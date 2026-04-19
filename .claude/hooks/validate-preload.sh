#!/usr/bin/env bash
# Hook PreToolUse opcional: verifica se o contrato de carga base foi cumprido
# antes de permitir edicoes em codigo.
#
# Para habilitar, adicione ao .claude/settings.local.json:
#
#   "PreToolUse": [{
#     "matcher": "Edit|Write",
#     "hooks": [{"type": "command", "command": "bash .claude/hooks/validate-preload.sh"}]
#   }]
#
# Este hook e informativo por padrao. Use GOVERNANCE_PRELOAD_MODE=fail para bloquear.
# Entrada: JSON do tool use via stdin.

set -euo pipefail

GOVERNANCE_PRELOAD_MODE="${GOVERNANCE_PRELOAD_MODE:-warn}"

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../../scripts/lib/parse-hook-input.sh
source "$HOOK_DIR/../../scripts/lib/parse-hook-input.sh" 2>/dev/null \
  || source "$(cd "$HOOK_DIR/../.." && pwd)/scripts/lib/parse-hook-input.sh" 2>/dev/null \
  || { echo "AVISO: parse-hook-input.sh nao encontrado" >&2; exit 0; }

_stdin="$(cat)"
file_path="$(printf '%s' "$_stdin" | parse_file_path)"

[[ -n "$file_path" ]] || exit 0

# Only check code files, not governance files themselves
case "$file_path" in
  *.go|*.py|*.ts|*.js|*.tsx|*.jsx)
    # This hook emits a reminder — the actual enforcement depends on the agent following it
    echo "LEMBRETE: antes de editar codigo, confirme que AGENTS.md e agent-governance/SKILL.md foram lidos nesta sessao." >&2
    if [[ "$GOVERNANCE_PRELOAD_MODE" == "fail" ]]; then
      echo "GOVERNANCE_PRELOAD_MODE=fail: bloqueando edicao ate que contrato de carga seja confirmado." >&2
      exit 1
    fi
    ;;
esac

exit 0
