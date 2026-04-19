#!/usr/bin/env bash
# Hook de validacao pos-edicao: avisa quando arquivos de governanca sao modificados diretamente.
# Instalado em projetos consumidores via install.sh.
# Para habilitar manualmente, adicione ao .claude/settings.local.json:
#
#   "hooks": {
#     "PostToolUse": [{
#       "matcher": "Edit|Write",
#       "hooks": [{"type": "command", "command": "bash .claude/hooks/validate-governance.sh"}]
#     }]
#   }
#
# Entrada: JSON do tool use via stdin.
# Saida: aviso em stderr quando um arquivo de governanca e editado.
#
# Modos (via variavel de ambiente GOVERNANCE_HOOK_MODE):
#   warn  — emite aviso em stderr, exit 0 (default)
#   fail  — emite aviso em stderr, exit 1 (bloqueia a edicao)

set -euo pipefail

GOVERNANCE_HOOK_MODE="${GOVERNANCE_HOOK_MODE:-warn}"

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../../scripts/lib/parse-hook-input.sh
source "$HOOK_DIR/../../scripts/lib/parse-hook-input.sh" 2>/dev/null \
  || source "$(cd "$HOOK_DIR/../.." && pwd)/scripts/lib/parse-hook-input.sh" 2>/dev/null \
  || { echo "AVISO: parse-hook-input.sh nao encontrado" >&2; exit 0; }

_stdin="$(cat)"
file_path="$(printf '%s' "$_stdin" | parse_file_path)"

[[ -n "$file_path" ]] || exit 0

case "$file_path" in
  */.agents/skills/*/SKILL.md|*/.agents/skills/*/references/*.md|*/AGENTS.md)
    echo "AVISO: arquivo de governanca modificado: $file_path" >&2
    echo "Verifique se esta edicao e intencional e se nao quebra o contrato de upgrade." >&2
    if [[ "$GOVERNANCE_HOOK_MODE" == "fail" ]]; then
      exit 1
    fi
    ;;
esac

exit 0
