# CI/CD iOS para TestFlight

## Objetivo

Este fluxo publica automaticamente o build iOS do SixoApp no TestFlight sem
alterar Android, Web ou o codigo Flutter da aplicacao.

- Workflow: `.github/workflows/ios-testflight.yml`
- App: `com.sixoapp.app`
- Team ID: `7FH3353D87`
- Workspace iOS: `ios/Runner.xcworkspace`
- Destino: App Store Connect / TestFlight

## Arquitetura do fluxo

O pipeline executa este caminho:

1. checkout do repositorio;
2. setup do Flutter;
3. resolucao da versao do app e dos `dart-defines` de producao;
4. `flutter pub get`;
5. `pod install` respeitando `Podfile.lock` quando existir;
6. instalacao temporaria da App Store Connect API Key;
7. instalacao temporaria do certificado `Apple Distribution` em keychain propria;
8. instalacao temporaria do provisioning profile `SixoApp App Store`;
9. `flutter build ios --release --no-codesign`;
10. `xcodebuild archive` com signing manual;
11. `xcodebuild -exportArchive` com `ios/ExportOptions.plist`;
12. validacao do `.ipa` via `xcrun altool --validate-app`;
13. upload para TestFlight via `xcrun altool --upload-app`;
14. upload do `.ipa` como artifact de diagnostico;
15. cleanup obrigatorio das credenciais temporarias.

## Triggers

O workflow mantem os dois gatilhos pedidos:

- `workflow_dispatch`
- `push` na branch `main`

Pull requests nao publicam no TestFlight.

## Flutter e Xcode utilizados

- Flutter configurado no workflow: `3.41.4`
- Runner: `macos-latest`

O workflow imprime em log:

- `flutter --version`
- `dart --version`
- `xcodebuild -version`
- `pod --version`

`macos-latest` foi mantido para reduzir manutencao manual. A versao real do
Xcode usada em cada execucao fica registrada no log do job.

## Processo de signing

O projeto nao versiona `DEVELOPMENT_TEAM` no `project.pbxproj`, entao o
workflow injeta o signing no `xcodebuild archive` sem alterar o projeto:

- `DEVELOPMENT_TEAM=7FH3353D87`
- `PRODUCT_BUNDLE_IDENTIFIER=com.sixoapp.app`
- `CODE_SIGN_STYLE=Manual`
- `CODE_SIGN_IDENTITY=Apple Distribution`
- `PROVISIONING_PROFILE_SPECIFIER=SixoApp App Store`

O certificado `.p12` e importado em uma keychain temporaria criada no runner.
Depois do job, a keychain e apagada.

## Processo de provisioning

O provisioning profile vem da secret `IOS_PROVISIONING_PROFILE_BASE64`.

O workflow:

1. decodifica o arquivo para `${RUNNER_TEMP}`;
2. extrai o UUID com `security cms` + `plutil`;
3. instala o profile em `~/Library/MobileDevice/Provisioning Profiles/<UUID>.mobileprovision`;
4. remove o profile no cleanup.

Nao existe UUID hardcoded no workflow.

## App Store Connect API Key

A autenticacao usa apenas:

- `APPLE_API_KEY_ID`
- `APPLE_API_ISSUER_ID`
- `APPLE_API_PRIVATE_KEY`

Durante o job, a chave `.p8` e criada temporariamente em:

```text
$HOME/.appstoreconnect/private_keys/AuthKey_<APPLE_API_KEY_ID>.p8
```

O arquivo recebe `chmod 600` e e removido no cleanup.

## Geracao do IPA

O export usa `ios/ExportOptions.plist` versionado, com estes pontos:

- `method = app-store-connect`
- `teamID = 7FH3353D87`
- `signingStyle = manual`
- `signingCertificate = Apple Distribution`
- `provisioningProfiles["com.sixoapp.app"] = "SixoApp App Store"`

O pipeline gera:

1. build Flutter iOS sem codesign;
2. archive assinado via `xcodebuild`;
3. export do `.ipa` via `xcodebuild -exportArchive`.

`flutter build ipa` nao foi adotado aqui porque o projeto nao versiona o team
de signing no `project.pbxproj`. O `xcodebuild archive` com parametros
explicitos reduz risco sem alterar o projeto iOS existente.

## Estrategia de versionamento

Base usada:

- `build-name`: parte antes do `+` em `pubspec.yaml`
- `build-number`: `pubspec_build_number + github.run_number`

Exemplo com o estado atual:

- `pubspec.yaml`: `1.120.0+121`
- `github.run_number`: `5`
- build final no iOS: `1.120.0 (126)`

Essa estrategia evita:

- reaproveitar o build `1` ja publicado manualmente;
- depender de alteracao permanente no `pubspec.yaml`;
- colisao imediata com runs iniciais do GitHub Actions.

## Dart-defines utilizados

O workflow resolve os defines reais do projeto antes do build:

- `API_BASE_URL`
- `PUBLIC_FRONTEND_URL`
- `APP_VERSION`
- `APP_BUILD_NUMBER`
- `GOOGLE_IOS_CLIENT_ID`

Origem de cada valor:

