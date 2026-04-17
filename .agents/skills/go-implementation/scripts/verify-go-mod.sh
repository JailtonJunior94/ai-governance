#!/usr/bin/env bash
set -euo pipefail

if [[ -f "go.mod" ]]; then
  echo "OK: go.mod encontrado"
  exit 0
fi

echo "ERRO: go.mod ausente no diretório atual. Verifique se a tarefa realmente envolve um contexto Go." >&2
exit 1
