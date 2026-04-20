#!/usr/bin/env bash
# Gera relatorio consolidado de execucao do loop de tasks.
#
# Uso:
#   bash scripts/lib/loop-report-generator.sh <feature_slug> <final_state> <stop_task> <completed_ids> <log_dir> <start_time> <tasks_md>
#
# Saida:
#   Grava o relatorio em tasks/prd-<slug>/consolidated-execution-<timestamp>.md
#   Imprime o caminho do relatorio em stdout.

set -euo pipefail

if [[ $# -lt 7 ]]; then
  echo "Uso: $0 <feature_slug> <final_state> <stop_task> <completed_ids> <log_dir> <start_time> <tasks_md>" >&2
  exit 2
fi

feature_slug="$1"
final_state="$2"
stop_task="$3"
completed_ids="$4"
log_dir="$5"
start_time="$6"
tasks_md="$7"

tasks_dir="$(dirname "$tasks_md")"
end_time="$(date '+%Y-%m-%d %H:%M:%S')"
timestamp="$(date '+%Y%m%d-%H%M%S')"
report_file="$tasks_dir/consolidated-execution-${timestamp}.md"

# Detectar ferramenta a partir dos logs
tool="unknown"
if ls "$log_dir"/claude-* >/dev/null 2>&1; then
  tool="claude"
elif ls "$log_dir"/codex-* >/dev/null 2>&1; then
  tool="codex"
elif ls "$log_dir"/gemini-* >/dev/null 2>&1; then
  tool="gemini"
fi

{
  echo "# Relatorio Consolidado de Execucao"
  echo ""
  echo "## Metadados"
  echo "- Feature: prd-${feature_slug}"
  echo "- Ferramenta: ${tool}"
  echo "- Inicio: ${start_time}"
  echo "- Fim: ${end_time}"
  echo "- Estado Final: ${final_state}"
  echo ""

  # Tasks concluidas
  echo "## Tasks Concluidas"
  echo ""
  if [[ -z "$completed_ids" ]]; then
    echo "Nenhuma task concluida neste loop."
  else
    echo "| # | Titulo | Relatorio |"
    echo "|---|--------|-----------|"
    for tid in $completed_ids; do
      # Extrair titulo do tasks.md
      title="$(grep -E "^\|[[:space:]]*${tid}[[:space:]]*\|" "$tasks_md" \
        | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3}' \
        || echo "(titulo nao encontrado)")"
      report_name="${tid}_execution_report.md"
      echo "| ${tid} | ${title} | ${report_name} |"
    done
  fi
  echo ""

  # Task de parada
  echo "## Task de Parada"
  echo ""
  if [[ -z "$stop_task" ]]; then
    echo "Nenhuma — todas as tasks elegiveis foram concluidas."
  else
    stop_title="$(grep -E "^\|[[:space:]]*${stop_task}[[:space:]]*\|" "$tasks_md" \
      | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3}' \
      || echo "(titulo nao encontrado)")"
    echo "- ID: ${stop_task}"
    echo "- Titulo: ${stop_title}"
    echo "- Estado: ${final_state}"
    echo "- Relatorio: ${stop_task}_execution_report.md"
  fi
  echo ""

  # Tasks pendentes
  echo "## Tasks Pendentes"
  echo ""
  pending_found=false
  while IFS= read -r line; do
    if ! echo "$line" | grep -Eq '^\|[[:space:]]*[0-9]+\.[0-9]+'; then
      continue
    fi
    tid="$(echo "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}')"
    status="$(echo "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4); print $4}' | tr '[:upper:]' '[:lower:]')"
    title="$(echo "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3}')"
    deps="$(echo "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $5); print $5}')"
    if [[ "$status" != "done" && "$status" != "skipped" ]]; then
      if [[ "$pending_found" == "false" ]]; then
        echo "| # | Titulo | Status | Dependencias |"
        echo "|---|--------|--------|--------------|"
        pending_found=true
      fi
      echo "| ${tid} | ${title} | ${status} | ${deps} |"
    fi
  done < "$tasks_md"
  if [[ "$pending_found" == "false" ]]; then
    echo "Nenhuma task pendente."
  fi
  echo ""

  # Logs
  echo "## Logs"
  echo "- Diretorio: ${log_dir}"
} > "$report_file"

echo "$report_file"