- `API_BASE_URL`: default atual em `lib/core/config/app_config.dart`
- `PUBLIC_FRONTEND_URL`: default atual em `lib/core/config/app_config.dart`
- `APP_VERSION`: derivado do `pubspec.yaml`
- `APP_BUILD_NUMBER`: derivado da estrategia descrita acima
- `GOOGLE_IOS_CLIENT_ID`: `GIDClientID` em `ios/Runner/Info.plist`

Nao foi criada secret nova para `GOOGLE_IOS_CLIENT_ID`, porque o valor ja faz
parte da configuracao iOS versionada.

## Validacao do IPA

Antes do upload, o workflow executa:

```bash
xcrun altool --validate-app --type ios --file <ipa> --apiKey <id> --apiIssuer <issuer>
```

Se a validacao falhar, o job falha e o upload nao acontece.

## Upload para TestFlight

Somente depois da validacao bem-sucedida:

```bash
xcrun altool --upload-app --type ios --file <ipa> --apiKey <id> --apiIssuer <issuer>
```

O fluxo segue o mesmo mecanismo manual que ja foi validado no projeto.

## Concurrency e timeout

- `concurrency.group = sixoapp-ios-testflight-publish`
- `cancel-in-progress = false`
- `timeout-minutes = 90`

Isso serializa uploads e evita dois envios simultaneos para TestFlight.

## Artifact do IPA

O `.ipa` exportado e salvo como artifact do GitHub Actions por 7 dias:

- nome: `sixoapp-ios-ipa-<run_number>`

O artifact inclui somente o `.ipa`. Nao inclui:

- `.p8`
- `.p12`
- `.mobileprovision`
- keychain
- secrets

## Secrets necessarias

O workflow usa exatamente estas seis secrets:

- `APPLE_API_KEY_ID`
- `APPLE_API_ISSUER_ID`
- `APPLE_API_PRIVATE_KEY`
- `IOS_DISTRIBUTION_CERTIFICATE_BASE64`
- `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`

Nao colocar valores reais nesta documentacao.

## Como executar manualmente

1. subir a branch com os arquivos da CI;
2. abrir `GitHub -> Actions`;
3. selecionar `SixoApp iOS - TestFlight`;
4. clicar em `Run workflow`;
5. escolher a branch de teste;
6. acompanhar o job `Build and upload iOS to TestFlight`.

## Como verificar o resultado no TestFlight

1. abrir App Store Connect;
2. acessar o app `SixoApp`;
3. abrir `TestFlight`;
4. aguardar o processamento do build;
5. conferir a versao e o build number gerados pelo workflow.

## Diagnostico de erros

Falhas comuns e causa provavel:

- `No signing certificate "Apple Distribution" found`
  - `.p12` sem chave privada ou senha incorreta.
- `No profiles for com.sixoapp.app were found`
  - provisioning profile incorreto ou nao corresponde ao bundle ID.
- `ITMS-90161` ou erro semelhante na validacao
  - signing/export inconsistente ou profile incorreto.
- build number rejeitado
  - numero nao cresceu para a mesma versao.
- erro de Google Sign-In no iOS
  - `GOOGLE_IOS_CLIENT_ID` divergente do `Info.plist`.

Os logs uteis do workflow mostram:

- versoes do toolchain;
- `build-name`;
- `build-number`;
- caminho final do `.ipa`;
- sucesso/erro da validacao;
- sucesso/erro do upload.

## Rotacao de certificado

Quando o certificado `Apple Distribution` mudar:

1. exportar novo `.p12` com chave privada;
2. converter para Base64;
3. atualizar `IOS_DISTRIBUTION_CERTIFICATE_BASE64`;
4. atualizar `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`;
5. executar um `workflow_dispatch` manual.

## Rotacao da API Key

Quando a App Store Connect API Key mudar:

1. criar ou baixar a nova chave no App Store Connect;
2. atualizar `APPLE_API_KEY_ID`;
3. atualizar `APPLE_API_ISSUER_ID` se necessario;
4. atualizar `APPLE_API_PRIVATE_KEY`;
5. executar um `workflow_dispatch` manual.

## Atualizacao do provisioning profile

Quando o profile `SixoApp App Store` mudar:

1. exportar ou baixar o novo `.mobileprovision`;
2. converter para Base64;
3. atualizar `IOS_PROVISIONING_PROFILE_BASE64`;
4. executar um `workflow_dispatch` manual.

## Como desabilitar temporariamente a publicacao automatica

Opcoes simples:

1. comentar/remover o bloco `push` do workflow;
2. manter apenas `workflow_dispatch`;
3. desabilitar o workflow no menu `Actions` do GitHub.

## Rollback da configuracao de CI

Para voltar ao estado anterior:

1. remover `.github/workflows/ios-testflight.yml`;
2. remover `ios/ExportOptions.plist` se quiser abandonar o fluxo;
3. reverter a alteracao no `.gitignore`, se ela nao fizer mais sentido;
4. validar que `ci.yml` e `bump-version-on-main.yml` continuam intactos.

## Observacoes operacionais

- O workflow depende de `ios/Podfile` e `ios/ExportOptions.plist` estarem
  versionados junto com o restante da alteracao.
- O `Info.plist` ja contem `ITSAppUsesNonExemptEncryption = false`; o workflow
  valida isso e falha se a chave estiver ausente ou com outro valor.
- O primeiro teste recomendado e manual, via `workflow_dispatch`, antes de
  permitir publicacao automatica na `main`.
