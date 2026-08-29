#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/resolve_node.sh"

fail() {
  echo "[ERRO SIX] $*" >&2
  exit 1
}

ok() {
  echo "[OK SIX] $*"
}

section() {
  echo "[LOG SIX] === $* ==="
}

require_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "Arquivo obrigatorio ausente: $path"
}

require_dir() {
  local path="$1"
  [[ -d "$path" ]] || fail "Diretorio obrigatorio ausente: $path"
}

require_contains() {
  local path="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$path" || fail "$path nao contem: $pattern"
}

require_not_contains() {
  local path="$1"
  local pattern="$2"
  if grep -Fq "$pattern" "$path"; then
    fail "$path contem padrao proibido: $pattern"
  fi
}

require_no_public_forbidden_terms() {
  local path="$1"
  for pattern in 'Six POS' 'Six ERP' 'Seven'; do
    require_not_contains "$path" "$pattern"
  done
}

validate_public_site_asset_references() {
  local html_path="$1"
  local asset_ref
  local asset_refs
  local asset_path

  asset_refs="$(grep -Eo '(src|href|srcset)="[^"]+"' "$html_path" |
    sed -E 's/^[^"]+"//; s/"$//' |
    grep '^/site-assets/' || true)"

  [[ -n "$asset_refs" ]] || return 0

  while IFS= read -r asset_ref; do
    asset_path="${asset_ref%% *}"
    asset_path="${asset_path%%\?*}"
    [[ -f "build/web${asset_path}" ]] ||
      fail "Referencia publica sem arquivo correspondente: ${asset_path}"
  done <<< "$asset_refs"
}

NODE_BIN="$(resolve_node)"

section "ASSETS"

require_file build/web/index.html
require_file build/web/login.html
require_file build/web/register.html
require_file build/web/forgot-password.html
require_file build/web/onboarding.html
require_file build/web/checkout.html
require_file build/web/catalogo.html
require_file build/web/collaborator-invite.html
require_file build/web/flutter.html
require_file build/web/flutter_bootstrap.js
require_file build/web/main.dart.js
require_file build/web/flutter_service_worker.js
require_file web/public_login.html
require_file web/public_register.html
require_file web/public_forgot_password.html
require_file web/public_onboarding.html
require_file web/public_checkout.html
require_file web/public_catalog.html
require_file web/public_collaborator_invite.html
require_file web/catalogo.html
require_file web/site-assets/css/public-base.css
require_file web/site-assets/css/home.css
require_file web/site-assets/css/sixoapp-public.css
require_file web/site-assets/css/login.css
require_file web/site-assets/css/register.css
require_file web/site-assets/css/forgot-password.css
require_file web/site-assets/css/onboarding.css
require_file web/site-assets/css/checkout.css
require_file web/site-assets/css/catalog.css
require_file web/site-assets/css/collaborator-invite.css
require_file web/site-assets/js/public-locale.mjs
require_file web/site-assets/js/login-core.mjs
require_file web/site-assets/js/login.js
require_file web/site-assets/js/register-core.mjs
require_file web/site-assets/js/register.js
require_file web/site-assets/js/forgot-password-core.mjs
require_file web/site-assets/js/forgot-password.js
require_file web/site-assets/js/onboarding-core.mjs
require_file web/site-assets/js/onboarding.js
require_file web/site-assets/js/checkout-core.mjs
require_file web/site-assets/js/checkout.js
require_file web/site-assets/js/catalog-core.mjs
require_file web/site-assets/js/catalog.js
require_file web/site-assets/js/collaborator-invite-core.mjs
require_file web/site-assets/js/collaborator-invite.js
require_file web/site-assets/js/home.js
require_file web/site-assets/images/sixoapp-mark.png
require_file web/site-assets/images/sixoapp-symbol.png
require_file web/site-assets/images/commerce-workspace.webp
require_file build/web/site-assets/css/public-base.css
require_file build/web/site-assets/css/home.css
require_file build/web/site-assets/css/sixoapp-public.css
require_file build/web/site-assets/css/login.css
require_file build/web/site-assets/css/register.css
require_file build/web/site-assets/css/forgot-password.css
require_file build/web/site-assets/css/onboarding.css
require_file build/web/site-assets/css/checkout.css
require_file build/web/site-assets/css/catalog.css
require_file build/web/site-assets/css/collaborator-invite.css
require_file build/web/site-assets/js/public-locale.mjs
require_file build/web/site-assets/js/login-core.mjs
require_file build/web/site-assets/js/login.js
require_file build/web/site-assets/js/register-core.mjs
require_file build/web/site-assets/js/register.js
require_file build/web/site-assets/js/forgot-password-core.mjs
require_file build/web/site-assets/js/forgot-password.js
require_file build/web/site-assets/js/onboarding-core.mjs
require_file build/web/site-assets/js/onboarding.js
require_file build/web/site-assets/js/checkout-core.mjs
require_file build/web/site-assets/js/checkout.js
require_file build/web/site-assets/js/catalog-core.mjs
require_file build/web/site-assets/js/catalog.js
require_file build/web/site-assets/js/collaborator-invite-core.mjs
require_file build/web/site-assets/js/collaborator-invite.js
require_file build/web/site-assets/js/home.js
require_file build/web/site-assets/js/public-config.js
require_file build/web/site-assets/images/sixoapp-mark.png
require_file build/web/site-assets/images/sixoapp-symbol.png
require_file build/web/site-assets/images/commerce-workspace.webp
require_dir build/web/assets
require_dir build/web/canvaskit

section "HOME"

