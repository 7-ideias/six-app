# six-app[README.md](README.md)
novo six app versao 2025

esses comandos sao necessarios para subir a app

```bash
flutter clean
flutter pub get
flutter gen-l10n
flutter build web
```

--------------------------------
RODAR O EMULADOR RAPIDAO [20260308]
```bash
~/Android/Sdk/emulator/emulator -list-avds
~/Android/Sdk/emulator/emulator -avd Pixel_5 -gpu host -no-snapshot -noaudio -no-boot-anim
```
--------------------------------

--------------------------------
# PARA RODAR A APP NO EMULADOR OU WEB - CONFIGURACOES [20260308]
# PASSO 1 - DESCOBRINDO O NOME DO DISPOSITIVO
```bash
flutter devices
```
exemplo de saida:
emulator-5554
chrome

# PASSO 2 - RODANDO A APP NO DISPOSITIVO
entao coloque no Additional run args para android:
    -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8082
e para web, coloque:
    -d chrome --dart-define=API_BASE_URL=http://localhost:8082
--------------------------------
