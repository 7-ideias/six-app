# Firebase Push no Six App

A branch `feature/firebase` prepara o mobile Flutter para receber push via Firebase Cloud Messaging.

## Configuração do Firebase no build

O arquivo `lib/firebase_options.dart` usa `--dart-define` para evitar versionar arquivos de configuração reais no repositório.

Exemplo Android:

```bash
flutter run \
  --dart-define=FIREBASE_PROJECT_ID=six-app \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=000000000000 \
  --dart-define=FIREBASE_STORAGE_BUCKET=six-app.appspot.com \
  --dart-define=FIREBASE_ANDROID_API_KEY=android-api-key \
  --dart-define=FIREBASE_ANDROID_APP_ID=1:000000000000:android:abcdef
```

Exemplo iOS:

```bash
flutter run \
  --dart-define=FIREBASE_PROJECT_ID=six-app \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=000000000000 \
  --dart-define=FIREBASE_STORAGE_BUCKET=six-app.appspot.com \
  --dart-define=FIREBASE_IOS_API_KEY=ios-api-key \
  --dart-define=FIREBASE_IOS_APP_ID=1:000000000000:ios:abcdef \
  --dart-define=FIREBASE_IOS_BUNDLE_ID=br.com.seteideias.appplanilha
```

## Fluxo implementado

1. Após login/restauração de sessão, o app carrega os dados da empresa.
2. O app solicita permissão de notificação no mobile.
3. O app obtém o registro FCM do dispositivo.
4. O app envia esse registro para `POST /private/api/notificacoes/push-token` com `idUnicoDaEmpresa` e `Authorization`.
5. Mensagens em foreground são exibidas via notificação local e também entram no `NotificacaoService`.

## Ajuste iOS obrigatório fora do conector

No Xcode, habilite:

- Push Notifications
- Background Modes > Remote notifications

Também configure o APNs no projeto Firebase para o bundle do iOS.
