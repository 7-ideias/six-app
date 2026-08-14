#!/usr/bin/env bash

resolve_node() {
  if [[ -n "${NODE_BIN:-}" ]]; then
    if [[ -x "$NODE_BIN" ]]; then
      "$NODE_BIN" --version >/dev/null 2>&1 && printf '%s\n' "$NODE_BIN" && return 0
    fi

    if command -v "$NODE_BIN" >/dev/null 2>&1; then
      local resolved_node
      resolved_node="$(command -v "$NODE_BIN")"
      "$resolved_node" --version >/dev/null 2>&1 && printf '%s\n' "$resolved_node" && return 0
    fi

    echo "[ERRO SIX] NODE_BIN informado nao aponta para um Node.js valido: $NODE_BIN" >&2
    return 1
  fi

  if command -v node >/dev/null 2>&1; then
    local path_node
    path_node="$(command -v node)"
    "$path_node" --version >/dev/null 2>&1 && printf '%s\n' "$path_node" && return 0
  fi

  local runtime_dir="${HOME}/.cache/JetBrains/acp-agents/.runtimes/node"
  local candidates=()
  local candidate

  shopt -s nullglob
  candidates=("$runtime_dir"/*/bin/node)
  shopt -u nullglob

  if ((${#candidates[@]} > 0)); then
    while IFS= read -r candidate; do
      if [[ -x "$candidate" ]] && "$candidate" --version >/dev/null 2>&1; then
        printf '%s\n' "$candidate"
        return 0
      fi
    done < <(printf '%s\n' "${candidates[@]}" | sort -Vr)
  fi

  echo "[ERRO SIX] Node.js nao encontrado. Instale Node no PATH ou disponibilize um runtime valido em ${runtime_dir}/*/bin/node." >&2
  return 1
}
