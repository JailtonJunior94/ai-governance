#!/usr/bin/env bash

set -euo pipefail

export LC_ALL=C

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <relatorio-execucao-tarefa.md>"
  exit 2
fi

report_file="$1"

if [[ ! -f "$report_file" ]]; then
  echo "ERRO: arquivo de relatório não encontrado: $report_file"
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
# (pelo menos 1 linha nao-vazia que nao seja apenas "Nenhum", "N/A", "n/a", "-" ou heading)
require_content_after_heading() {
  local heading_pattern="$1"
  local label="$2"

  local heading_line
  heading_line="$(grep -Ein "^#+[[:space:]]+$heading_pattern" "$report_file" | head -1 | cut -d: -f1)"
  if [[ -z "$heading_line" ]]; then
    return # heading ausente — ja capturado por require_heading
  fi

  local total_lines
  total_lines="$(wc -l < "$report_file" | tr -d ' ')"
  local next_start=$((heading_line + 1))
  if [[ "$next_start" -gt "$total_lines" ]]; then
    echo "FALTANDO: conteudo apos $label (secao vazia)"
    missing=1
    return
  fi

  # Extrair linhas ate o proximo heading ou fim do arquivo
  local has_content=0
  while IFS= read -r line; do
    # Parar no proximo heading
    if echo "$line" | grep -Eq '^#+[[:space:]]'; then
      break
    fi
    # Ignorar linhas vazias e placeholders
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

# Contexto carregado (PRD e TechSpec) — exigir como heading Markdown
require_heading "contexto carregado" "seção Contexto Carregado"
require_pattern "PRD[[:space:]]*:" "referência ao PRD consultado"
require_pattern "TechSpec[[:space:]]*:" "referência à TechSpec consultada"

# Seções obrigatórias — exigir como heading Markdown
require_heading "comandos executados" "seção Comandos Executados"
require_heading "arquivos alterados" "seção Arquivos Alterados"
require_heading "resultados de validac" "seção Resultados de Validação"
require_heading "suposic" "seção Suposições"
require_heading "riscos residuais" "seção Riscos Residuais"

# Validacao semantica: secoes criticas devem ter conteudo real
require_content_after_heading "comandos executados" "seção Comandos Executados"
require_content_after_heading "arquivos alterados" "seção Arquivos Alterados"
require_content_after_heading "resultados de validac" "seção Resultados de Validação"

# Exigir um estado terminal canônico
if ! grep -Eiq "estado[[:space:]]*:[[:space:]]*(blocked|failed|done)" "$report_file"; then
  echo "FALTANDO: estado terminal de execução (blocked|failed|done)"
  missing=1
fi

# Evidência de testes e lint
require_pattern "testes[[:space:]]*:[[:space:]]*(pass|fail|blocked)" "evidência de testes com resultado"
require_pattern "lint[[:space:]]*:[[:space:]]*(pass|fail|blocked)" "evidência de lint com resultado"

# Rastreabilidade PRD → teste: se o relatório referencia um PRD, verificar que pelo menos
# um ID de requisito (ex: RF-01, RF01, REQ-1, REQ1) aparece no corpo do relatório.
if grep -Eiq "PRD[[:space:]]*:" "$report_file"; then
  if ! grep -Eiq "(RF-?[0-9]+|REQ-?[0-9]+)" "$report_file"; then
    echo "FALTANDO: nenhum ID de requisito (RF-nn ou REQ-nn) referenciado no relatório"
    missing=1
  fi
fi

# Rastreabilidade cruzada: verificar que cada RF-nn/REQ-nn citado no relatório existe no PRD referenciado.
prd_path="$(grep -Eio 'PRD[[:space:]]*:[[:space:]]*(.+)' "$report_file" | head -1 | sed 's/^PRD[[:space:]]*:[[:space:]]*//' | tr -d '[:space:]')"
if [[ -n "$prd_path" && -f "$prd_path" ]]; then
  # Extrair IDs do relatório e verificar cada um no PRD
  report_ids="$(grep -Eio '(RF-?[0-9]+|REQ-?[0-9]+)' "$report_file" | sort -u)"
  for req_id in $report_ids; do
    if ! grep -Fiq "$req_id" "$prd_path" 2>/dev/null; then
      echo "FALTANDO: requisito $req_id citado no relatório não encontrado no PRD ($prd_path)"
      missing=1
    fi
  done
elif [[ -n "$prd_path" ]]; then
  # PRD referenciado mas arquivo não encontrado — tentar caminho relativo ao relatório
  report_dir="$(dirname "$report_file")"
  if [[ -f "$report_dir/$prd_path" ]]; then
    report_ids="$(grep -Eio '(RF-?[0-9]+|REQ-?[0-9]+)' "$report_file" | sort -u)"
    for req_id in $report_ids; do
      if ! grep -Fiq "$req_id" "$report_dir/$prd_path" 2>/dev/null; then
        echo "FALTANDO: requisito $req_id citado no relatório não encontrado no PRD ($report_dir/$prd_path)"
        missing=1
      fi
    done
  fi
fi

# Veredito do revisor
if ! grep -Eiq "veredito do revisor[[:space:]]*:[[:space:]]*(APPROVED|APPROVED_WITH_REMARKS|REJECTED|BLOCKED)" "$report_file"; then
  echo "FALTANDO: veredito do revisor com valor canônico"
  missing=1
fi

if [[ $missing -ne 0 ]]; then
  echo ""
  echo "Validação do pacote de evidências falhou: $report_file"
  exit 1
fi

echo "Validação do pacote de evidências aprovada: $report_file"
