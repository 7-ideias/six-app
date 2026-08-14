# six-app[README.md](README.md)
novo six app versao 2025

esses comandos sao uteis para preparar o projeto Flutter localmente

```bash
flutter clean
flutter pub get
flutter gen-l10n
```

Build correto de producao Web usado pela Vercel, com Home HTML em `/` e
Flutter Web nas rotas do app:

```bash
bash scripts/build_web_with_public_home.sh
```

Verificacao do artefato composto da Estrategia A:

```bash
bash scripts/verify_web_strategy_a.sh
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

# PASSO 1 - DESCOBRINDO O NOME DO DISPOSITIVO MOBILE LOCAL
```bash
flutter devices
```
exemplo de saida:
emulator-5554
chrome

# PASSO 2 - RODANDO A APP NO DISPOSITIVO 
entao coloque no Additional run args para android:
    -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8082

# PASSO 3 A - RODANDO A APP NA WEB COM PORTA ALEATORIA - o problema é que a cada vez que rodar, a porta muda, entao tem que ficar olhando qual porta foi escolhida
e para web, coloque:
    -d chrome --dart-define=API_BASE_URL=http://localhost:8082

# PASSO 3 B - RODANDO A APP NA WEB COM PORTA PERSONALIZADA - MINHA PREDILETA!!!
-d web-server --web-port=39441 --dart-define=API_BASE_URL=http://localhost:8082
--------------------------------
