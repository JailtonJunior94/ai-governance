#!/usr/bin/env bash
# Extrai file_path do JSON de hook input (stdin).
# Uso: file_path="$(echo "$input" | parse_file_path)"
# Tenta python3, depois jq, depois grep/sed como fallback.
#
# Fonte compartilhada entre validate-governance.sh e validate-preload.sh.

parse_file_path() {
  local input
  input="$(head -c 65536)"

  local file_path=""
  if command -v python3 >/dev/null 2>&1; then
    file_path="$(printf '%s' "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', data).get('file_path', ''))
except Exception:
    pass
" 2>/dev/null || true)"
  elif command -v jq >/dev/null 2>&1; then
    file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .file_path // empty' 2>/dev/null || true)"
  fi

  if [[ -z "$file_path" ]]; then
    file_path="$(printf '%s' "$input" | grep -o '"file_path":"[^"]*"' 2>/dev/null | head -1 | sed 's/"file_path":"//;s/"//' || true)"
  fi

  printf '%s' "$file_path"
}