require_contains build/web/index.html 'name="sixapp-entrypoint" content="public-home"'
require_not_contains build/web/index.html 'name="sixapp-entrypoint" content="flutter-app"'
require_not_contains build/web/index.html 'flutter_bootstrap.js'
require_not_contains build/web/index.html 'main.dart.js'
require_not_contains build/web/index.html 'flutter.js'
require_not_contains build/web/index.html 'canvaskit'
require_not_contains build/web/index.html 'accounts.google.com'
require_not_contains build/web/index.html 'fonts.googleapis'
require_no_public_forbidden_terms build/web/index.html
require_not_contains build/web/index.html '/assets/'
require_not_contains build/web/index.html '<link rel="manifest"'
require_not_contains build/web/index.html 'href="site-assets'
require_not_contains build/web/index.html 'src="site-assets'
require_contains build/web/index.html '/site-assets/css/public-base.css'
require_contains build/web/index.html '/site-assets/css/home.css'
require_contains build/web/index.html '/site-assets/js/home.js'
require_contains build/web/index.html '/site-assets/images/sixoapp-mark.png'
require_contains build/web/index.html '/site-assets/images/sixoapp-symbol.png'
require_not_contains build/web/index.html 'href="/onboarding"'
validate_public_site_asset_references build/web/index.html

section "LOGIN"

require_contains build/web/login.html 'name="sixapp-entrypoint" content="public-login"'
require_contains build/web/login.html 'name="robots" content="noindex, nofollow"'
require_not_contains build/web/login.html 'name="sixapp-entrypoint" content="flutter-app"'
require_not_contains build/web/login.html 'flutter_bootstrap.js'
require_not_contains build/web/login.html 'main.dart.js'
require_not_contains build/web/login.html 'flutter.js'
require_not_contains build/web/login.html 'canvaskit'
require_not_contains build/web/login.html 'CanvasKit'
require_not_contains build/web/login.html 'accounts.google.com'
require_not_contains build/web/login.html 'google-signin'
require_not_contains build/web/login.html 'fonts.googleapis'
require_not_contains build/web/login.html '<link rel="manifest"'
require_not_contains build/web/login.html 'manifest.json'
require_not_contains build/web/login.html '/assets/'
require_not_contains build/web/login.html 'href="site-assets'
require_not_contains build/web/login.html 'src="site-assets'
require_not_contains build/web/login.html 'https://'
require_not_contains build/web/login.html 'http://'
require_contains build/web/login.html '/site-assets/css/public-base.css'
require_contains build/web/login.html '/site-assets/css/login.css'
require_contains build/web/login.html '/site-assets/js/public-config.js'
require_contains build/web/login.html '/site-assets/js/login.js'
require_contains build/web/login.html '/site-assets/images/sixoapp-mark.png'
require_contains build/web/login.html '/site-assets/css/sixoapp-public.css'
require_contains build/web/login.html '/login/flutter'
require_no_public_forbidden_terms build/web/login.html
validate_public_site_asset_references build/web/login.html

section "REGISTER"

require_contains build/web/register.html 'name="sixapp-entrypoint" content="public-register"'
require_contains build/web/register.html 'name="robots" content="noindex, nofollow"'
require_not_contains build/web/register.html 'name="sixapp-entrypoint" content="flutter-app"'
require_not_contains build/web/register.html 'flutter_bootstrap.js'
require_not_contains build/web/register.html 'main.dart.js'
require_not_contains build/web/register.html 'flutter.js'
require_not_contains build/web/register.html 'canvaskit'
require_not_contains build/web/register.html 'CanvasKit'
require_not_contains build/web/register.html 'accounts.google.com'
require_not_contains build/web/register.html 'google-signin'
require_not_contains build/web/register.html 'fonts.googleapis'
require_not_contains build/web/register.html '<link rel="manifest"'
require_not_contains build/web/register.html 'manifest.json'
require_not_contains build/web/register.html '/assets/'
require_not_contains build/web/register.html 'href="site-assets'
require_not_contains build/web/register.html 'src="site-assets'
require_not_contains build/web/register.html 'https://'
require_not_contains build/web/register.html 'http://'
require_contains build/web/register.html '/site-assets/css/public-base.css'
require_contains build/web/register.html '/site-assets/css/register.css'
require_contains build/web/register.html '/site-assets/js/public-config.js'
require_contains build/web/register.html '/site-assets/js/register.js'
require_contains build/web/register.html '/site-assets/images/sixoapp-mark.png'
require_contains build/web/register.html '/site-assets/css/sixoapp-public.css'
require_contains build/web/register.html '/register/flutter'
require_contains build/web/register.html '<noscript>'
require_no_public_forbidden_terms build/web/register.html
validate_public_site_asset_references build/web/register.html

section "COLLABORATOR INVITATION"

require_contains build/web/collaborator-invite.html 'name="sixapp-entrypoint" content="public-collaborator-invite"'
require_contains build/web/collaborator-invite.html 'name="robots" content="noindex, nofollow"'
require_contains build/web/collaborator-invite.html 'name="referrer" content="no-referrer"'
require_not_contains build/web/collaborator-invite.html 'name="sixapp-entrypoint" content="flutter-app"'
require_not_contains build/web/collaborator-invite.html 'flutter_bootstrap.js'
require_not_contains build/web/collaborator-invite.html 'main.dart.js'
require_not_contains build/web/collaborator-invite.html 'flutter.js'
require_not_contains build/web/collaborator-invite.html 'canvaskit'
require_not_contains build/web/collaborator-invite.html 'CanvasKit'
require_not_contains build/web/collaborator-invite.html 'accounts.google.com'
require_not_contains build/web/collaborator-invite.html 'google-signin'
require_not_contains build/web/collaborator-invite.html 'fonts.googleapis'
require_not_contains build/web/collaborator-invite.html '<link rel="manifest"'
require_not_contains build/web/collaborator-invite.html 'manifest.json'
require_not_contains build/web/collaborator-invite.html '/assets/'
require_not_contains build/web/collaborator-invite.html 'href="site-assets'
require_not_contains build/web/collaborator-invite.html 'src="site-assets'
require_not_contains build/web/collaborator-invite.html 'https://'
require_not_contains build/web/collaborator-invite.html 'http://'
require_contains build/web/collaborator-invite.html '/site-assets/css/public-base.css'
require_contains build/web/collaborator-invite.html '/site-assets/css/collaborator-invite.css'
require_contains build/web/collaborator-invite.html '/site-assets/js/public-config.js'
require_contains build/web/collaborator-invite.html '/site-assets/js/collaborator-invite.js'
require_contains build/web/collaborator-invite.html '/site-assets/images/sixoapp-mark.png'
require_contains build/web/collaborator-invite.html '/site-assets/css/sixoapp-public.css'
require_contains build/web/collaborator-invite.html '<noscript>'
require_no_public_forbidden_terms build/web/collaborator-invite.html
validate_public_site_asset_references build/web/collaborator-invite.html

