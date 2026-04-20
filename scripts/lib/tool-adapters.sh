#!/usr/bin/env bash
# Adaptadores de invocacao por ferramenta CLI.
# Cada funcao segue o contrato:
#
#   adapter_<tool> <feature_slug> <task_id> <task_file> <log_dir>
#
# Retorno:
#   0 — invocacao concluida (independente do estado da task)
#   1 — falha de invocacao (CLI nao encontrado, crash, timeout)
#
# Efeito:
#   - A IA grava execution report em tasks/prd-<slug>/<task_id>_execution_report.md
#   - Stdout/stderr capturados em <log_dir>/

# Nao executar diretamente — source este arquivo
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && { echo "ERRO: source este arquivo, nao execute diretamente" >&2; exit 1; }

_build_prompt() {
  local feature_slug="$1" task_id="$2" task_file="$3"
  cat <<PROMPT
Execute a tarefa ${task_id} do feature ${feature_slug}.
Caminho da tarefa: tasks/prd-${feature_slug}/${task_file}
Use /execute-task como fluxo canonico.
Retorne o estado canonico ao final: done, blocked, failed ou needs_input.
PROMPT
}

adapter_claude() {
  local feature_slug="$1" task_id="$2" task_file="$3" log_dir="$4"

  if ! command -v claude >/dev/null 2>&1; then
    echo "ERRO: claude CLI nao encontrado no PATH" >&2
    return 1
  fi

  local prompt
  prompt="$(_build_prompt "$feature_slug" "$task_id" "$task_file")"

  local output_file="$log_dir/claude-task-${task_id}-output.json"

  claude -p "$prompt" \
    --dangerously-skip-permissions \
    --output-format json \
    --no-session-persistence \
    >"$output_file" \
    2>"$log_dir/claude-task-${task_id}.stderr" || {
    echo "ERRO: claude retornou exit code $?" >&2
    return 1
  }

  return 0
}

adapter_codex() {
  local feature_slug="$1" task_id="$2" task_file="$3" log_dir="$4"

  if ! command -v codex >/dev/null 2>&1; then
    echo "ERRO: codex CLI nao encontrado no PATH" >&2
    return 1
  fi

  local prompt
  prompt="$(_build_prompt "$feature_slug" "$task_id" "$task_file")"

  codex exec "$prompt" \
    --yolo \
    --json \
    >"$log_dir/codex-task-${task_id}-output.json" \
    2>"$log_dir/codex-task-${task_id}.stderr" || {
    echo "ERRO: codex retornou exit code $?" >&2
    return 1
  }

  return 0
}

adapter_gemini() {
  local feature_slug="$1" task_id="$2" task_file="$3" log_dir="$4"

  if ! command -v gemini >/dev/null 2>&1; then
    echo "ERRO: gemini CLI nao encontrado no PATH" >&2
    return 1
  fi

  local prompt
  prompt="$(_build_prompt "$feature_slug" "$task_id" "$task_file")"

  gemini -p "$prompt" \
    --yolo \
    --output-format json \
    >"$log_dir/gemini-task-${task_id}-output.json" \
    2>"$log_dir/gemini-task-${task_id}.stderr" || {
    echo "ERRO: gemini retornou exit code $?" >&2
    return 1
  }

  return 0
}

adapter_copilot() {
  local feature_slug="$1" task_id="$2" task_file="$3" log_dir="$4"

  # Copilot CLI pode estar como `copilot` direto ou via `gh copilot`
  local copilot_cmd=""
  if command -v copilot >/dev/null 2>&1; then
    copilot_cmd="copilot"
  elif command -v gh >/dev/null 2>&1 && gh copilot --help >/dev/null 2>&1; then
    copilot_cmd="gh copilot --"
  else
    echo "ERRO: copilot CLI nao encontrado no PATH (nem copilot nem gh copilot)" >&2
    return 1
  fi

  local prompt
  prompt="$(_build_prompt "$feature_slug" "$task_id" "$task_file")"

  local output_file="$log_dir/copilot-task-${task_id}-output.json"

  # shellcheck disable=SC2086
  $copilot_cmd -p "$prompt" \
    --yolo \
    --no-ask-user \
    --silent \
    --output-format json \
    >"$output_file" \
    2>"$log_dir/copilot-task-${task_id}.stderr" || {
    echo "ERRO: copilot retornou exit code $?" >&2
    return 1
  }

  return 0
}
