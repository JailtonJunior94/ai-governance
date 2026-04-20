#!/usr/bin/env bash
# Extrai o estado canonico de um relatorio de execucao de tarefa.
#
# Uso:
#   bash scripts/lib/report-parser.sh <execution-report.md>
#
# Saida (stdout):
#   done | blocked | failed | needs_input | unknown
#
# Retorno:
#   0 — estado extraido com sucesso
#   1 — arquivo nao encontrado ou estado nao parseavel
#   2 — uso incorreto

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <execution-report.md>" >&2
  exit 2
fi

report_file="$1"

if [[ ! -f "$report_file" ]]; then
  echo "unknown"
  exit 1
fi

# Extrair estado da linha "Estado: <valor>" ou "- Estado: <valor>"
state="$(grep -Eio 'estado[[:space:]]*:[[:space:]]*(done|blocked|failed|needs_input)' "$report_file" \
  | head -1 \
  | sed 's/.*:[[:space:]]*//' \
  | tr '[:upper:]' '[:lower:]')"

if [[ -z "$state" ]]; then
  echo "unknown"
  exit 1
fi

echo "$state"
exit 0