section "FORGOT PASSWORD"

require_contains build/web/forgot-password.html 'name="sixapp-entrypoint" content="public-forgot-password"'
require_contains build/web/forgot-password.html 'name="robots" content="noindex, nofollow"'
require_not_contains build/web/forgot-password.html 'name="sixapp-entrypoint" content="flutter-app"'
require_not_contains build/web/forgot-password.html 'flutter_bootstrap.js'
require_not_contains build/web/forgot-password.html 'main.dart.js'
require_not_contains build/web/forgot-password.html 'flutter.js'
require_not_contains build/web/forgot-password.html 'canvaskit'
require_not_contains build/web/forgot-password.html 'CanvasKit'
require_not_contains build/web/forgot-password.html 'accounts.google.com'
require_not_contains build/web/forgot-password.html 'google-signin'
require_not_contains build/web/forgot-password.html 'fonts.googleapis'
require_not_contains build/web/forgot-password.html '<link rel="manifest"'
require_not_contains build/web/forgot-password.html 'manifest.json'
require_not_contains build/web/forgot-password.html '/assets/'
require_not_contains build/web/forgot-password.html 'href="site-assets'
require_not_contains build/web/forgot-password.html 'src="site-assets'
require_not_contains build/web/forgot-password.html 'https://'
require_not_contains build/web/forgot-password.html 'http://'
require_contains build/web/forgot-password.html '/site-assets/css/public-base.css'
require_contains build/web/forgot-password.html '/site-assets/css/forgot-password.css'
require_contains build/web/forgot-password.html '/site-assets/js/public-config.js'
require_contains build/web/forgot-password.html '/site-assets/js/forgot-password.js'
require_contains build/web/forgot-password.html '/site-assets/images/sixoapp-mark.png'
require_contains build/web/forgot-password.html '/site-assets/css/sixoapp-public.css'
require_contains build/web/forgot-password.html '/forgot-password/flutter'
require_contains build/web/forgot-password.html '<noscript>'
require_no_public_forbidden_terms build/web/forgot-password.html
validate_public_site_asset_references build/web/forgot-password.html

section "ONBOARDING"

require_contains build/web/onboarding.html 'name="sixapp-entrypoint" content="public-onboarding"'
require_contains build/web/onboarding.html 'name="robots" content="noindex, nofollow"'
require_not_contains build/web/onboarding.html 'name="sixapp-entrypoint" content="flutter-app"'
require_not_contains build/web/onboarding.html 'flutter_bootstrap.js'
require_not_contains build/web/onboarding.html 'main.dart.js'
require_not_contains build/web/onboarding.html 'flutter.js'
require_not_contains build/web/onboarding.html 'canvaskit'
require_not_contains build/web/onboarding.html 'CanvasKit'
require_not_contains build/web/onboarding.html 'accounts.google.com'
require_not_contains build/web/onboarding.html 'google-signin'
require_not_contains build/web/onboarding.html 'fonts.googleapis'
require_not_contains build/web/onboarding.html '<link rel="manifest"'
require_not_contains build/web/onboarding.html 'manifest.json'
require_not_contains build/web/onboarding.html '/assets/'
require_not_contains build/web/onboarding.html 'href="site-assets'
require_not_contains build/web/onboarding.html 'src="site-assets'
require_not_contains build/web/onboarding.html 'https://'
require_not_contains build/web/onboarding.html 'http://'
require_contains build/web/onboarding.html '/site-assets/css/public-base.css'
require_contains build/web/onboarding.html '/site-assets/css/onboarding.css'
require_contains build/web/onboarding.html '/site-assets/js/onboarding.js'
require_contains build/web/onboarding.html '/site-assets/images/sixoapp-mark.png'
require_contains build/web/onboarding.html '/onboarding/flutter'
require_contains build/web/onboarding.html '<noscript>'
require_no_public_forbidden_terms build/web/onboarding.html
validate_public_site_asset_references build/web/onboarding.html

section "CHECKOUT"

require_contains build/web/checkout.html 'name="sixapp-entrypoint" content="public-checkout"'
require_contains build/web/checkout.html 'name="robots" content="noindex, nofollow"'
require_not_contains build/web/checkout.html 'name="sixapp-entrypoint" content="flutter-app"'
require_not_contains build/web/checkout.html 'flutter_bootstrap.js'
require_not_contains build/web/checkout.html 'main.dart.js'
require_not_contains build/web/checkout.html 'flutter.js'
require_not_contains build/web/checkout.html 'canvaskit'
require_not_contains build/web/checkout.html 'CanvasKit'
require_not_contains build/web/checkout.html 'accounts.google.com'
require_not_contains build/web/checkout.html 'google-signin'
require_not_contains build/web/checkout.html 'fonts.googleapis'
require_not_contains build/web/checkout.html '<link rel="manifest"'
require_not_contains build/web/checkout.html 'manifest.json'
require_not_contains build/web/checkout.html '/assets/'
require_not_contains build/web/checkout.html 'href="site-assets'
require_not_contains build/web/checkout.html 'src="site-assets'
require_not_contains build/web/checkout.html 'https://'
require_not_contains build/web/checkout.html 'http://'
require_contains build/web/checkout.html '/site-assets/css/public-base.css'
require_contains build/web/checkout.html '/site-assets/css/checkout.css'
require_contains build/web/checkout.html '/site-assets/js/public-config.js'
require_contains build/web/checkout.html '/site-assets/js/checkout.js'
require_contains build/web/checkout.html '/site-assets/images/sixoapp-mark.png'
require_contains build/web/checkout.html '/site-assets/css/sixoapp-public.css'
require_contains build/web/checkout.html '/checkout/flutter'
require_contains build/web/checkout.html '<noscript>'
require_no_public_forbidden_terms build/web/checkout.html
validate_public_site_asset_references build/web/checkout.html

