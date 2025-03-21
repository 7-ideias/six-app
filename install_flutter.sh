#!/bin/bash

if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git
fi

export PATH="$PWD/flutter/bin:$PATH"

echo "[LOG SIX] INICIO DO BATCH... ACOMPANHE OS LOGS"

STEP=1
TOTAL=7 #MANTENHA ISSO ATUALIZADO!

log_step() {
  echo "[LOG SIX] $(printf "%02d" $STEP) DE $(printf "%02d" $TOTAL) $1"
  STEP=$((STEP + 1))
}

log_step "DANDO UM UPGRADE"
flutter upgrade

log_step "VERIFICANDO COM O DOCTOR COMO ESTA O FLUTTER APOS INSTALADO..."
flutter doctor

log_step "SE NAO ACHAR O ANDROID, NAO SE PREOCUPE. DEU BOM!"

log_step "DANDO UM CLEANSINHO DE BOA"
flutter clean

log_step "CONFIGURANDO WEB"
flutter config --enable-web

log_step "INICIO DO PUBGET"
flutter pub get
#flutter gen-l10n

echo "[LOG SIX] FINALIZEI AS CONFIGS DO PROJETO"
#echo "ARQUIVOS GERADOS:"
#find . -name "app_localizations.dart"
