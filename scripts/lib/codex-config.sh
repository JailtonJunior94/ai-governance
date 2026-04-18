#!/usr/bin/env bash
# Gera configuracao de skills para Codex (.codex/config.toml).
# Uso: source scripts/lib/codex-config.sh
#      build_codex_config <include_go:0|1> <include_node:0|1> <include_python:0|1>

build_codex_config() {
  local include_go="${1:-0}"
  local include_node="${2:-0}"
  local include_python="${3:-0}"
  local profile="${CODEX_SKILL_PROFILE:-minimal}"
  local skills=()

  case "$profile" in
    full)
      skills=(agent-governance analyze-project create-prd create-technical-specification create-tasks execute-task refactor review bugfix)
      ;;
    *)
      skills=(agent-governance bugfix review refactor execute-task)
      ;;
  esac

  [[ "$include_go" == "1" ]] && skills+=(go-implementation object-calisthenics-go)
  [[ "$include_node" == "1" ]] && skills+=(node-implementation)
  [[ "$include_python" == "1" ]] && skills+=(python-implementation)

  local output=""
  for skill in "${skills[@]}"; do
    output+="[[skills.config]]\npath = \".agents/skills/$skill\"\nenabled = true\n\n"
  done

  printf '%b' "$output"
}
