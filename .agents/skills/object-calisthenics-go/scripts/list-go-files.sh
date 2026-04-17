#!/usr/bin/env bash
set -euo pipefail

if ! command -v rg >/dev/null 2>&1; then
  echo "rg nao encontrado no PATH" >&2
  exit 1
fi

mapfile -t files < <(rg --files -g '*.go' -g '!vendor/**' -g '!**/testdata/**' -g '!**/node_modules/**')

if [ "${#files[@]}" -eq 0 ]; then
  echo "nenhum arquivo Go encontrado no workspace atual" >&2
  exit 1
fi

printf '%s\n' "${files[@]}"
