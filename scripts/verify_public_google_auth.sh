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

for path in \
  web/site-assets/js/google-auth-core.mjs \
  web/site-assets/css/google-auth.css \
  build/web/site-assets/js/google-auth-core.mjs \
  build/web/site-assets/css/google-auth.css; do
  require_file "$path"
done

require_contains build/web/login.html 'data-google-login-button'
require_contains build/web/login.html '/site-assets/css/google-auth.css'
require_contains build/web/register.html 'data-google-register-button'
require_contains build/web/register.html '/site-assets/css/google-auth.css'
require_contains build/web/register.html 'href="/terms"'
require_contains build/web/register.html 'href="/privacy"'

require_contains build/web/site-assets/js/login.js "from './google-auth-core.mjs'"
require_contains build/web/site-assets/js/register.js "from './google-auth-core.mjs'"
require_contains build/web/site-assets/js/public-config.js 'googleWebClientId'
require_contains build/web/site-assets/js/public-config.js '841074493827-srvp19o45fh2edon9gq1kgcr1nhrtk5u.apps.googleusercontent.com'
require_contains lib/core/services/google_auth_service.dart '841074493827-srvp19o45fh2edon9gq1kgcr1nhrtk5u.apps.googleusercontent.com'

require_not_contains build/web/site-assets/js/public-config.js 'clientSecret'
require_not_contains build/web/site-assets/js/public-config.js 'client_secret'
require_not_contains web/public_login.html 'accounts.google.com'
require_not_contains web/public_register.html 'accounts.google.com'

if grep -Fq '194419403668-manc56voom9d29bv0n7m4pilub8j864a.apps.googleusercontent.com' \
  lib/core/services/google_auth_service.dart; then
  fail 'GoogleAuthService ainda usa o Web Client ID legado.'
fi

echo "[OK SIX] Public Google authentication validated"
