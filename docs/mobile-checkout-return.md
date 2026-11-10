# Retorno do checkout ao aplicativo

O mobile envia `returnTarget: MOBILE` ao endpoint de checkout. Na web o
destino continua `WEB` (também é o padrão para clientes antigos).
O portal usa `?returnTarget=MOBILE`. Não há URL arbitrária enviada pelo cliente.

O backend gera os retornos em
`https://www.sixoapp.com/mobile/billing-return?retorno=stripe&company=...`.
Cancelamento usa `retorno=cancelado`; portal usa `retorno=portal`.
A URL não comprova pagamento, não contém token e não altera o comércio atual.
Somente o backend consulta a Stripe e decide o acesso e a vigência paga.

## Publicação

1. Publicar a web com a página de retorno antes de ativar o novo backend/app.
   A página é HTML leve e não carrega Flutter nem exige login.
2. Na configuração do build web, definir `SIX_ANDROID_APP_LINK_SHA256` com
   a impressão SHA-256 do certificado que assina o app instalado.
   Para Google Play App Signing, usar o certificado **de assinatura do app**,
   não o certificado de upload. Para APK distribuído diretamente, usar o seu
   certificado de release. Múltiplos fingerprints são separados por vírgula.
3. O build gera `/.well-known/assetlinks.json` e
   `/.well-known/apple-app-site-association`, servidos sem redirecionamento.
   Sem fingerprint Android, gera uma lista vazia (nenhuma associação inventada)
   e avisa no build. O botão de retorno por esquema continua disponível.
4. iOS: habilitar Associated Domains no App ID `com.sixoapp.app` e regenerar
   o provisioning profile usado no TestFlight/produção, incluindo a capability.
   O Team ID padrão é `7FH3353D87`, presente no projeto. Se o perfil usa outro
   App ID prefix, ajustar `SIX_IOS_TEAM_ID` no build web para esse prefixo.
   O workflow compara essa capability com o perfil instalado antes de compilar.
   Se o perfil antigo ainda não a permite, remove somente Associated Domains
   dos entitlements da cópia de build e usa o botão de retorno pelo esquema
   do aplicativo. Push Notifications e autenticação permanecem intactos.
   Ao atualizar `IOS_PROVISIONING_PROFILE_BASE64` com o perfil compatível, o
   próximo build mantém Universal Links automaticamente. O archive valida
   tanto o entitlement de push quanto o modo de retorno escolhido.
5. Publicar o backend e instalar uma nova versão nativa Android/iOS. Atualizar
   somente web/backend não registra os links em versões antigas do aplicativo.

O caminho HTTPS é associado somente ao retorno mobile; uma compra iniciada na
web continua na web. Se o sistema/navegador não abrir o app automaticamente,
a página oferece o botão `com.sixoapp.billing://return`, separado do esquema
de autenticação. Não há tentativa automática repetitiva nem abertura forçada
da aplicação web.

## Comportamento

- App fechado: o link fica pendente enquanto login, biometria, permissões e
  onboarding seguem o fluxo normal; ao entrar, abre a assinatura.
- App aberto: um painel de assinatura existente consome o retorno; senão, a
  navegação autenticada abre a tela mobile.
- Retorno manual do navegador: o painel atualiza e, após iniciar checkout,
  tenta confirmar até seis vezes, com intervalo de três segundos entre respostas.
- Confirmação atrasada: mantém mensagem de espera e atualização manual.
- Cancelamento: consulta o estado sem anunciar pagamento bem-sucedido.
- Outro comércio: orienta a selecionar o comércio correto, sem trocar tenant
  pelo parâmetro do link.
- Checkout pendente: destino persistido junto da requisição idempotente.
  Mudar WEB/MOBILE expira a sessão aberta antes de criar outra; recuperação
  após timeout conserva o destino original.

## Verificação em dispositivos

Validar Android e iOS com checkout de teste: sucesso, cancelamento, portal,
webhook atrasado, volta manual, app fechado, sessão expirada, biometria e
comércio diferente. Confirmar também que checkout web permanece no navegador.
Usar apenas ambiente/chaves de teste para ensaios de cobrança.

Android (substituir o comércio por um ID válido da conta de teste):

```sh
adb shell am start -a android.intent.action.VIEW -d 'https://www.sixoapp.com/mobile/billing-return?retorno=stripe&company=COMERCIO'
adb shell pm get-app-links br.com.seteideias.appplanilha
```

iOS Simulator:

```sh
xcrun simctl openurl booted 'com.sixoapp.billing://return?retorno=cancelado&company=COMERCIO'
```

Testar também Universal Links em aparelho físico com perfil atualizado.