section "CATALOG"

require_contains build/web/catalogo.html 'name="sixapp-entrypoint" content="public-catalog"'
require_contains build/web/catalogo.html 'name="robots" content="noindex, nofollow"'
require_not_contains build/web/catalogo.html 'name="sixapp-entrypoint" content="flutter-app"'
require_not_contains build/web/catalogo.html 'flutter_bootstrap.js'
require_not_contains build/web/catalogo.html 'main.dart.js'
require_not_contains build/web/catalogo.html 'flutter.js'
require_not_contains build/web/catalogo.html 'canvaskit'
require_not_contains build/web/catalogo.html 'fonts.googleapis'
require_not_contains build/web/catalogo.html 'accounts.google.com'
require_not_contains build/web/catalogo.html '<link rel="manifest"'
require_not_contains build/web/catalogo.html 'manifest.json'
require_not_contains build/web/catalogo.html '/assets/'
require_not_contains build/web/catalogo.html 'href="site-assets'
require_not_contains build/web/catalogo.html 'src="site-assets'
require_not_contains build/web/catalogo.html 'https://'
require_not_contains build/web/catalogo.html 'http://'
require_contains build/web/catalogo.html '/site-assets/css/public-base.css'
require_contains build/web/catalogo.html '/site-assets/css/catalog.css'
require_contains build/web/catalogo.html '/site-assets/js/public-config.js'
require_contains build/web/catalogo.html '/site-assets/js/catalog.js'
require_contains build/web/catalogo.html '/site-assets/images/sixoapp-mark.png'
require_contains build/web/catalogo.html '<noscript>'
require_no_public_forbidden_terms build/web/catalogo.html
validate_public_site_asset_references build/web/catalogo.html

section "FLUTTER"

require_contains build/web/flutter.html 'name="sixapp-entrypoint" content="flutter-app"'
require_not_contains build/web/flutter.html '<meta name="viewport"'
require_contains build/web/flutter.html '<base href="/">'
require_contains build/web/flutter.html 'flutter_bootstrap.js'
require_contains build/web/flutter_bootstrap.js 'main.dart.js'

require_contains build/web/site-assets/js/public-config.js 'window.SIXAPP_PUBLIC_CONFIG'
require_contains build/web/site-assets/js/public-config.js 'apiBaseUrl'
require_not_contains build/web/site-assets/js/public-config.js 'PLACEHOLDER'
require_not_contains build/web/site-assets/js/public-config.js 'client_secret'
require_not_contains build/web/site-assets/js/public-config.js 'access_token'
require_not_contains build/web/site-assets/js/public-config.js 'refresh_token'
require_not_contains build/web/site-assets/js/public-config.js 'password='
require_not_contains build/web/site-assets/js/public-config.js 'senha='
require_not_contains build/web/site-assets/js/public-config.js 'token='
"$NODE_BIN" --input-type=module <<'NODE'
import { readFileSync } from 'node:fs';
import { normalizeApiBaseUrl } from './build/web/site-assets/js/login-core.mjs';
const source = readFileSync('build/web/site-assets/js/public-config.js', 'utf8');
const match = source.match(/apiBaseUrl:\s*"([^"]+)"/);
if (!match) {
  console.error('[ERRO SIX] public-config.js nao expoe apiBaseUrl.');
  process.exit(1);
}
const value = match[1];
try {
  if (normalizeApiBaseUrl(value) !== value) {
    throw new Error('URL nao esta normalizada.');
  }
} catch (error) {
  console.error('[ERRO SIX] public-config.js contem URL publica invalida.');
  process.exit(1);
}
NODE

section "VERCEL"

"$NODE_BIN" scripts/lib/verify_vercel_config.mjs vercel.json

section "SECURITY"

