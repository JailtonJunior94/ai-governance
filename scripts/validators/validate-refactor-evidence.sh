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

# Validacao semantica: verifica que apos um heading existe conteudo real
require_content_after_heading() {
  local heading_pattern="$1"
  local label="$2"

  local heading_line
  heading_line="$(grep -Ein "^#+[[:space:]]+$heading_pattern" "$report_file" | head -1 | cut -d: -f1)"
  if [[ -z "$heading_line" ]]; then
    return
  fi

  local total_lines
  total_lines="$(wc -l < "$report_file" | tr -d ' ')"
  local next_start=$((heading_line + 1))
  if [[ "$next_start" -gt "$total_lines" ]]; then
    echo "FALTANDO: conteudo apos $label (secao vazia)"
    missing=1
    return
  fi

  local has_content=0
  while IFS= read -r line; do
    if echo "$line" | grep -Eq '^#+[[:space:]]'; then
      break
    fi
    local trimmed
    trimmed="$(echo "$line" | sed 's/^[[:space:]-]*//' | sed 's/[[:space:]]*$//')"
    if [[ -n "$trimmed" ]] && ! echo "$trimmed" | grep -Eiq '^(nenhum[a.]?|n/?a|-)$'; then
      has_content=1
      break
    fi
  done < <(tail -n +"$next_start" "$report_file")

  if [[ "$has_content" -eq 0 ]]; then
    echo "FALTANDO: conteudo real apos $label (secao vazia ou apenas placeholders)"
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

# Validacao semantica: secoes criticas devem ter conteudo real
require_content_after_heading "mudanc" "seção Mudanças"
require_content_after_heading "comandos executados" "seção Comandos Executados"
require_content_after_heading "invariantes" "seção Invariantes Preservadas"

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
