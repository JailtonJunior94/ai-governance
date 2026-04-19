#!/usr/bin/env bash
# Valida o pacote de evidencias de um relatorio de refatoracao.
# Uso: $0 <refactor_report.md>
#
# Exit 0 = aprovado, Exit 1 = reprovado, Exit 2 = uso incorreto.

set -euo pipefail

export LC_ALL=C

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <refactor_report.md>"
  exit 2
fi

report_file="$1"

if [[ ! -f "$report_file" ]]; then
  echo "ERRO: arquivo de relatorio nao encontrado: $report_file"
  exit 2
fi

missing=0

require_pattern() {
  local pattern="$1"
  local label="$2"

  if ! grep -Eiq "$pattern" "$report_file"; then
    echo "FALTANDO: $label"
    missing=1
  fi
}

require_heading() {
  local pattern="$1"
  local label="$2"

  if ! grep -Eiq "^#+[[:space:]]+$pattern" "$report_file"; then
    echo "FALTANDO: $label"
    missing=1
  fi
}

# Secoes obrigatorias
require_heading "escopo"                      "seção Escopo"
require_heading "invariantes"                 "seção Invariantes Preservadas"
require_heading "mudanc"                      "seção Mudanças"
require_heading "comandos executados"         "seção Comandos Executados"
require_heading "resultados de validac"       "seção Resultados de Validação"
require_heading "riscos residuais"            "seção Riscos Residuais"

# Modo documentado
require_pattern "Modo[[:space:]]*:[[:space:]]*(advisory|execution)" \
  "campo Modo (advisory|execution)"

# Estado terminal canonico
if ! grep -Eiq "Estado[[:space:]]*:[[:space:]]*(needs_input|blocked|failed|done)" "$report_file"; then
  echo "FALTANDO: estado terminal canonico (needs_input|blocked|failed|done)"
  missing=1
fi

# Evidencia de testes e lint
require_pattern "Testes[[:space:]]*:[[:space:]]*(pass|fail|blocked|n/a)" \
  "evidencia de testes com resultado"
require_pattern "Lint[[:space:]]*:[[:space:]]*(pass|fail|blocked|n/a)" \
  "evidencia de lint com resultado"

# Veredito do revisor (obrigatorio em modo execution)
if grep -Eiq "Modo[[:space:]]*:[[:space:]]*execution" "$report_file"; then
  if ! grep -Eiq "Veredito do Revisor[[:space:]]*:[[:space:]]*(APPROVED|APPROVED_WITH_REMARKS|REJECTED|BLOCKED|n/a)" "$report_file"; then
    echo "FALTANDO: veredito do revisor (obrigatorio em modo execution)"
    missing=1
  fi
fi

if [[ $missing -ne 0 ]]; then
  echo ""
  echo "Validacao do pacote de evidencias de refatoracao falhou: $report_file"
  exit 1
fi

echo "Validacao do pacote de evidencias de refatoracao aprovada: $report_file"
