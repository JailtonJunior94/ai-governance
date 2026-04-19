#!/usr/bin/env bash
# Wrapper de pre-validacao para Codex/Gemini CLI.
# Verifica contrato de carga e pre-requisitos antes de delegar ao tool nativo.
#
# Uso:
#   bash scripts/governance-wrapper.sh <tool> <skill> [args...]
#
# Exemplos:
#   bash scripts/governance-wrapper.sh codex go-implementation "implementar feature X"
#   bash scripts/governance-wrapper.sh gemini execute-task "tasks/prd-my-feature"
#
# O wrapper verifica:
#   1. AGENTS.md e agent-governance existem (contrato base)
#   2. Pre-requisitos da skill estao satisfeitos
#   3. Budget de tokens esta dentro do limite
#
# Se todas as verificacoes passarem, emite instrucoes de invocacao.
# O wrapper NAO executa o tool automaticamente — apenas valida e orienta.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 2 ]]; then
  echo "Uso: $0 <tool> <skill> [args...]" >&2
  echo "Tools: codex, gemini, copilot" >&2
  echo "Exemplo: $0 codex go-implementation 'implementar feature X'" >&2
  exit 2
fi

tool="$1"
skill="$2"
shift 2
args="${*:-}"

errors=0

# Validar tool
case "$tool" in
  codex|gemini|copilot) ;;
  *)
    echo "ERRO: tool desconhecido '$tool'. Use: codex, gemini, copilot." >&2
    exit 2
    ;;
esac

echo "=== Governance Wrapper: $tool / $skill ==="

# 1. Contrato base
echo "[1/3] Verificando contrato base..."
if [[ ! -f "$ROOT_DIR/AGENTS.md" ]]; then
  echo "  FALHA: AGENTS.md nao encontrado" >&2
  errors=1
else
  echo "  OK: AGENTS.md presente"
fi

if [[ ! -f "$ROOT_DIR/.agents/skills/agent-governance/SKILL.md" ]]; then
  echo "  FALHA: agent-governance/SKILL.md nao encontrado" >&2
  errors=1
else
  echo "  OK: agent-governance/SKILL.md presente"
fi

if [[ ! -f "$ROOT_DIR/.agents/skills/$skill/SKILL.md" ]]; then
  echo "  FALHA: skill '$skill' nao encontrada em .agents/skills/" >&2
  errors=1
else
  echo "  OK: $skill/SKILL.md presente"
fi

# 2. Pre-requisitos da skill
echo "[2/3] Verificando pre-requisitos da skill..."
if bash "$ROOT_DIR/scripts/check-skill-prerequisites.sh" "$skill" "${args%% *}" 2>&1 | grep -q "^OK:"; then
  echo "  OK: pre-requisitos satisfeitos"
else
  echo "  AVISO: pre-requisitos podem estar faltando (verifique a saida acima)" >&2
fi

# 3. Budget estimado
echo "[3/3] Estimando budget de tokens..."
budget_files=("$ROOT_DIR/AGENTS.md" "$ROOT_DIR/.agents/skills/agent-governance/SKILL.md")
if [[ -f "$ROOT_DIR/.agents/skills/$skill/SKILL.md" ]]; then
  budget_files+=("$ROOT_DIR/.agents/skills/$skill/SKILL.md")
fi

if bash "$ROOT_DIR/scripts/check-token-budget.sh" "${budget_files[@]}" 2>&1 | grep -q "^OK:"; then
  echo "  OK: dentro do budget"
else
  echo "  AVISO: budget pode estar proximo do limite" >&2
fi

if [[ "$errors" -ne 0 ]]; then
  echo ""
  echo "BLOQUEADO: corrija os erros acima antes de invocar $tool." >&2
  exit 1
fi

echo ""
echo "=== Validacao aprovada ==="
echo ""

# Instrucoes de invocacao por tool
case "$tool" in
  codex)
    echo "Invoque no Codex:"
    echo "  codex \"$skill: $args\""
    ;;
  gemini)
    echo "Invoque no Gemini CLI:"
    echo "  gemini -c $skill -- \"$args\""
    ;;
  copilot)
    echo "Invoque no Copilot:"
    echo "  Use o agent '$skill' com a solicitacao: $args"
    ;;
esac
