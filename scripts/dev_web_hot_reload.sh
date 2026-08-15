#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

API_URL="${API_BASE_URL:-${SIXAPP_PUBLIC_API_BASE_URL:-http://localhost:8082}}"
PORT="${SIXAPP_WEB_PORT:-39441}"
DEVICE="${SIXAPP_WEB_DEVICE:-chrome}"
LAUNCH_PATH="${SIXAPP_WEB_LAUNCH_PATH:-/login/flutter}"
DISABLE_BROWSER_HANDOFF="${SIXAPP_DISABLE_WEB_BROWSER_HANDOFF:-true}"
WEB_LOGS="${SIXAPP_WEB_LOGS:-normal}"
FLUTTER_LOGS="${SIXAPP_FLUTTER_LOGS:-terminal}"
FLUTTER_LOG_FILE="${SIXAPP_FLUTTER_LOG_FILE:-$ROOT_DIR/.dart_tool/sixapp_web_hot_reload.log}"
FORWARD_ARGS=()

is_quiet_logs() {
  case "${WEB_LOGS,,}" in
    0|false|off|quiet|silent)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

log() {
  if is_quiet_logs; then
    return
  fi
  echo "[LOG SIX] $*"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --six-quiet)
      WEB_LOGS="quiet"
      shift
      ;;
    --port)
      if [[ $# -lt 2 ]]; then
        echo "[ERRO SIX] --port exige um valor." >&2
        exit 1
      fi
      PORT="$2"
      shift 2
      ;;
    --port=*)
      PORT="${1#--port=}"
      shift
      ;;
    --host)
      if [[ $# -lt 2 ]]; then
        echo "[ERRO SIX] --host exige um valor." >&2
        exit 1
      fi
      log "Ignorando --host=$2 no modo Flutter debug."
      shift 2
      ;;
    --host=*)
      log "Ignorando ${1} no modo Flutter debug."
      shift
      ;;
    *)
      FORWARD_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ "$LAUNCH_PATH" =~ ^https?:// ]]; then
  LAUNCH_URL="$LAUNCH_PATH"
elif [[ "$LAUNCH_PATH" == /* ]]; then
  LAUNCH_URL="http://localhost:${PORT}${LAUNCH_PATH}"
else
  LAUNCH_URL="http://localhost:${PORT}/${LAUNCH_PATH}"
fi

FLUTTER_RUN_ARGS=(
  -d "$DEVICE"
  --web-port="$PORT"
  --web-launch-url="$LAUNCH_URL"
  --dart-define="API_BASE_URL=$API_URL"
  --dart-define="SIXAPP_DISABLE_WEB_BROWSER_HANDOFF=$DISABLE_BROWSER_HANDOFF"
  "${FORWARD_ARGS[@]}"
)

log "Flutter Web debug com hot reload"
log "Device: $DEVICE"
log "URL: $LAUNCH_URL"
log "API_BASE_URL: $API_URL"
log "Disable browser handoff: $DISABLE_BROWSER_HANDOFF"
log "Flutter logs: $FLUTTER_LOGS"
log "Use r para hot reload, R para hot restart, q para sair."

case "${FLUTTER_LOGS,,}" in
  terminal|on|true|1)
    exec flutter run "${FLUTTER_RUN_ARGS[@]}"
    ;;
  file)
    mkdir -p "$(dirname "$FLUTTER_LOG_FILE")"
    log "Gravando logs do Flutter em: $FLUTTER_LOG_FILE"
    exec flutter run "${FLUTTER_RUN_ARGS[@]}" >"$FLUTTER_LOG_FILE" 2>&1
    ;;
  quiet|silent|off|false|0)
    exec flutter run "${FLUTTER_RUN_ARGS[@]}" >/dev/null 2>&1
    ;;
  *)
    echo "[ERRO SIX] SIXAPP_FLUTTER_LOGS invalido: $FLUTTER_LOGS" >&2
    echo "[ERRO SIX] Use terminal, file ou quiet." >&2
    exit 1
    ;;
esac
