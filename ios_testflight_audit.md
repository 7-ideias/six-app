# Auditoria iOS para primeiro TestFlight - SixoApp

Data da auditoria: 2026-08-22  
Branch local: `feature/20260820-melhorias`  
Objetivo: diagnosticar o preparo do primeiro build iOS/TestFlight sem alterar codigo do app.

## Estado atual

- O projeto Flutter existe e esta resolvendo dependencias com `flutter pub get`.
- Flutter local: `3.41.4 stable`, Dart `3.11.1`.
- `pubspec.yaml`: `name: sixpos`, `description: Six Point of Sale`, `version: 1.120.0+121`.
- A pasta `ios/` existe e possui template moderno do Flutter com `SceneDelegate` e `FlutterImplicitEngineDelegate`.
- Existem:
  - `ios/Runner.xcodeproj`
  - `ios/Runner.xcworkspace`
  - `ios/Runner/Info.plist`
  - `ios/Runner/AppDelegate.swift`
  - `ios/Runner/SceneDelegate.swift`
  - `ios/Runner/Assets.xcassets/AppIcon.appiconset`
  - `ios/Runner/Base.lproj/LaunchScreen.storyboard`
  - `ios/RunnerTests/RunnerTests.swift`
- Nao existem atualmente:
  - `ios/Podfile`
  - `ios/Runner/Runner.entitlements`
  - `ios/Runner/GoogleService-Info.plist`
  - `ios/Podfile.lock`
- O AppIcon tem os tamanhos iOS esperados, incluindo `1024x1024`.
- O LaunchScreen existe, mas usa o template padrao com imagens transparentes `1x1`.
- O scheme `Runner` existe e arquiva com configuracao `Release`.
- Nao foram encontrados flavors/schemes customizados para iOS.

Observacao importante: no Flutter 3.41.4 o template iOS base nao inclui `Podfile` diretamente em `templates/app/ios.tmpl`; o Flutter cria/configura o Podfile no macOS quando ha plugins CocoaPods. Mesmo assim, para um primeiro TestFlight previsivel, recomendo versionar o `ios/Podfile` gerado no Mac ou criar antes com o template oficial ajustado.

## Bloqueadores para compilar no iOS

1. **Target minimo iOS incompatível com Firebase atual**
   - `ios/Runner.xcodeproj/project.pbxproj` usa `IPHONEOS_DEPLOYMENT_TARGET = 13.0`.
   - `firebase_core 4.11.0` e `firebase_messaging 16.4.1` exigem `s.ios.deployment_target = '15.0'` nos podspecs locais.
   - Acao: elevar iOS Deployment Target para `15.0` no Xcode project e no Podfile.

2. **Bundle ID nao bate com o App Store Connect**
   - App ID registrado: `com.sixoapp.app`.
   - Projeto iOS atual: `br.com.seteideias.sixpos`.
   - Firebase iOS atual: `br.com.seteideias.appplanilha`.
   - Acao: alinhar Bundle ID em todos os pontos antes de Archive.

3. **Configuracao iOS de Firebase/Google antiga ou incompleta**
   - `lib/firebase_options.dart` tem `iosBundleId: 'br.com.seteideias.appplanilha'`.
   - `ios/Runner/Info.plist` tem Google iOS Client ID antigo.
   - `GoogleService-Info.plist` nao existe.
   - Acao: criar/baixar configuracoes Firebase e OAuth para `com.sixoapp.app`.

4. **CocoaPods/Podfile ainda nao materializado**
   - `ios/Podfile` ausente no Linux.
   - O Mac provavelmente pode gerar ao executar comando Flutter/Xcode, mas isso deve ser conferido antes do Archive.
   - Acao recomendada: no Mac, rodar `flutter pub get` e `cd ios && pod install`; se o Flutter gerar o Podfile, versionar o arquivo final.

## Bloqueadores para TestFlight

