#!/bin/bash

if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git
fi

export PATH="$PWD/flutter/bin:$PATH"
flutter upgrade
flutter doctor
flutter clean
flutter config --enable-web
flutter pub get
flutter gen-l10n
