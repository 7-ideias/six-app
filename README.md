# six-app[README.md](README.md)
novo six app versao 2025

esses comandos sao uteis para preparar o projeto Flutter localmente

```bash
flutter clean
flutter pub get
flutter gen-l10n
```

--------------------------------
RODAR O EMULADOR RAPIDAO [20260308]
```bash
~/Android/Sdk/emulator/emulator -list-avds
~/Android/Sdk/emulator/emulator -avd Pixel_5 -gpu host -no-snapshot -noaudio -no-boot-anim
```
--------------------------------

Build correto de producao Web usado pela Vercel, com Home HTML em `/` e
Flutter Web nas rotas do app:

```bash
bash scripts/build_web_with_public_home.sh
```

Verificacao do artefato composto da Estrategia A:

```bash
bash scripts/verify_web_strategy_a.sh
```

## Web debug com hot reload

Use este fluxo para desenvolver Flutter Web. Ele roda `flutter run` em modo
debug, entao preserva hot reload no terminal e no IntelliJ quando usado como
configuracao Flutter.

```bash
bash scripts/dev_web_hot_reload.sh
```

Padroes do script:

```text
API_BASE_URL=http://localhost:8082
SIXAPP_WEB_PORT=39441
SIXAPP_WEB_DEVICE=chrome
SIXAPP_WEB_LAUNCH_PATH=/login/flutter
SIXAPP_DISABLE_WEB_BROWSER_HANDOFF=true
SIXAPP_WEB_LOGS=normal
SIXAPP_FLUTTER_LOGS=terminal
```

Para mudar alguma coisa:

```bash
API_BASE_URL=https://api.sixappback.com \
SIXAPP_WEB_LAUNCH_PATH=/app \
bash scripts/dev_web_hot_reload.sh
```

Rotas uteis no modo debug Flutter:

```text
http://localhost:39441/app
http://localhost:39441/login/flutter
http://localhost:39441/register/flutter
http://localhost:39441/forgot-password/flutter
http://localhost:39441/onboarding/flutter
http://localhost:39441/checkout/flutter
```

No terminal do Flutter, use:

```text
r = hot reload
R = hot restart
q = sair
```

Logs opcionais:

```bash
# Esconde apenas os logs [LOG SIX] do wrapper.
SIXAPP_WEB_LOGS=quiet bash scripts/dev_web_hot_reload.sh

# Tira os logs do Flutter do terminal e grava em .dart_tool/sixapp_web_hot_reload.log.
SIXAPP_FLUTTER_LOGS=file bash scripts/dev_web_hot_reload.sh

# Silencia wrapper e Flutter. Use apenas quando nao precisar ver feedback do run.
SIXAPP_WEB_LOGS=quiet SIXAPP_FLUTTER_LOGS=quiet bash scripts/dev_web_hot_reload.sh
```

No IntelliJ, use uma configuracao do tipo Flutter apontando para
`lib/main.dart`, selecione o device `Chrome` e coloque em Additional run args:

```text
--web-port=39441 --web-launch-url=http://localhost:39441/login/flutter --dart-define=API_BASE_URL=http://localhost:8082 --dart-define=SIXAPP_DISABLE_WEB_BROWSER_HANDOFF=true
```

Nao use a configuracao de Script Shell para esse caso, porque ela serve para
build estatico e nao oferece os controles de hot reload do Flutter.

Se preferir rodar como Script Shell no IntelliJ, o Script text deve ser apenas:

```text
bash scripts/dev_web_hot_reload.sh
```

O wrapper de hot reload tambem aceita `--port 39441` por compatibilidade com
configuracoes antigas do servidor local.

Nao encadeie com `scripts/build_web_with_public_home.sh`; build release antes
do debug deixa o ciclo mais lento e nao ajuda no hot reload.

## Teste local production-like

Para testar localmente o build Web composto com rewrites equivalentes aos
essenciais da Vercel:

```bash
SIXAPP_PUBLIC_API_BASE_URL=https://api.sixappback.com \
bash scripts/build_web_with_public_home.sh

python3 scripts/dev_web_production_server.py --port 39441
```

Depois acesse:

```text
http://localhost:39441/
http://localhost:39441/login
http://localhost:39441/register
http://localhost:39441/forgot-password
http://localhost:39441/onboarding
http://localhost:39441/checkout
http://localhost:39441/app
```

O servidor local nao faz proxy da API. O frontend em `localhost:39441`
continua usando a URL configurada em `build/web/site-assets/js/public-config.js`.

## Web production-like com backend local

Para compilar as paginas publicas HTML e o Flutter Web apontando para o
backend local. Este fluxo nao tem hot reload, porque serve arquivos de
`build/web` depois de `flutter build web --release`:

```bash
SIXAPP_PUBLIC_API_BASE_URL=http://localhost:8082 \
bash scripts/build_web_with_public_home.sh

python3 scripts/dev_web_production_server.py --port 39441
```

Depois acesse:

```text
http://localhost:39441/login
```

A variavel `SIXAPP_PUBLIC_API_BASE_URL` configura o HTML publico e o
`API_BASE_URL` usado pelo Flutter Web no build composto.

Configuracao sugerida no IntelliJ:

```text
Name: WEB PRODUCTION-LIKE LOCAL
Working directory: /home/cartaxo/IdeaProjects/six-app
Script text: SIXAPP_PUBLIC_API_BASE_URL=http://localhost:8082 bash scripts/build_web_with_public_home.sh && python3 scripts/dev_web_production_server.py --port 39441
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

# PASSO 3 B - RODANDO A APP NA WEB COM PORTA PERSONALIZADA E HOT RELOAD
-d chrome --web-port=39441 --web-launch-url=http://localhost:39441/login/flutter --dart-define=API_BASE_URL=http://localhost:8082 --dart-define=SIXAPP_DISABLE_WEB_BROWSER_HANDOFF=true
--------------------------------
