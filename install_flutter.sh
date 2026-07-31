#!/usr/bin/env bash

set -euo pipefail

FLUTTER_VERSION="3.41.4"
FLUTTER_DIR="$PWD/flutter"

echo "[LOG SIX] INICIANDO INSTALAÇÃO DO FLUTTER"
echo "[LOG SIX] VERSÃO FIXADA: $FLUTTER_VERSION"

if [ -d "$FLUTTER_DIR" ]; then
  echo "[LOG SIX] REMOVENDO INSTALAÇÃO ANTERIOR DO FLUTTER"
  rm -rf "$FLUTTER_DIR"
fi

echo "[LOG SIX] CLONANDO FLUTTER $FLUTTER_VERSION"

git clone \
  --depth 1 \
  --branch "$FLUTTER_VERSION" \
  https://github.com/flutter/flutter.git \
  "$FLUTTER_DIR"

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "[LOG SIX] FLUTTER INSTALADO:"
flutter --version

echo "[LOG SIX] CONFIGURANDO SUPORTE WEB"
flutter config --enable-web

echo "[LOG SIX] INSTALAÇÃO DO FLUTTER FINALIZADA"