1. **Signing nao configurado**
   - `DEVELOPMENT_TEAM` nao aparece no `project.pbxproj`.
   - `CODE_SIGN_STYLE = Automatic` existe, mas sem Team.
   - Acao no Xcode: selecionar Team, Bundle Identifier `com.sixoapp.app`, automatic signing e archive Release.

2. **Bundle ID errado**
   - Enquanto estiver `br.com.seteideias.sixpos`, o Xcode nao deve conseguir assinar/uploadar como o app criado no App Store Connect (`com.sixoapp.app`).

3. **Google Sign-In iOS exige dart-define**
   - `GoogleAuthService._ensurePlatformConfigured()` bloqueia iOS se `GOOGLE_IOS_CLIENT_ID` estiver vazio.
   - Para TestFlight com login Google funcional, o build precisa de:
     - `--dart-define=GOOGLE_IOS_CLIENT_ID=<client-id-ios-do-bundle-com.sixoapp.app>`
     - `Info.plist` com `GIDClientID` e URL scheme correspondentes.

4. **Push/FCM nao esta pronto para iOS**
   - Nao ha entitlements.
   - Nao ha `aps-environment`.
   - Nao ha `GoogleService-Info.plist`.
   - Firebase iOS aponta para bundle antigo.
   - O app pode abrir sem push porque o codigo captura falhas de inicializacao, mas push real no iPhone nao deve funcionar ate ajustar Firebase/APNs/capabilities.

## Ajustes recomendados antes de usar um Mac

1. Alterar `PRODUCT_BUNDLE_IDENTIFIER` do target Runner para `com.sixoapp.app`.
2. Alterar Bundle ID do target `RunnerTests` para algo derivado, por exemplo `com.sixoapp.app.RunnerTests`.
3. Alterar `CFBundleDisplayName` de `Appplanilha` para `SixoApp` ou nome final definido.
4. Alterar `CFBundleName` de `appplanilha` para um nome coerente, por exemplo `SixoApp`.
5. Elevar `IPHONEOS_DEPLOYMENT_TARGET` de `13.0` para `15.0`.
6. Atualizar `lib/firebase_options.dart` com app iOS Firebase registrado para `com.sixoapp.app`, ou regenerar via FlutterFire.
7. Criar/revisar `ios/Runner/GoogleService-Info.plist` para `com.sixoapp.app`.
8. Atualizar Google Sign-In:
   - `GIDClientID` no `Info.plist`.
   - URL scheme reverso no `CFBundleURLTypes`.
   - `GOOGLE_IOS_CLIENT_ID` no comando de build.
9. Trocar `PUBLIC_FRONTEND_URL` default de `https://six-app-iota.vercel.app/cliente/auto-cadastro` para dominio oficial se este link for usado no mobile.
10. Decidir se o primeiro TestFlight sera `1.120.0+121` ou se vai resetar para `1.0.0+1`.
11. Corrigir gates de validacao:
    - `flutter analyze` falha hoje por erro em teste.
    - `flutter test` falha hoje com 25 testes.

## Ajustes que obrigatoriamente exigem macOS/Xcode

1. Instalar CocoaPods e rodar `pod install`.
2. Abrir `ios/Runner.xcworkspace` no Xcode.
3. Selecionar Apple Team.
4. Validar signing automatico para `com.sixoapp.app`.
5. Gerar/baixar provisioning profile.
6. Gerar Archive Release.
7. Validar upload pelo Organizer ou Transporter.
8. Conferir se Xcode criou entitlements ao habilitar Push Notifications.
9. Validar execucao em iPhone real.
10. Validar APNs/FCM real em dispositivo se push for parte do TestFlight.

## Bundle ID

Bundle ID esperado pela Apple:

```text
com.sixoapp.app
```

Identificadores encontrados:

