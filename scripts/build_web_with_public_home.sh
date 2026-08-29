#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/resolve_node.sh"
NODE_BIN="$(resolve_node)"
API_URL="$("$NODE_BIN" scripts/lib/resolve_public_api_base_url.mjs)"
export SIXAPP_PUBLIC_API_BASE_URL="$API_URL"

echo "[LOG SIX] Building Flutter Web with public HTML home"
echo "[LOG SIX] Web API base URL: $API_URL"

flutter --version
flutter pub get
flutter gen-l10n
flutter build web --release --no-wasm-dry-run --dart-define="API_BASE_URL=$API_URL"

grep -Fq 'name="sixapp-entrypoint" content="flutter-app"' build/web/index.html || {
  echo "[ERRO SIX] Flutter build nao gerou index.html com marker flutter-app" >&2
  exit 1
}

cp build/web/index.html build/web/flutter.html
cp web/public_home.html build/web/index.html
cp web/public_login.html build/web/login.html
cp web/public_register.html build/web/register.html
cp web/public_forgot_password.html build/web/forgot-password.html
cp web/public_onboarding.html build/web/onboarding.html
cp web/public_checkout.html build/web/checkout.html
cp web/public_catalog.html build/web/catalogo.html
cp web/public_collaborator_invite.html build/web/collaborator-invite.html
cp web/public_customer_signup.html build/web/customer-signup.html
rm -f build/web/public_home.html
rm -f build/web/public_login.html
rm -f build/web/public_register.html
rm -f build/web/public_forgot_password.html
rm -f build/web/public_onboarding.html
rm -f build/web/public_checkout.html
rm -f build/web/public_catalog.html
rm -f build/web/public_collaborator_invite.html
rm -f build/web/public_customer_signup.html

if [ -d web/site-assets ]; then
  rm -rf build/web/site-assets
  cp -R web/site-assets build/web/site-assets
fi

"$NODE_BIN" scripts/generate_public_web_config.mjs build/web/site-assets/js/public-config.js

if [ -f web/flutter_service_worker.js ]; then
  cp web/flutter_service_worker.js build/web/flutter_service_worker.js
fi

bash scripts/verify_web_strategy_a.sh

echo "[LOG SIX] Public home: build/web/index.html"
echo "[LOG SIX] Public login: build/web/login.html"
echo "[LOG SIX] Public register: build/web/register.html"
echo "[LOG SIX] Public forgot password: build/web/forgot-password.html"
echo "[LOG SIX] Public onboarding: build/web/onboarding.html"
echo "[LOG SIX] Public checkout: build/web/checkout.html"
echo "[LOG SIX] Public catalog: build/web/catalogo.html"
echo "[LOG SIX] Public collaborator invitation: build/web/collaborator-invite.html"
echo "[LOG SIX] Public customer signup: build/web/customer-signup.html"
echo "[LOG SIX] Flutter entry: build/web/flutter.html"
