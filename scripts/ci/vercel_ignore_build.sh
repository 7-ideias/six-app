#!/usr/bin/env bash

set -euo pipefail

commit_message="${VERCEL_GIT_COMMIT_MESSAGE:-}"

if [[ -z "${commit_message}" ]]; then
  echo "VERCEL_GIT_COMMIT_MESSAGE ausente; seguindo com o build."
  exit 1
fi

if [[ "${commit_message}" == *"[skip web]"* ]]; then
  echo "Marcador [skip web] encontrado; ignorando deploy Web na Vercel."
  exit 0
fi

echo "Sem marcador [skip web]; seguindo com o build."
exit 1