| Arquivo | Valor encontrado | Observacao |
| --- | --- | --- |
| `ios/Runner.xcodeproj/project.pbxproj` | `br.com.seteideias.sixpos` | Bundle ID do target Runner. Diverge do esperado. |
| `ios/Runner.xcodeproj/project.pbxproj` | `br.com.seteideias.sixpos.RunnerTests` | Bundle ID dos testes. Diverge do esperado. |
| `ios/Runner/Info.plist` | `$(PRODUCT_BUNDLE_IDENTIFIER)` | Herda do Xcode project. |
| `lib/firebase_options.dart` | `iosBundleId: 'br.com.seteideias.appplanilha'` | Firebase iOS aponta para bundle diferente do target atual e do esperado. |
| `android/app/build.gradle.kts` | `br.com.seteideias.appplanilha` | Android, nao bloqueia iOS, mas mostra naming legado. |
| `android/app/google-services.json` | `br.com.seteideias.appplanilha` | Android, nao bloqueia iOS. |

Arquivos que precisam mudar para alinhar o iOS:

- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Runner/Info.plist`
- `lib/firebase_options.dart`
- `ios/Runner/GoogleService-Info.plist` novo
- `ios/Runner/Runner.entitlements` novo se Push for habilitado
- `ios/Runner.xcodeproj/project.pbxproj` tambem deve referenciar entitlements se criados

Nao foram encontradas extensoes, app groups, widgets ou targets alem de `Runner` e `RunnerTests`.

## Nome e versao do app

| Item | Valor atual |
| --- | --- |
| Nome Flutter/package | `sixpos` |
| Display name iOS | `Appplanilha` |
| `CFBundleDisplayName` | `Appplanilha` |
| `CFBundleName` | `appplanilha` |
| `pubspec.yaml version` | `1.120.0+121` |
| `CFBundleShortVersionString` | `$(FLUTTER_BUILD_NAME)` |
| `CFBundleVersion` | `$(FLUTTER_BUILD_NUMBER)` |
| `Generated.xcconfig` local | `1.51.0+52`, arquivo gerado e nao versionado |
| Flutter local | `3.41.4 stable` |

Sugestao:

- Se ja existe estrategia real de release: manter `1.120.0+121` para nao perder historico.
- Se o App Store Connect ainda nao recebeu nenhum build e a estrategia publica sera reiniciada: usar `1.0.0+1`.
- Para o primeiro TestFlight, o mais limpo e definir uma decisao unica no `pubspec.yaml` e gerar com `--build-name`/`--build-number` apenas se quiser sobrescrever temporariamente.

## Dependencias e compatibilidade iOS

| Dependencia/plugin | iOS | Configuracao nativa relevante |
| --- | --- | --- |
| `firebase_core 4.11.0` | Sim | Requer iOS 15.0. Precisa Firebase options corretas. |
| `firebase_messaging 16.4.1` | Sim | Requer iOS 15.0, APNs para push real, Push Notifications, possivel Background Modes para notificacoes remotas em background. |
| `flutter_local_notifications 17.2.4` | Sim | Solicita alert/badge/sound no DarwinInitializationSettings. |
| `google_sign_in 6.3.0` / `google_sign_in_ios 5.9.0` | Sim | Requer iOS client ID, `GIDClientID`, URL scheme reverso. |
| `image_picker 1.2.1` / `image_picker_ios 0.8.13` | Sim | Requer `NSCameraUsageDescription` e `NSPhotoLibraryUsageDescription` se camera/galeria forem usadas. |
| `mobile_scanner 7.2.0` | Sim | Requer camera e `NSCameraUsageDescription`. |
| `share_plus 10.1.4` | Sim | Usa share sheet nativo. Nao exige capability. |
| `shared_preferences 2.5.3` | Sim | Usa `NSUserDefaults`. Nao exige capability. |
| `google_fonts 6.3.3` | Sim | Pode baixar fontes via rede/cache; nao exige capability. |
| `fl_chart`, `provider`, `lottie`, `signature`, `intl`, `http`, `stomp_dart_client`, `syncfusion_flutter_gauges` | Dart/Flutter | Sem configuracao iOS nativa especifica encontrada. |

O target minimo recomendado para este projeto e **iOS 15.0**, por causa de Firebase Core/Messaging resolvidos atualmente.

## Info.plist

Chaves existentes relevantes:

- `CFBundleDisplayName = Appplanilha`
- `CFBundleIdentifier = $(PRODUCT_BUNDLE_IDENTIFIER)`
- `CFBundleName = appplanilha`
- `CFBundleShortVersionString = $(FLUTTER_BUILD_NAME)`
- `CFBundleVersion = $(FLUTTER_BUILD_NUMBER)`
- `UIApplicationSceneManifest`
- `GIDClientID`
- `CFBundleURLTypes`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `UILaunchStoryboardName`
- `UIMainStoryboardFile`
- `UISupportedInterfaceOrientations`

Chaves presentes e justificadas:

- `NSCameraUsageDescription`: usada por `image_picker` camera e `mobile_scanner`.
- `NSPhotoLibraryUsageDescription`: usada por `image_picker` galeria.
- `GIDClientID` e `CFBundleURLTypes`: usados por Google Sign-In.

Chaves ausentes que podem ser necessarias:

- `UIBackgroundModes` com `remote-notification`: necessario se push em background/silent notification for requisito do TestFlight. Para apenas abrir o app sem push, nao e obrigatorio.
- `NSPhotoLibraryAddUsageDescription`: nao encontrei uso claro de salvar imagens na galeria, entao nao recomendo adicionar agora.
- `NSMicrophoneUsageDescription`: nao encontrei uso real.
- `NSLocationWhenInUseUsageDescription`: nao encontrei geolocalizacao.
- `NSContactsUsageDescription`: nao encontrei acesso a contatos.
- `NSFaceIDUsageDescription`: nao ha `local_auth`/biometria.
- `LSApplicationQueriesSchemes`: nao ha `canOpenURL` nativo; links externos usam Web no browser e fallback stub no mobile. Nao adicionar sem uso real.
- `NSAppTransportSecurity`: ausente. Com API HTTPS, isso e aceitavel.

Textos que a Apple apresentara:

- Camera: `O Six precisa acessar a câmera para fotografar produtos e escanear códigos de barras no PDV.`
- Fotos: `O Six precisa acessar sua galeria para anexar imagens aos produtos.`

Esses textos estao coerentes com o uso atual, mas devem mencionar SixoApp/Six conforme nome final.

## Firebase e notificacoes

Uso real encontrado:

- `firebase_core`
- `firebase_messaging`
- `flutter_local_notifications`
- `lib/firebase_options.dart`
- `FirebasePushNotificationService.initializeOnAppStart()` roda em `main.dart` para nao Web.
- `syncTokenForLoggedUser()` e chamado apos login/dados da empresa.
- O token e enviado para `${AppConfig.baseUrl}/private/api/notificacoes/push-token`.

Problemas atuais:

- `ios/Runner/GoogleService-Info.plist` nao existe.
- `lib/firebase_options.dart` iOS aponta para `iosBundleId: 'br.com.seteideias.appplanilha'`.
- Nao ha `Runner.entitlements`.
- Nao ha `aps-environment`.
- Nao ha `UIBackgroundModes`.
- Nao foi encontrada configuracao APNs no repositorio.

O app consegue funcionar sem push inicialmente?

- Provavelmente sim para abrir/login/usar fluxos basicos, porque `initializeFirebaseIfConfigured()` captura excecoes e retorna `false`.
- Para Google Sign-In no iOS, isso nao basta: o app exige `GOOGLE_IOS_CLIENT_ID`.
- Para push real no iPhone, nao esta pronto.

## Google Sign-In / OAuth

Uso real:

- `google_sign_in` no mobile.
- `google_sign_in_web` no Web.
- Backend recebe idToken em:
  - `${AppConfig.baseUrl}/auth/mobile/google`
  - `${AppConfig.baseUrl}/auth/web/google`

Valores atuais:

- Web/server client ID em Dart: `194419403668-manc56voom9d29bv0n7m4pilub8j864a.apps.googleusercontent.com`
- iOS client ID no `Info.plist`: `194419403668-04a9qv3spjctqmcrssqu3vb6upgi6mg6.apps.googleusercontent.com`
- URL scheme iOS: `com.googleusercontent.apps.194419403668-04a9qv3spjctqmcrssqu3vb6upgi6mg6`

Risco:

- Com Bundle ID `com.sixoapp.app`, sera necessario criar/selecionar um OAuth Client iOS vinculado exatamente a esse bundle no Google/Firebase.
- O valor de `GOOGLE_IOS_CLIENT_ID` no build precisa bater com o `GIDClientID`.
- O URL scheme reverso precisa bater com esse client ID.

Keycloak/Cognito:

- Nao encontrei integracao mobile nativa com Keycloak ou Cognito.
- A palavra Keycloak aparece em texto de pagina publica Web, nao como SDK/config iOS.

## Comunicacao com backend

Configuracao central:

- `lib/core/config/app_config.dart`
- `API_BASE_URL`, default: `https://api.sixappback.com`
- `PUBLIC_FRONTEND_URL`, default: `https://six-app-iota.vercel.app/cliente/auto-cadastro`

