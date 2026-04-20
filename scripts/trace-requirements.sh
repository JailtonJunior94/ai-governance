#!/usr/bin/env bash
# Gera matriz de rastreabilidade RF → tasks → testes → codigo → evidencia.
#
# Uso:
#   bash scripts/trace-requirements.sh <diretorio-da-feature>
#
# Exemplo:
#   bash scripts/trace-requirements.sh tasks/prd-semver-automation-release
#
# Retorna:
#   0 — rastreabilidade completa
#   1 — lacunas encontradas
#   2 — uso incorreto

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 <diretorio-da-feature> [--project-root <path>]" >&2
  exit 2
fi

FEATURE_DIR="$1"
shift

PROJECT_ROOT="."
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root) PROJECT_ROOT="$2"; shift 2 ;;
    *) echo "ERRO: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

if [[ ! -d "$FEATURE_DIR" ]]; then
  echo "ERRO: diretorio nao encontrado: $FEATURE_DIR" >&2
  exit 2
fi

PRD_FILE="$FEATURE_DIR/prd.md"
TASKS_FILE="$FEATURE_DIR/tasks.md"

if [[ ! -f "$PRD_FILE" ]]; then
  echo "ERRO: prd.md nao encontrado em $FEATURE_DIR" >&2
  exit 2
fi

# Extrair todos os RF/REQ/RNF do PRD
all_ids="$(grep -Eohi '(RF-?[0-9]+|REQ-?[0-9]+|RNF-?[0-9]+)' "$PRD_FILE" 2>/dev/null \
  | tr '[:lower:]' '[:upper:]' | sort -u || true)"

if [[ -z "$all_ids" ]]; then
  echo "OK: nenhum requisito RF/REQ/RNF encontrado em $PRD_FILE"
  exit 0
fi

total=0
full_trace=0
partial_trace=0
no_trace=0

echo ""
echo "# Matriz de Rastreabilidade"
echo ""
echo "Feature: $FEATURE_DIR"
echo "PRD: $PRD_FILE"
echo ""
echo "| RF-ID | PRD | Tasks | Testes | Codigo | Evidencia | Status |"
echo "|-------|-----|-------|--------|--------|-----------|--------|"

while IFS= read -r req_id; do
  [[ -n "$req_id" ]] || continue
  total=$((total + 1))

  # PRD — sempre presente (fonte de extracao)
  in_prd="sim"

  # Tasks
  in_tasks="nao"
  if [[ -f "$TASKS_FILE" ]] && grep -Fiq "$req_id" "$TASKS_FILE" 2>/dev/null; then
    in_tasks="sim"
  fi

  # Testes — buscar em arquivos *_test.go, *.test.ts, test_*.py, *_test.py
  in_tests="nao"
  test_files="$(find "$PROJECT_ROOT" \
    \( -name '*_test.go' -o -name '*.test.ts' -o -name '*.test.js' \
       -o -name 'test_*.py' -o -name '*_test.py' \) \
    -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null || true)"
  if [[ -n "$test_files" ]]; then
    while IFS= read -r tf; do
      [[ -n "$tf" ]] || continue
      if grep -Fiq "$req_id" "$tf" 2>/dev/null; then
        in_tests="sim"
        break
      fi
    done <<< "$test_files"
  fi

  # Codigo fonte — buscar em .go, .ts, .js, .py (excluindo testes)
  in_code="nao"
  src_files="$(find "$PROJECT_ROOT" \
    \( -name '*.go' -o -name '*.ts' -o -name '*.js' -o -name '*.py' \) \
    -not -name '*_test.go' -not -name '*.test.ts' -not -name '*.test.js' \
    -not -name 'test_*.py' -not -name '*_test.py' \
    -not -path '*/node_modules/*' -not -path '*/.git/*' \
    -not -path '*/tests/*' 2>/dev/null || true)"
  if [[ -n "$src_files" ]]; then
    while IFS= read -r sf; do
      [[ -n "$sf" ]] || continue
      if grep -Fiq "$req_id" "$sf" 2>/dev/null; then
        in_code="sim"
        break
      fi
    done <<< "$src_files"
  fi

  # Evidencia — buscar em execution reports e bugfix reports
  in_evidence="nao"
  report_files="$(find "$FEATURE_DIR" \
    \( -name '*_execution_report.md' -o -name 'bugfix_report.md' \) 2>/dev/null || true)"
  if [[ -n "$report_files" ]]; then
    while IFS= read -r rf; do
      [[ -n "$rf" ]] || continue
      if grep -Fiq "$req_id" "$rf" 2>/dev/null; then
        in_evidence="sim"
        break
      fi
    done <<< "$report_files"
  fi

  # Calcular status
  count=0
  [[ "$in_tasks" == "sim" ]] && count=$((count + 1))
  [[ "$in_tests" == "sim" ]] && count=$((count + 1))
  [[ "$in_code" == "sim" ]] && count=$((count + 1))
  [[ "$in_evidence" == "sim" ]] && count=$((count + 1))

  if [[ "$count" -eq 4 ]]; then
    status="completo"
    full_trace=$((full_trace + 1))
  elif [[ "$count" -gt 0 ]]; then
    status="parcial ($count/4)"
    partial_trace=$((partial_trace + 1))
  else
    status="ausente"
    no_trace=$((no_trace + 1))
  fi

  echo "| $req_id | $in_prd | $in_tasks | $in_tests | $in_code | $in_evidence | $status |"

done <<< "$all_ids"

echo ""
echo "## Resumo"
echo ""
echo "- Total de requisitos: $total"
echo "- Rastreabilidade completa: $full_trace"
echo "- Rastreabilidade parcial: $partial_trace"
echo "- Sem rastreabilidade: $no_trace"
echo ""

if [[ "$total" -gt 0 ]]; then
  coverage=$((full_trace * 100 / total))
  echo "- Cobertura completa: ${coverage}%"
fi

echo ""

if [[ "$no_trace" -gt 0 ]]; then
  echo "ATENCAO: $no_trace requisito(s) sem rastreabilidade."
  exit 1
fi

if [[ "$partial_trace" -gt 0 ]]; then
  echo "ATENCAO: $partial_trace requisito(s) com rastreabilidade parcial."
  exit 1
fi

echo "OK: rastreabilidade completa para todos os $total requisito(s)."
exit 0
