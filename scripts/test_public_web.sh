#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/resolve_node.sh"
NODE_BIN="$(resolve_node)"

"$NODE_BIN" --test \
  scripts/tests/admin_login_regression_test.mjs \
  scripts/tests/build_web_api_base_url_test.mjs \
  scripts/tests/public_login_core_test.mjs \
  scripts/tests/public_register_core_test.mjs \
  scripts/tests/public_forgot_password_core_test.mjs \
  scripts/tests/public_onboarding_core_test.mjs \
  scripts/tests/public_checkout_core_test.mjs \
  scripts/tests/public_catalog_core_test.mjs \
  scripts/tests/catalogo_reservas_web_test.mjs \
  scripts/tests/public_home_plans_test.mjs