Conclusoes:

- A API Dart padrao usa HTTPS, entao ATS nao deve bloquear.
- Nao ha `NSAppTransportSecurity` no iOS, o que e correto se a API final continuar HTTPS.
- A mensagem de erro em `AuthService` ainda cita `http://localhost:8082` como instrucao de desenvolvimento.
- Existem muitas URLs em arquivos Web/publicos e scripts; para iOS, o ponto critico e `AppConfig`.
- O dominio oficial informado `https://sixoapp.com` ainda nao aparece como default de `PUBLIC_FRONTEND_URL`.

Recomendacao para TestFlight:

```bash
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://api.sixappback.com \
  --dart-define=PUBLIC_FRONTEND_URL=https://sixoapp.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=<ios-client-id-do-com.sixoapp.app>
```

## Deep links e URL schemes

Encontrado:

- `CFBundleURLTypes` apenas para Google Sign-In.
- Links Web/publicos de atendimento/catalogo/auto-cadastro existem no Flutter/Web e arquivos `web/`.
- WhatsApp aparece como `https://wa.me/...` em pagina publica, mas o launcher mobile atual para external link usa stub e retorna `false`.

Nao encontrado:

- Universal Links (`associated-domains`).
- Custom scheme proprio do app.
- App Groups.
- URL scheme de WhatsApp.