require_contains web/index.html 'name="sixapp-entrypoint" content="flutter-app"'
require_not_contains web/index.html '<meta name="viewport"'
require_contains web/public_home.html 'name="sixapp-entrypoint" content="public-home"'
require_contains web/public_login.html 'name="sixapp-entrypoint" content="public-login"'
require_contains web/public_login.html 'name="robots" content="noindex, nofollow"'
require_contains web/public_register.html 'name="sixapp-entrypoint" content="public-register"'
require_contains web/public_register.html 'name="robots" content="noindex, nofollow"'
require_contains web/public_forgot_password.html 'name="sixapp-entrypoint" content="public-forgot-password"'
require_contains web/public_forgot_password.html 'name="robots" content="noindex, nofollow"'
require_contains web/public_onboarding.html 'name="sixapp-entrypoint" content="public-onboarding"'
require_contains web/public_onboarding.html 'name="robots" content="noindex, nofollow"'
require_contains web/public_checkout.html 'name="sixapp-entrypoint" content="public-checkout"'
require_contains web/public_checkout.html 'name="robots" content="noindex, nofollow"'
require_contains web/public_catalog.html 'name="sixapp-entrypoint" content="public-catalog"'
require_contains web/public_catalog.html 'name="robots" content="noindex, nofollow"'
require_contains web/public_collaborator_invite.html 'name="sixapp-entrypoint" content="public-collaborator-invite"'
require_contains web/public_collaborator_invite.html 'name="robots" content="noindex, nofollow"'
require_contains web/public_collaborator_invite.html 'name="referrer" content="no-referrer"'
require_contains web/public_home.html '/site-assets/css/public-base.css'
require_contains web/public_home.html '/site-assets/css/home.css'
require_contains web/public_home.html '/site-assets/js/home.js'
require_contains web/public_home.html '/site-assets/images/sixoapp-mark.png'
require_contains web/public_home.html '/site-assets/images/sixoapp-symbol.png'
require_not_contains web/public_home.html 'href="/onboarding"'
require_contains web/public_login.html '/site-assets/css/public-base.css'
require_contains web/public_login.html '/site-assets/css/login.css'
require_contains web/public_login.html '/site-assets/js/public-config.js'
require_contains web/public_login.html '/site-assets/js/login.js'
require_contains web/public_login.html '/site-assets/images/sixoapp-mark.png'
require_contains web/public_login.html '/site-assets/css/sixoapp-public.css'
require_contains web/public_register.html '/site-assets/css/public-base.css'
require_contains web/public_register.html '/site-assets/css/register.css'
require_contains web/public_register.html '/site-assets/js/public-config.js'
require_contains web/public_register.html '/site-assets/js/register.js'
require_contains web/public_register.html '/site-assets/images/sixoapp-mark.png'
require_contains web/public_register.html '/site-assets/css/sixoapp-public.css'
require_contains web/public_register.html '/register/flutter'
require_contains web/public_forgot_password.html '/site-assets/css/public-base.css'
require_contains web/public_forgot_password.html '/site-assets/css/forgot-password.css'
require_contains web/public_forgot_password.html '/site-assets/js/public-config.js'
require_contains web/public_forgot_password.html '/site-assets/js/forgot-password.js'
require_contains web/public_forgot_password.html '/site-assets/images/sixoapp-mark.png'
require_contains web/public_forgot_password.html '/site-assets/css/sixoapp-public.css'
require_contains web/public_forgot_password.html '/forgot-password/flutter'
require_contains web/public_onboarding.html '/site-assets/css/public-base.css'
require_contains web/public_onboarding.html '/site-assets/css/onboarding.css'
require_contains web/public_onboarding.html '/site-assets/js/onboarding.js'
require_contains web/public_onboarding.html '/site-assets/images/sixoapp-mark.png'
require_contains web/public_onboarding.html '/onboarding/flutter'
require_contains web/public_onboarding.html '<noscript>'
require_contains web/public_checkout.html '/site-assets/css/public-base.css'
require_contains web/public_checkout.html '/site-assets/css/checkout.css'
require_contains web/public_checkout.html '/site-assets/js/public-config.js'
require_contains web/public_checkout.html '/site-assets/js/checkout.js'
require_contains web/public_checkout.html '/site-assets/images/sixoapp-mark.png'
require_contains web/public_checkout.html '/site-assets/css/sixoapp-public.css'
require_contains web/public_checkout.html '/checkout/flutter'
require_contains web/public_checkout.html '<noscript>'
require_contains web/public_catalog.html '/site-assets/css/public-base.css'
require_contains web/public_catalog.html '/site-assets/css/catalog.css'
require_contains web/public_catalog.html '/site-assets/js/public-config.js'
require_contains web/public_catalog.html '/site-assets/js/catalog.js'
require_contains web/public_catalog.html '/site-assets/images/sixoapp-mark.png'
require_contains web/public_catalog.html '<noscript>'
require_contains web/public_collaborator_invite.html '/site-assets/css/public-base.css'
require_contains web/public_collaborator_invite.html '/site-assets/css/collaborator-invite.css'
require_contains web/public_collaborator_invite.html '/site-assets/js/public-config.js'
require_contains web/public_collaborator_invite.html '/site-assets/js/collaborator-invite.js'
require_contains web/public_collaborator_invite.html '/site-assets/images/sixoapp-mark.png'
require_contains web/public_collaborator_invite.html '/site-assets/css/sixoapp-public.css'
require_contains web/public_collaborator_invite.html '<noscript>'
require_no_public_forbidden_terms web/public_home.html
require_no_public_forbidden_terms web/public_login.html
require_no_public_forbidden_terms web/public_register.html
require_no_public_forbidden_terms web/public_forgot_password.html
require_no_public_forbidden_terms web/public_onboarding.html
require_no_public_forbidden_terms web/public_checkout.html
require_no_public_forbidden_terms web/public_catalog.html
require_no_public_forbidden_terms web/public_collaborator_invite.html
require_no_public_forbidden_terms web/site-assets/js/home.js
require_no_public_forbidden_terms web/site-assets/js/login.js
require_no_public_forbidden_terms web/site-assets/js/register.js
require_no_public_forbidden_terms web/site-assets/js/register-core.mjs
require_no_public_forbidden_terms web/site-assets/js/forgot-password.js
require_no_public_forbidden_terms web/site-assets/js/forgot-password-core.mjs
require_no_public_forbidden_terms web/site-assets/js/onboarding.js
require_no_public_forbidden_terms web/site-assets/js/onboarding-core.mjs
require_no_public_forbidden_terms web/site-assets/js/checkout.js
require_no_public_forbidden_terms web/site-assets/js/checkout-core.mjs
require_no_public_forbidden_terms web/site-assets/js/catalog.js
require_no_public_forbidden_terms web/site-assets/js/catalog-core.mjs
require_no_public_forbidden_terms web/site-assets/js/collaborator-invite.js
require_no_public_forbidden_terms web/site-assets/js/collaborator-invite-core.mjs
require_no_public_forbidden_terms web/site-assets/css/public-base.css
require_no_public_forbidden_terms web/site-assets/css/home.css
require_no_public_forbidden_terms web/site-assets/css/login.css
require_no_public_forbidden_terms web/site-assets/css/register.css
require_no_public_forbidden_terms web/site-assets/css/forgot-password.css
require_no_public_forbidden_terms web/site-assets/css/onboarding.css
require_no_public_forbidden_terms web/site-assets/css/checkout.css
require_no_public_forbidden_terms web/site-assets/css/catalog.css
require_no_public_forbidden_terms web/site-assets/css/collaborator-invite.css
require_no_public_forbidden_terms build/web/site-assets/js/home.js
require_no_public_forbidden_terms build/web/site-assets/js/login.js
require_no_public_forbidden_terms build/web/site-assets/js/register.js
require_no_public_forbidden_terms build/web/site-assets/js/register-core.mjs
require_no_public_forbidden_terms build/web/site-assets/js/forgot-password.js
require_no_public_forbidden_terms build/web/site-assets/js/forgot-password-core.mjs
require_no_public_forbidden_terms build/web/site-assets/js/onboarding.js
require_no_public_forbidden_terms build/web/site-assets/js/onboarding-core.mjs
require_no_public_forbidden_terms build/web/site-assets/js/checkout.js
require_no_public_forbidden_terms build/web/site-assets/js/checkout-core.mjs
require_no_public_forbidden_terms build/web/site-assets/js/catalog.js
require_no_public_forbidden_terms build/web/site-assets/js/catalog-core.mjs
require_no_public_forbidden_terms build/web/site-assets/js/collaborator-invite.js
require_no_public_forbidden_terms build/web/site-assets/js/collaborator-invite-core.mjs
require_no_public_forbidden_terms build/web/site-assets/css/public-base.css
require_no_public_forbidden_terms build/web/site-assets/css/home.css
require_no_public_forbidden_terms build/web/site-assets/css/login.css
require_no_public_forbidden_terms build/web/site-assets/css/register.css
require_no_public_forbidden_terms build/web/site-assets/css/forgot-password.css
require_no_public_forbidden_terms build/web/site-assets/css/onboarding.css
require_no_public_forbidden_terms build/web/site-assets/css/checkout.css
require_no_public_forbidden_terms build/web/site-assets/css/catalog.css
require_no_public_forbidden_terms build/web/site-assets/css/collaborator-invite.css
require_not_contains web/public_home.html 'fonts.googleapis'
require_not_contains web/public_home.html 'accounts.google.com'
require_not_contains web/public_login.html 'fonts.googleapis'
require_not_contains web/public_login.html 'accounts.google.com'
require_not_contains web/public_register.html 'fonts.googleapis'
require_not_contains web/public_register.html 'accounts.google.com'
require_not_contains web/public_forgot_password.html 'fonts.googleapis'
require_not_contains web/public_forgot_password.html 'accounts.google.com'
require_not_contains web/public_onboarding.html 'fonts.googleapis'
require_not_contains web/public_onboarding.html 'accounts.google.com'
require_not_contains web/public_checkout.html 'fonts.googleapis'
require_not_contains web/public_checkout.html 'accounts.google.com'
require_not_contains web/public_catalog.html 'fonts.googleapis'
require_not_contains web/public_catalog.html 'accounts.google.com'
require_not_contains web/public_onboarding.html 'flutter_bootstrap.js'
require_not_contains web/public_onboarding.html 'main.dart.js'
require_not_contains web/public_onboarding.html 'flutter.js'
require_not_contains web/public_onboarding.html 'canvaskit'
require_not_contains web/public_onboarding.html '<link rel="manifest"'
require_not_contains web/public_onboarding.html 'manifest.json'
require_not_contains web/public_onboarding.html 'https://'
require_not_contains web/public_onboarding.html 'http://'
require_not_contains web/public_checkout.html 'flutter_bootstrap.js'
require_not_contains web/public_checkout.html 'main.dart.js'
require_not_contains web/public_checkout.html 'flutter.js'
require_not_contains web/public_checkout.html 'canvaskit'
require_not_contains web/public_checkout.html '<link rel="manifest"'
require_not_contains web/public_checkout.html 'manifest.json'
require_not_contains web/public_checkout.html 'https://'
require_not_contains web/public_checkout.html 'http://'
require_not_contains web/public_catalog.html 'flutter_bootstrap.js'
require_not_contains web/public_catalog.html 'main.dart.js'
require_not_contains web/public_catalog.html 'flutter.js'
require_not_contains web/public_catalog.html 'canvaskit'
require_not_contains web/public_catalog.html '<link rel="manifest"'
require_not_contains web/public_catalog.html 'manifest.json'
require_not_contains web/public_catalog.html 'https://'
require_not_contains web/public_catalog.html 'http://'
require_not_contains web/public_collaborator_invite.html 'flutter_bootstrap.js'
require_not_contains web/public_collaborator_invite.html 'main.dart.js'
require_not_contains web/public_collaborator_invite.html 'flutter.js'
require_not_contains web/public_collaborator_invite.html 'canvaskit'
require_not_contains web/public_collaborator_invite.html '<link rel="manifest"'
require_not_contains web/public_collaborator_invite.html 'manifest.json'
require_not_contains web/public_collaborator_invite.html 'https://'
require_not_contains web/public_collaborator_invite.html 'http://'
require_contains web/site-assets/js/login-core.mjs "credentials: 'include'"
require_contains web/site-assets/js/login-core.mjs "cache: 'no-store'"
require_contains web/site-assets/js/login-core.mjs '/auth/web/login'
require_contains web/site-assets/js/register-core.mjs "credentials: 'include'"
require_contains web/site-assets/js/register-core.mjs "cache: 'no-store'"
require_contains web/site-assets/js/register-core.mjs '/public/api/login/nova-empresa'
require_contains web/site-assets/js/forgot-password-core.mjs "credentials: 'include'"
require_contains web/site-assets/js/forgot-password-core.mjs "cache: 'no-store'"
require_contains web/site-assets/js/forgot-password-core.mjs '/public/api/esqueceu-senha/enviar-codigo'
require_contains web/site-assets/js/forgot-password-core.mjs '/public/api/esqueceu-senha/validar-codigo'
require_contains web/site-assets/js/forgot-password-core.mjs '/public/api/esqueceu-senha/redefinir-senha'
require_contains web/site-assets/js/collaborator-invite-core.mjs '/public/api/colaborador/convites/'
require_contains web/site-assets/js/collaborator-invite-core.mjs "credentials: 'omit'"
require_contains web/site-assets/js/collaborator-invite-core.mjs "cache: 'no-store'"
require_not_contains web/site-assets/js/collaborator-invite-core.mjs 'localStorage.setItem'
require_not_contains web/site-assets/js/collaborator-invite-core.mjs 'sessionStorage'
require_not_contains web/site-assets/js/collaborator-invite-core.mjs 'document.cookie'
require_not_contains web/site-assets/js/collaborator-invite.js 'innerHTML'
require_not_contains web/site-assets/js/collaborator-invite.js 'accessToken'
require_not_contains web/site-assets/js/collaborator-invite.js 'refreshToken'
require_not_contains web/site-assets/js/login-core.mjs 'localStorage.setItem'
require_not_contains web/site-assets/js/login-core.mjs 'sessionStorage'
require_not_contains web/site-assets/js/login.js 'localStorage.setItem'
require_not_contains web/site-assets/js/login.js 'sessionStorage'
require_not_contains web/site-assets/js/login.js 'innerHTML'
require_not_contains build/web/site-assets/js/login.js 'innerHTML'
require_not_contains web/site-assets/js/register-core.mjs 'localStorage.setItem'
require_not_contains web/site-assets/js/register-core.mjs 'sessionStorage'
require_not_contains web/site-assets/js/register-core.mjs 'document.cookie'
require_not_contains web/site-assets/js/register.js 'localStorage.setItem'
require_not_contains web/site-assets/js/register.js 'sessionStorage'
require_not_contains web/site-assets/js/register.js 'document.cookie'
require_not_contains web/site-assets/js/register.js 'innerHTML'
require_not_contains build/web/site-assets/js/register.js 'innerHTML'
require_not_contains web/site-assets/js/forgot-password-core.mjs 'localStorage.setItem'
require_not_contains web/site-assets/js/forgot-password-core.mjs 'sessionStorage'
require_not_contains web/site-assets/js/forgot-password-core.mjs 'document.cookie'
require_not_contains web/site-assets/js/forgot-password.js 'localStorage.setItem'
require_not_contains web/site-assets/js/forgot-password.js 'sessionStorage'
require_not_contains web/site-assets/js/forgot-password.js 'document.cookie'
require_not_contains web/site-assets/js/forgot-password.js 'innerHTML'
require_not_contains build/web/site-assets/js/forgot-password.js 'innerHTML'
require_contains web/site-assets/js/checkout-core.mjs '/public/api/planos'
require_contains web/site-assets/js/checkout-core.mjs "cache: 'no-store'"
require_contains web/site-assets/js/checkout-core.mjs 'hasUnsafeCheckoutPriceParam'
require_not_contains web/site-assets/js/checkout-core.mjs '/public/api/i18n/'
require_not_contains web/site-assets/js/checkout-core.mjs "get('price')"
require_not_contains web/site-assets/js/checkout-core.mjs "credentials: 'include'"
require_not_contains web/site-assets/js/checkout-core.mjs 'localStorage.setItem'
require_not_contains web/site-assets/js/checkout-core.mjs 'sessionStorage'
require_not_contains web/site-assets/js/checkout-core.mjs 'document.cookie'
require_not_contains web/site-assets/js/checkout-core.mjs 'innerHTML'
require_not_contains web/site-assets/js/checkout-core.mjs 'accessToken'
require_not_contains web/site-assets/js/checkout-core.mjs 'refreshToken'
require_not_contains web/site-assets/js/checkout-core.mjs 'client_secret'
require_not_contains web/site-assets/js/checkout-core.mjs 'cardNumber'
require_not_contains web/site-assets/js/checkout-core.mjs 'cvv'
require_not_contains web/site-assets/js/checkout.js 'localStorage.setItem'
require_not_contains web/site-assets/js/checkout.js 'sessionStorage'
require_not_contains web/site-assets/js/checkout.js 'document.cookie'
require_not_contains web/site-assets/js/checkout.js 'innerHTML'
require_not_contains web/site-assets/js/checkout.js 'accessToken'
require_not_contains web/site-assets/js/checkout.js 'refreshToken'
require_not_contains web/site-assets/js/checkout.js 'client_secret'
require_not_contains web/site-assets/js/checkout.js 'cardNumber'
require_not_contains web/site-assets/js/checkout.js 'cvv'
require_not_contains build/web/site-assets/js/checkout-core.mjs "credentials: 'include'"
require_contains build/web/site-assets/js/checkout-core.mjs '/public/api/planos'
require_not_contains build/web/site-assets/js/checkout-core.mjs '/public/api/i18n/'
require_not_contains build/web/site-assets/js/checkout-core.mjs 'localStorage.setItem'
require_not_contains build/web/site-assets/js/checkout-core.mjs 'sessionStorage'
require_not_contains build/web/site-assets/js/checkout-core.mjs 'document.cookie'
require_not_contains build/web/site-assets/js/checkout-core.mjs 'innerHTML'
require_not_contains build/web/site-assets/js/checkout.js 'localStorage.setItem'
require_not_contains build/web/site-assets/js/checkout.js 'sessionStorage'
require_not_contains build/web/site-assets/js/checkout.js 'document.cookie'
require_not_contains build/web/site-assets/js/checkout.js 'innerHTML'
require_contains web/site-assets/js/catalog-core.mjs '/public/api/catalogos/'
require_contains web/site-assets/js/catalog-core.mjs "cache: 'no-store'"
require_not_contains web/site-assets/js/catalog-core.mjs "credentials: 'include'"
require_not_contains web/site-assets/js/catalog-core.mjs 'localStorage.setItem'
require_not_contains web/site-assets/js/catalog-core.mjs 'sessionStorage'
require_not_contains web/site-assets/js/catalog-core.mjs 'document.cookie'
require_not_contains web/site-assets/js/catalog-core.mjs 'innerHTML'
require_not_contains web/site-assets/js/catalog-core.mjs 'accessToken'
require_not_contains web/site-assets/js/catalog-core.mjs 'refreshToken'
require_not_contains web/site-assets/js/catalog.js 'localStorage.setItem'
require_not_contains web/site-assets/js/catalog.js 'sessionStorage'
require_not_contains web/site-assets/js/catalog.js 'document.cookie'
require_not_contains web/site-assets/js/catalog.js 'innerHTML'
require_contains build/web/site-assets/js/catalog-core.mjs '/public/api/catalogos/'
require_not_contains build/web/site-assets/js/catalog-core.mjs "credentials: 'include'"
require_not_contains build/web/site-assets/js/catalog-core.mjs 'localStorage.setItem'
require_not_contains build/web/site-assets/js/catalog-core.mjs 'sessionStorage'
require_not_contains build/web/site-assets/js/catalog-core.mjs 'document.cookie'
require_not_contains build/web/site-assets/js/catalog.js 'localStorage.setItem'
require_not_contains build/web/site-assets/js/catalog.js 'sessionStorage'
require_not_contains build/web/site-assets/js/catalog.js 'document.cookie'
require_not_contains build/web/site-assets/js/catalog.js 'innerHTML'
require_contains web/site-assets/js/onboarding-core.mjs 'web_trial_onboarding_profile'
require_contains web/site-assets/js/onboarding-core.mjs '/login?source=trial'
require_not_contains web/site-assets/js/onboarding-core.mjs 'fetch('
require_not_contains web/site-assets/js/onboarding-core.mjs 'XMLHttpRequest'
require_not_contains web/site-assets/js/onboarding-core.mjs 'sessionStorage'
require_not_contains web/site-assets/js/onboarding-core.mjs 'document.cookie'
require_not_contains web/site-assets/js/onboarding-core.mjs 'innerHTML'
require_not_contains web/site-assets/js/onboarding-core.mjs 'accessToken'
require_not_contains web/site-assets/js/onboarding-core.mjs 'refreshToken'
require_not_contains web/site-assets/js/onboarding-core.mjs 'permissoes'
require_not_contains web/site-assets/js/onboarding-core.mjs 'preferencias'
require_not_contains web/site-assets/js/onboarding.js 'fetch('
require_not_contains web/site-assets/js/onboarding.js 'XMLHttpRequest'
require_not_contains web/site-assets/js/onboarding.js 'sessionStorage'
require_not_contains web/site-assets/js/onboarding.js 'document.cookie'
require_not_contains web/site-assets/js/onboarding.js 'innerHTML'
require_not_contains web/site-assets/js/onboarding.js 'accessToken'
require_not_contains web/site-assets/js/onboarding.js 'refreshToken'
require_not_contains web/site-assets/js/onboarding.js 'permissoes'
require_not_contains web/site-assets/js/onboarding.js 'preferencias'
require_not_contains build/web/site-assets/js/onboarding-core.mjs 'fetch('
require_not_contains build/web/site-assets/js/onboarding-core.mjs 'XMLHttpRequest'
require_not_contains build/web/site-assets/js/onboarding-core.mjs 'sessionStorage'
require_not_contains build/web/site-assets/js/onboarding-core.mjs 'document.cookie'
require_not_contains build/web/site-assets/js/onboarding-core.mjs 'innerHTML'
require_not_contains build/web/site-assets/js/onboarding.js 'fetch('
require_not_contains build/web/site-assets/js/onboarding.js 'XMLHttpRequest'
require_not_contains build/web/site-assets/js/onboarding.js 'sessionStorage'
require_not_contains build/web/site-assets/js/onboarding.js 'document.cookie'
require_not_contains build/web/site-assets/js/onboarding.js 'innerHTML'
require_contains web/index.html 'isSixAppFlutterServiceWorker'
require_contains web/site-assets/js/home.js 'isSixAppFlutterServiceWorker'
require_contains web/site-assets/js/public-locale.mjs 'isSixAppFlutterServiceWorker'
require_contains web/site-assets/js/home.js 'sixapp.public.locale'
require_contains web/site-assets/js/public-locale.mjs 'sixapp.public.locale'
require_contains web/flutter_service_worker.js 'isSixAppFlutterCacheName'
require_contains web/flutter_service_worker.js 'cacheLooksLikeSixAppFlutter'

