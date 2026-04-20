#!/usr/bin/env bash
# Verifica cobertura de requisitos: todos os RF-nn/REQ-nn/RNF-nn do PRD devem aparecer em tasks.md.
# Inclui requisitos funcionais (RF/REQ) e nao-funcionais (RNF).
#
# Uso:
#   bash scripts/check-rf-coverage.sh <prd.md> <tasks.md>
#
# Retorna:
#   0  — todos os requisitos cobertos
#   1  — algum requisito ausente (drift de cobertura)
#   2  — uso incorreto ou arquivo nao encontrado
#
# Exemplo:
#   bash scripts/check-rf-coverage.sh tasks/prd-feature/prd.md tasks/prd-feature/tasks.md

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Uso: $0 <prd.md> <tasks.md>" >&2
  exit 2
fi

prd_file="$1"
tasks_file="$2"

for f in "$prd_file" "$tasks_file"; do
  if [[ ! -f "$f" ]]; then
    echo "ERRO: arquivo nao encontrado: $f" >&2
    exit 2
  fi
done

# Extrair todos os RF-nn / REQ-nn / RNF-nn do PRD (case-insensitive, uppercase normalizado)
all_ids="$(grep -Eohi '(RF-?[0-9]+|REQ-?[0-9]+|RNF-?[0-9]+)' "$prd_file" 2>/dev/null \
  | tr '[:lower:]' '[:upper:]' | sort -u || true)"

if [[ -z "$all_ids" ]]; then
  echo "OK: nenhum requisito RF-nn/REQ-nn/RNF-nn encontrado em $prd_file (sem cobertura a verificar)"
  exit 0
fi

# Classificar requisitos por tipo para relatorio detalhado
rf_total=0
rnf_total=0
rf_missing=0
rnf_missing=0

total=0
missing=0
missing_ids=()

while IFS= read -r req_id; do
  [[ -n "$req_id" ]] || continue
  total=$((total + 1))

  # Classificar tipo
  if echo "$req_id" | grep -Eq '^RNF'; then
    rnf_total=$((rnf_total + 1))
  else
    rf_total=$((rf_total + 1))
  fi

  if ! grep -Fiq "$req_id" "$tasks_file" 2>/dev/null; then
    missing=$((missing + 1))
    missing_ids+=("$req_id")
    if echo "$req_id" | grep -Eq '^RNF'; then
      rnf_missing=$((rnf_missing + 1))
    else
      rf_missing=$((rf_missing + 1))
    fi
  fi
done <<< "$all_ids"

if [[ "$missing" -gt 0 ]]; then
  echo "COBERTURA INCOMPLETA: $missing de $total requisito(s) ausente(s) em $tasks_file" >&2
  if [[ "$rf_missing" -gt 0 ]]; then
    echo "  Funcionais (RF/REQ) ausentes: $rf_missing de $rf_total" >&2
  fi
  if [[ "$rnf_missing" -gt 0 ]]; then
    echo "  Nao-funcionais (RNF) ausentes: $rnf_missing de $rnf_total" >&2
  fi
  for id in "${missing_ids[@]}"; do
    echo "  - $id" >&2
  done
  echo "" >&2
  echo "Recomendacao: adicionar tarefas ou subtarefas que referenciem os requisitos ausentes," >&2
  echo "  ou marcar como fora-de-escopo com justificativa em tasks.md." >&2
  exit 1
fi

echo "OK: todos os $total requisito(s) de $prd_file cobertos em $tasks_file (RF: $rf_total, RNF: $rnf_total)"
exit 0