Obrigatorio agora:

- URL scheme reverso do Google Sign-In, se login Google for testado no iOS.

Futuro:

- Associated Domains para `sixoapp.com` se quiser abrir links de atendimento/catalogo diretamente no app.
- Custom URL scheme apenas se houver necessidade de callback proprio.

## Capabilities necessarias

| Capability | Motivo | Obrigatoria agora? | Configuracao necessaria |
| --- | --- | --- | --- |
| Push Notifications | `firebase_messaging` e sync de token FCM. | Nao para app abrir; sim para push real no TestFlight. | Habilitar no App ID/Xcode, APNs no Firebase, entitlements com `aps-environment`. |
| Background Modes - Remote notifications | Receber/processar push em background. | Nao para primeiro build sem push; sim se exigir background push. | Xcode > Signing & Capabilities > Background Modes > Remote notifications; `UIBackgroundModes`. |
| Sign in with Apple | UI mobile tem botao Apple mockado, mas sem implementacao real. | Nao agora. | Futuro: adicionar SDK/plugin, capability, backend e fluxo real. |
| Associated Domains | Universal links para `sixoapp.com`. | Nao agora. | Futuro: capability + `applinks:sixoapp.com` + AASA no dominio. |
| Keychain Sharing | Nao ha uso de secure storage/keychain. | Nao. | Nenhuma. |
| App Groups | Nao ha extensoes/widgets. | Nao. | Nenhuma. |
| iCloud | Nao encontrado. | Nao. | Nenhuma. |
| Apple Pay | Nao encontrado. | Nao. | Nenhuma. |
| Maps | Nao encontrado. | Nao. | Nenhuma. |
| HealthKit | Nao encontrado. | Nao. | Nenhuma. |