for path in web/index.html web/public_home.html web/public_login.html web/public_register.html web/public_forgot_password.html web/public_onboarding.html web/public_checkout.html web/public_catalog.html web/public_collaborator_invite.html web/site-assets/js/home.js build/web/index.html build/web/login.html build/web/register.html build/web/forgot-password.html build/web/onboarding.html build/web/checkout.html build/web/catalogo.html build/web/collaborator-invite.html build/web/site-assets/js/home.js build/web/flutter.html; do
  require_not_contains "$path" 'registrations.forEach(function (registration)'
done

for path in web/flutter_service_worker.js build/web/flutter_service_worker.js; do
  require_not_contains "$path" 'cacheNames.map(function (cacheName)'
  require_not_contains "$path" 'Promise.all(cacheNames.map'
done

if find build/web -maxdepth 1 \( -name '*.old' -o -name '*.bak' -o -name '*.tmp' \) | grep -q .; then
  fail "Arquivos temporarios/orfaos encontrados em build/web"
fi

if [[ -f build/web/public_home.html ]]; then
  fail "build/web/public_home.html nao deve permanecer como copia solta"
fi

if [[ -f build/web/public_login.html ]]; then
  fail "build/web/public_login.html nao deve permanecer como copia solta"
fi

if [[ -f build/web/public_register.html ]]; then
  fail "build/web/public_register.html nao deve permanecer como copia solta"
fi

if [[ -f build/web/public_forgot_password.html ]]; then
  fail "build/web/public_forgot_password.html nao deve permanecer como copia solta"
fi

if [[ -f build/web/public_onboarding.html ]]; then
  fail "build/web/public_onboarding.html nao deve permanecer como copia solta"
fi

if [[ -f build/web/public_checkout.html ]]; then
  fail "build/web/public_checkout.html nao deve permanecer como copia solta"
fi

if [[ -f build/web/public_catalog.html ]]; then
  fail "build/web/public_catalog.html nao deve permanecer como copia solta"
fi

if [[ -f build/web/public_collaborator_invite.html ]]; then
  fail "build/web/public_collaborator_invite.html nao deve permanecer como copia solta"
fi

if find build/web web -maxdepth 2 \( -name '*.old' -o -name '*.bak' -o -name '*.tmp' \) | grep -q .; then
  fail "Arquivos temporarios/orfaos encontrados"
fi

ok "Estrategia A verificada em build/web"
