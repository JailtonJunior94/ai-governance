#!/usr/bin/env bash
# Orquestrador externo de loop de tasks.
# Executa todas as tasks elegiveis de um tasks/prd-<feature-slug>/ em sequencia,
# invocando o CLI de IA como processo separado para cada task (contexto limpo).
#
# Uso:
#   bash scripts/loop-execute-tasks.sh <feature-slug> [--tool claude|codex|gemini]
#
# Exemplos:
#   bash scripts/loop-execute-tasks.sh semver-automation-release
#   bash scripts/loop-execute-tasks.sh my-feature --tool codex
#
# Retorno:
#   0 — todas as tasks elegiveis concluidas (done)
#   1 — loop interrompido por estado nao-done (blocked, failed, needs_input)
#   2 — uso incorreto ou pre-condicao nao atendida
#
# Estrategia de contexto:
#   Cada iteracao invoca o CLI em processo separado, garantindo
#   contexto limpo. Nenhum estado e compartilhado entre iteracoes
#   alem dos artefatos persistidos no filesystem (tasks.md, reports).
#
# Regra de parada:
#   - Todas as tasks done → exit 0
#   - blocked, failed, needs_input → exit 1
#   - Nenhuma task elegivel → exit 0
#   - Max 1 retry por task (guard contra tasks.md nao atualizado)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# shellcheck source=lib/tool-adapters.sh
source "$LIB_DIR/tool-adapters.sh"

# --- Argumentos ---
if [[ $# -lt 1 ]]; then
  echo "Uso: $0 <feature-slug> [--tool claude|codex|gemini|copilot]" >&2
  exit 2
fi

feature_slug="$1"
shift

tool="claude"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool)
      tool="${2:-}"
      if [[ -z "$tool" ]]; then
        echo "ERRO: --tool requer um valor (claude, codex, gemini, copilot)" >&2
        exit 2
      fi
      shift 2
      ;;
    --tool=*)
      tool="${1#--tool=}"
      shift
      ;;
    *)
      echo "ERRO: argumento desconhecido: $1" >&2
      exit 2
      ;;
  esac
done

# Validar tool
case "$tool" in
  claude|codex|gemini|copilot) ;;
  *)
    echo "ERRO: tool desconhecido '$tool'. Use: claude, codex, gemini, copilot." >&2
    exit 2
    ;;
esac

# Validar que a funcao adapter existe
if ! declare -f "adapter_${tool}" >/dev/null 2>&1; then
  echo "ERRO: adapter para '$tool' nao encontrado em tool-adapters.sh" >&2
  exit 2
fi

# --- Caminhos ---
tasks_dir="$ROOT_DIR/tasks/prd-${feature_slug}"
tasks_md="$tasks_dir/tasks.md"
prd_md="$tasks_dir/prd.md"
techspec_md="$tasks_dir/techspec.md"
log_dir="$ROOT_DIR/.task-loop-logs/$(date '+%Y%m%d-%H%M%S')"
start_time="$(date '+%Y-%m-%d %H:%M:%S')"

mkdir -p "$log_dir"

# --- Lockfile ---
lock_file="$tasks_dir/.loop.lock"
exec 9>"$lock_file"
if ! flock -n 9; then
  echo "ERRO: outra instancia do loop ja esta em execucao para prd-${feature_slug}" >&2
  exit 1
fi

cleanup() {
  rm -f "$lock_file"
}
trap cleanup EXIT

# --- Pre-condicoes ---
echo "=== Loop Execute Tasks: prd-${feature_slug} (tool: ${tool}) ==="
echo ""

echo "[pre] Verificando artefatos obrigatorios..."
for required in "$tasks_md" "$prd_md" "$techspec_md"; do
  if [[ ! -f "$required" ]]; then
    echo "ERRO: arquivo nao encontrado: $required" >&2
    exit 2
  fi
done
echo "  OK: tasks.md, prd.md, techspec.md presentes"

echo "[pre] Verificando cobertura de requisitos..."
if ! bash "$ROOT_DIR/scripts/check-rf-coverage.sh" "$prd_md" "$tasks_md"; then
  echo "BLOQUEADO: cobertura de requisitos incompleta" >&2
  exit 1
fi

# --- Loop ---
completed=()
final_state="done"
stop_task=""
last_task_id=""
retry_count=0
max_retries=1

echo ""
echo "=== Iniciando loop ==="

while true; do
  # Selecionar proxima task elegivel
  eligible="$(bash "$LIB_DIR/task-selector.sh" "$tasks_md" 2>/dev/null)" || {
    # Nenhuma task elegivel
    echo ""
    echo "[loop] Nenhuma task elegivel encontrada."
    break
  }

  task_id="$(echo "$eligible" | cut -f1)"
  task_file="$(echo "$eligible" | cut -f2)"
  task_title="$(echo "$eligible" | cut -f3)"

  # Guard contra re-selecao da mesma task (tasks.md nao atualizado)
  if [[ "$task_id" == "$last_task_id" ]]; then
    retry_count=$((retry_count + 1))
    if [[ "$retry_count" -gt "$max_retries" ]]; then
      echo ""
      echo "ERRO: task $task_id re-selecionada ${retry_count} vez(es) — tasks.md pode nao ter sido atualizado pela IA" >&2
      final_state="failed"
      stop_task="$task_id"
      break
    fi
  else
    retry_count=0
  fi
  last_task_id="$task_id"

  echo ""
  echo "=== Task ${task_id}: ${task_title} ==="
  echo "  Arquivo: ${task_file}"
  echo "  Ferramenta: ${tool}"
  echo ""

  # Invocar adapter
  if ! "adapter_${tool}" "$feature_slug" "$task_id" "$task_file" "$log_dir"; then
    final_state="failed"
    stop_task="$task_id"
    echo "ERRO: invocacao do ${tool} falhou para task ${task_id}" >&2
    break
  fi

  # Parsear estado do report
  report_file="$tasks_dir/${task_id}_execution_report.md"
  state="$(bash "$LIB_DIR/report-parser.sh" "$report_file")"

  echo "  Estado: ${state}"

  case "$state" in
    done)
      completed+=("$task_id")
      echo "  OK: task ${task_id} concluida"
      ;;
    blocked|failed|needs_input)
      final_state="$state"
      stop_task="$task_id"
      echo "  PARADA: task ${task_id} retornou ${state}"
      break
      ;;
    *)
      final_state="failed"
      stop_task="$task_id"
      echo "  ERRO: estado desconhecido '${state}' para task ${task_id}" >&2
      break
      ;;
  esac
done

# --- Relatorio consolidado ---
echo ""
echo "=== Gerando relatorio consolidado ==="

completed_str="${completed[*]:-}"
report_path="$(bash "$LIB_DIR/loop-report-generator.sh" \
  "$feature_slug" "$final_state" "${stop_task:-}" \
  "$completed_str" "$log_dir" "$start_time" "$tasks_md")"

echo "  Relatorio: ${report_path}"
echo ""
echo "=== Loop finalizado: ${final_state} ==="
echo "  Tasks concluidas: ${#completed[@]}"
if [[ -n "$stop_task" ]]; then
  echo "  Task de parada: ${stop_task} (${final_state})"
fi

if [[ "$final_state" == "done" ]]; then
  exit 0
else
  exit 1
fi