## Assets iOS

- `Assets.xcassets/AppIcon.appiconset` esta completo e valido em dimensoes.
- `Icon-App-1024x1024@1x.png` existe e tem `1024 x 1024`.
- Launch image existe, mas os PNGs sao `1 x 1`; compila, mas nao representa a marca.
- `LaunchScreen.storyboard` e `Main.storyboard` sao templates antigos/padrao, mas compatíveis.

Para build valido: suficiente.  
Para experiencia de TestFlight: recomendo trocar icone/splash por identidade final antes do envio.

## Podfile / CocoaPods

Estado atual:

- `ios/Podfile`: ausente.
- `ios/Podfile.lock`: ausente.
- O Flutter local possui template em `packages/flutter_tools/templates/cocoapods/Podfile-ios`.
- Template padrao comenta `platform :ios, '13.0'` e usa `use_frameworks!`.

Recomendacao:

- Criar/gerar `ios/Podfile`.
- Definir explicitamente:

```ruby
platform :ios, '15.0'
```

- Manter `use_frameworks!`, pois e o template atual do Flutter.
- Rodar `pod install` no Mac.
- Versionar `Podfile` e avaliar versionar `Podfile.lock` conforme pratica do projeto.

## Xcode Signing

No Xcode sera necessario:

1. Abrir `ios/Runner.xcworkspace`, nao apenas `.xcodeproj`.
2. Selecionar target `Runner`.
3. Em Signing & Capabilities:
   - Team: conta Apple Developer correta.
   - Bundle Identifier: `com.sixoapp.app`.
   - Automatically manage signing: habilitado inicialmente.
4. Confirmar Provisioning Profile gerado para App Store distribution.
5. Confirmar certificado Apple Distribution.
6. Usar scheme `Runner`.
7. Product > Archive.
8. Upload para App Store Connect pelo Organizer.

O Xcode provavelmente consegue gerar automaticamente:

- Development provisioning profile.
- Distribution provisioning se Team/Bundle/App ID estiverem corretos.
- Entitlements basicos ao adicionar capability pela UI.

Pode exigir configuracao manual:

- APNs Auth Key no Firebase.
- Ajuste de App ID no Apple Developer se Push/Associated Domains forem usados.
- OAuth client iOS no Google/Firebase.

## Build modes e ambientes

Nao encontrei:

- flavors Flutter.
- schemes dev/hml/prod.
- arquivos `.env`.
- Firebase por ambiente.
- configuracao nativa iOS por ambiente.

Encontrado:

- `--dart-define` para:
  - `API_BASE_URL`
  - `PUBLIC_FRONTEND_URL`
  - `APP_VERSION`
  - `APP_BUILD_NUMBER`
  - `GOOGLE_IOS_CLIENT_ID`
  - `GOOGLE_ANDROID_CLIENT_ID`
  - `FIREBASE_WEB_*` apenas Web.

Build de producao sugerido para TestFlight:

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ipa --release \
  --build-name=1.0.0 \
  --build-number=1 \
  --dart-define=API_BASE_URL=https://api.sixappback.com \
  --dart-define=PUBLIC_FRONTEND_URL=https://sixoapp.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=<ios-client-id-do-com.sixoapp.app>
```

Se optar por preservar versionamento atual:

```bash
flutter build ipa --release \
  --build-name=1.120.0 \
  --build-number=121 \
  --dart-define=API_BASE_URL=https://api.sixappback.com \
  --dart-define=PUBLIC_FRONTEND_URL=https://sixoapp.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=<ios-client-id-do-com.sixoapp.app>
