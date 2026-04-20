#!/usr/bin/env bash
# Valida o pacote de evidencias de um relatorio de bugfix.
# Uso: $0 [--rf <RF-ID>] <bugfix_report.md>
#
# Opcoes:
#   --rf <RF-ID>  Verifica se o RF/requisito informado e mencionado no relatorio (rastreabilidade).
#                 Pode ser repetido para multiplos IDs: --rf RF-01 --rf RF-02
#
# Exit 0 = aprovado, Exit 1 = reprovado, Exit 2 = uso incorreto.

set -euo pipefail

export LC_ALL=C

rf_ids=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rf)
      if [[ $# -lt 2 ]]; then
        echo "ERRO: --rf requer um argumento (ex: --rf RF-01)"
        exit 2
      fi
      rf_ids+=("$2")
      shift 2
      ;;
    -*)
      echo "Opcao desconhecida: $1"
      echo "Uso: $0 [--rf <RF-ID>]... <bugfix_report.md>"
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 [--rf <RF-ID>]... <bugfix_report.md>"
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
require_heading "bugs"                  "seção Bugs"
require_heading "comandos executados"   "seção Comandos Executados"
require_heading "riscos residuais"      "seção Riscos Residuais"

# Validacao semantica: secoes criticas devem ter conteudo real
require_content_after_heading "bugs" "seção Bugs"
require_content_after_heading "comandos executados" "seção Comandos Executados"

# Cada entrada de bug deve ter estado canonico
require_pattern "Estado[[:space:]]*:[[:space:]]*(fixed|blocked|skipped|failed)" \
  "estado canonico de bug (fixed|blocked|skipped|failed)"

# Causa raiz documentada
require_pattern "Causa[[:space:]]+raiz[[:space:]]*:" "campo Causa raiz"

# Teste de regressao documentado
require_pattern "Teste[[:space:]]+de[[:space:]]+regress" "referencia a teste de regressao"

# Evidencia de validacao
require_pattern "Validac" "campo Validacao"

# Totalizadores
require_pattern "Corrigidos[[:space:]]*:" "contagem de bugs corrigidos"

# Estado terminal canonico
if ! grep -Eiq "^[-*]?[[:space:]]*(Estado|estado|Estado final)[[:space:]]*:[[:space:]]*(done|blocked|failed|needs_input)" "$report_file"; then
  echo "FALTANDO: estado terminal canonico (done|blocked|failed|needs_input)"
  missing=1
fi

# Rastreabilidade RF: cada ID informado via --rf deve aparecer no relatorio
for rf_id in "${rf_ids[@]+"${rf_ids[@]}"}"; do
  if ! grep -Fiq "$rf_id" "$report_file"; then
    echo "FALTANDO: rastreabilidade RF '$rf_id' nao encontrada no relatorio"
    missing=1
  fi
done

if [[ $missing -ne 0 ]]; then
  echo ""
  echo "Validacao do pacote de evidencias de bugfix falhou: $report_file"
  exit 1
fi

echo "Validacao do pacote de evidencias de bugfix aprovada: $report_file"
