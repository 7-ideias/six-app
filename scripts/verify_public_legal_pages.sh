#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "[ERRO SIX] $*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "Arquivo obrigatorio ausente: $1"
}

require_contains() {
  grep -Fq "$2" "$1" || fail "$1 nao contem: $2"
}

require_not_contains() {
  if grep -Fq "$2" "$1"; then
    fail "$1 contem padrao proibido: $2"
  fi
}

for page in privacy terms; do
  source_path="web/public_${page}.html"
  build_path="build/web/${page}.html"

  require_file "$source_path"
  require_file "$build_path"

  require_contains "$build_path" "name=\"sixapp-entrypoint\" content=\"public-${page}\""
  require_contains "$build_path" "name=\"robots\" content=\"index, follow\""
  require_contains "$build_path" "/site-assets/css/public-base.css"
  require_contains "$build_path" "/site-assets/css/legal.css"
  require_contains "$build_path" "/site-assets/js/legal.js"
  require_contains "$build_path" 'data-legal-lang="pt"'
  require_contains "$build_path" 'data-legal-lang="en"'
  require_contains "$build_path" 'data-legal-lang="es"'
  require_contains "$build_path" "https://www.sixoapp.com/${page}"

  require_not_contains "$build_path" 'flutter_bootstrap.js'
  require_not_contains "$build_path" 'main.dart.js'
  require_not_contains "$build_path" 'accounts.google.com'
  require_not_contains "$build_path" 'google-signin'
done

require_contains build/web/privacy.html 'privacy-v1'
require_contains build/web/terms.html 'terms-v1'
require_contains build/web/privacy.html '/terms'
require_contains build/web/terms.html '/privacy'

require_file build/web/site-assets/css/legal.css
require_file build/web/site-assets/js/legal.js
require_contains vercel.json '"source": "/privacy"'
require_contains vercel.json '"destination": "/privacy.html"'
require_contains vercel.json '"source": "/terms"'
require_contains vercel.json '"destination": "/terms.html"'

echo "[OK SIX] Public legal pages validated"