```

## Codigo especifico por plataforma

Pontos encontrados:

- `main.dart` usa `kIsWeb` para rotas Web e inicializacao mobile.
- `flutter_web_plugins/url_strategy.dart` e importado em `main.dart`, mas o pacote exporta stub non-web no Flutter atual.
- Existem imports condicionais para Web:
  - `browser_location.dart`
  - `browser_device.dart`
  - `external_link_launcher.dart`
  - `pdf_download.dart`
  - `sub_painel_cadastro_produto.dart`
- Existe import direto de `dart:html` em arquivos Web, mas em geral isolado por condicionais.
- Risco de teste: `test/presentation/screens/produto_favorito_catalogo_web_test.dart` importa diretamente `sub_painel_cadastro_produto_web.dart` e falha na VM.
- `home_page_mobile_screen.dart` importa `pagina_principal_web.dart`; isso aumenta o grafo compilado no mobile e merece atencao, mas nao apareceu como erro no analyze.
- `external_link_launcher` no mobile retorna `false`; links externos/WhatsApp de telas compartilhadas podem nao abrir no app iOS sem `url_launcher`.

Riscos iOS:

- Google Sign-In lanca erro se `GOOGLE_IOS_CLIENT_ID` nao vier no build.
- Push pode falhar silenciosamente ate configurar Firebase/APNs.
- PDF download Web tem fallback mobile que retorna `false`; compartilhamento de PDF usa `share_plus` em servico proprio e deve ser o caminho mobile correto.

## Analise estatica e testes

Comandos executados em Linux:

```bash
flutter pub get
flutter analyze
flutter test
```

Resultado:

- `flutter pub get`: passou.
- `flutter analyze`: falhou com 419 issues.
  - Erro bloqueador principal:
    - `test/presentation/screens/pdv_mobile_dark_mode_test.dart:896`
    - `_FakeOperacaoService.imprimirComprovanteDaOperacao` nao sobrescreve mais a assinatura real de `OperacaoService.imprimirComprovanteDaOperacao`.
  - Tambem ha warnings relevantes em `pdv_web.dart` por uso invalido de `setState` fora de `State`.
  - O restante e majoritariamente lint/deprecations.
- `flutter test`: falhou.
  - Resumo final: `+434 ~1 -25`.
  - Falha visivel de compilacao: teste Web importando `dart:html` no runner VM.
  - Falhas visiveis em testes de widget mobile, incluindo `Bad state: No element`.
  - Muito ruido de chaves i18n ausentes usando fallback.

Esses problemas nao provam que o app iOS nao compila, mas deixam a base sem gate limpo antes do TestFlight.

## Riscos de App Review futuros

Mesmo que o objetivo agora seja TestFlight:

- Login obrigatorio: a Apple pode exigir conta de review funcional na submissao publica.
- Exclusao de conta: se houver cadastro/login, app publico tende a precisar caminho claro para exclusao de conta.
- Google Sign-In: se Google for oferecido como login de terceiros, Apple normalmente exige Sign in with Apple tambem em app publico. Hoje o botao Apple mobile e mockado.
- Permissoes: camera/fotos estao justificadas; nao adicionar permissoes sem uso real.
- Push: solicitar permissao logo apos login pode ser aceito, mas precisa explicar valor ao usuario no fluxo.
- Pagamentos/assinatura: revisar se ha links externos de checkout/planos para evitar problema com regras de pagamento da Apple, dependendo do que e vendido.
- Privacidade: sera necessario preencher App Privacy no App Store Connect com dados coletados (conta, contato, identificadores, imagens, notificacoes, etc.).
- App que pareca wrapper de site: o app tem UI Flutter mobile propria, o que reduz risco, mas ha muito codigo Web importado no grafo.
- Features incompletas/mockadas: botao Apple mockado e textos de configuracoes "coming soon" devem ser removidos/ocultados antes da submissao publica.

## Arquivos que precisam ser alterados

Obrigatorios antes de Archive/TestFlight:

- `ios/Runner.xcodeproj/project.pbxproj`
  - Bundle ID Runner.
  - Bundle ID RunnerTests.
  - Deployment target iOS 15.0.
  - Team/signing pode ser feito no Xcode.
  - Referencia a entitlements se Push for habilitado.
- `ios/Runner/Info.plist`
  - Display name.
  - Bundle name.
  - Google iOS Client ID.
  - URL scheme reverso.
  - Possivel `UIBackgroundModes` se push background for necessario.
- `lib/firebase_options.dart`
  - Firebase iOS app para `com.sixoapp.app`.
- `ios/Runner/GoogleService-Info.plist`
  - Novo arquivo do Firebase iOS.
- `ios/Podfile`
  - Criar/gerar e definir `platform :ios, '15.0'`.
- `pubspec.yaml`
  - Ajustar `version` se decidir por `1.0.0+1`.
- `lib/core/config/app_config.dart`
  - Trocar default `PUBLIC_FRONTEND_URL` para `https://sixoapp.com` se usado em mobile/producao.

Necessarios se push for parte do TestFlight:

- `ios/Runner/Runner.entitlements`
- `ios/Runner.xcodeproj/project.pbxproj`
- Configuracao Apple Developer/App ID
- Configuracao APNs no Firebase

Recomendados para gate limpo:

- `test/presentation/screens/pdv_mobile_dark_mode_test.dart`
- teste Web que importa `sub_painel_cadastro_produto_web.dart` diretamente
- possiveis testes mobile quebrados reportados por `flutter test`

## Sequencia sugerida de implementacao

1. Decidir versao: manter `1.120.0+121` ou resetar para `1.0.0+1`.
2. Alinhar Bundle ID iOS para `com.sixoapp.app`.
3. Elevar iOS deployment target para `15.0`.
4. Definir nome exibido final (`SixoApp` ou outro).
5. Criar/atualizar Firebase iOS para `com.sixoapp.app`.
6. Criar/atualizar Google OAuth iOS para `com.sixoapp.app`.
7. Atualizar `Info.plist` com Google client e URL scheme.
8. Criar/gerar Podfile com iOS 15.0.
9. Ajustar defaults de producao (`PUBLIC_FRONTEND_URL`).
10. Corrigir falha de `flutter analyze`.
11. Corrigir ou separar testes Web/VM que quebram `flutter test`.
12. Ir para o Mac, rodar CocoaPods, abrir workspace e configurar signing.
13. Gerar Archive e subir ao App Store Connect.
14. Distribuir no TestFlight e instalar em iPhone real.

## Checklist macOS

Preparacao:

```bash
flutter --version
flutter doctor -v
flutter pub get
```

CocoaPods:

```bash
cd ios
pod repo update
pod install
cd ..
```

Validacao:

```bash
flutter analyze
flutter test
```

Build/Archive via Flutter:

```bash
flutter build ipa --release \
  --build-name=1.0.0 \
  --build-number=1 \
  --dart-define=API_BASE_URL=https://api.sixappback.com \
  --dart-define=PUBLIC_FRONTEND_URL=https://sixoapp.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=<ios-client-id-do-com.sixoapp.app>
```

Xcode:

1. Abrir `ios/Runner.xcworkspace`.
2. Target `Runner` > Signing & Capabilities.
3. Team correto.
4. Bundle Identifier `com.sixoapp.app`.
5. Confirmar iOS Deployment Target `15.0`.
6. Habilitar Push Notifications apenas se for testar push.
7. Product > Archive.
8. Organizer > Distribute App > App Store Connect > Upload.
9. App Store Connect > TestFlight > aguardar processamento.
10. Adicionar tester interno e instalar no iPhone pelo TestFlight.

## Conclusao

O projeto esta **quase pronto para ir ao Mac**, mas possui bloqueadores relevantes antes de Archive/TestFlight:

- Bundle ID iOS ainda esta errado.
- Deployment target iOS 13.0 e incompatível com Firebase atual, que exige iOS 15.0.
- Firebase/Google Sign-In iOS apontam para identificadores antigos.
- Signing/capabilities ainda nao estao configurados.
- O gate de `flutter analyze` e `flutter test` esta vermelho.

Nao recomendo abrir o Xcode para tentar Archive antes de alinhar Bundle ID, iOS 15.0, Firebase/Google e decidir a versao do primeiro build.
