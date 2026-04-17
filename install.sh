#!/usr/bin/env bash
# Instala o pacote de governanca para IA em um projeto alvo.
# Uso: bash install.sh [diretorio-alvo]
# Se omitido, o diretorio atual sera usado.
# O script pergunta quais ferramentas devem ser instaladas.

set -euo pipefail

RULES_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
LINK_MODE="${LINK_MODE:-symlink}"
GENERATE_CONTEXTUAL_GOVERNANCE="${GENERATE_CONTEXTUAL_GOVERNANCE:-1}"
GOVERNANCE_GENERATOR="$RULES_DIR/.agents/skills/analyze-project/scripts/generate-governance.sh"

if [[ "$RULES_DIR" == "$PROJECT_DIR" ]]; then
  echo "ERRO: o diretorio alvo nao pode ser o proprio repositorio de regras."
  exit 1
fi

SKILLS=(create-prd create-technical-specification create-tasks execute-task refactor review analyze-project)

link_or_copy_dir() {
  local source="$1"
  local destination="$2"

  mkdir -p "$(dirname "$destination")"

  if [[ "$LINK_MODE" == "copy" ]]; then
    rm -rf "$destination"
    cp -R "$source" "$destination"
    return
  fi

  ln -sfn "$source" "$destination"
}

link_or_copy_skill() {
  local source_abs="$1"
  local link_target="$2"
  local destination="$3"

  mkdir -p "$(dirname "$destination")"

  if [[ "$LINK_MODE" == "copy" ]]; then
    rm -rf "$destination"
    cp -R "$source_abs" "$destination"
    return
  fi

  ln -sfn "$link_target" "$destination"
}

# Selecao de ferramentas
INSTALL_CLAUDE=0
INSTALL_GEMINI=0
INSTALL_CODEX=0
INSTALL_COPILOT=0

echo "Selecione as ferramentas que deseja instalar:"
echo ""
echo "  1) claude"
echo "  2) gemini"
echo "  3) codex"
echo "  4) copilot"
echo "  A) Todas"
echo ""
read -rp "Digite os numeros separados por espaco (exemplo: 1 3) ou A para todas: " selection

case "$selection" in
  [aA]|"")
    INSTALL_CLAUDE=1; INSTALL_GEMINI=1; INSTALL_CODEX=1; INSTALL_COPILOT=1
    ;;
  *)
    for num in $selection; do
      case "$num" in
        1) INSTALL_CLAUDE=1 ;;
        2) INSTALL_GEMINI=1 ;;
        3) INSTALL_CODEX=1 ;;
        4) INSTALL_COPILOT=1 ;;
        *) echo "AVISO: opcao '$num' ignorada (invalida)." ;;
      esac
    done
    ;;
esac

if [[ $((INSTALL_CLAUDE + INSTALL_GEMINI + INSTALL_CODEX + INSTALL_COPILOT)) -eq 0 ]]; then
  echo "Nenhuma ferramenta selecionada. Encerrando."
  exit 0
fi

selected=""
[[ $INSTALL_CLAUDE -eq 1 ]] && selected="$selected claude"
[[ $INSTALL_GEMINI -eq 1 ]] && selected="$selected gemini"
[[ $INSTALL_CODEX -eq 1 ]]  && selected="$selected codex"
[[ $INSTALL_COPILOT -eq 1 ]] && selected="$selected copilot"
echo ""
echo "Ferramentas selecionadas:$selected"
echo ""

# Base comum (AGENTS.md + skills canonicas)
mkdir -p "$PROJECT_DIR/.agents"
link_or_copy_dir "$RULES_DIR/.agents/skills" "$PROJECT_DIR/.agents/skills"

# Claude Code
if [[ $INSTALL_CLAUDE -eq 1 ]]; then
  echo "-> Instalando Claude Code..."
  mkdir -p "$PROJECT_DIR/.claude/skills" "$PROJECT_DIR/.claude/agents" "$PROJECT_DIR/.claude/rules" "$PROJECT_DIR/.claude/scripts"
  for skill in "${SKILLS[@]}"; do
    link_or_copy_skill "$RULES_DIR/.agents/skills/$skill" "../../.agents/skills/$skill" "$PROJECT_DIR/.claude/skills/$skill"
  done
  cp "$RULES_DIR/.claude/rules/governance.md" "$PROJECT_DIR/.claude/rules/governance.md"
  cp "$RULES_DIR/.claude/agents/"*.md "$PROJECT_DIR/.claude/agents/"
  cp "$RULES_DIR/.claude/scripts/validate-task-evidence.sh" "$PROJECT_DIR/.claude/scripts/"
fi

# Gemini CLI
if [[ $INSTALL_GEMINI -eq 1 ]]; then
  echo "-> Instalando Gemini CLI..."
  mkdir -p "$PROJECT_DIR/.gemini/commands"
  cp "$RULES_DIR/.gemini/commands/"*.toml "$PROJECT_DIR/.gemini/commands/"
fi

# Codex
if [[ $INSTALL_CODEX -eq 1 ]]; then
  echo "-> Instalando Codex..."
  mkdir -p "$PROJECT_DIR/.codex"
  cp "$RULES_DIR/.codex/config.toml" "$PROJECT_DIR/.codex/config.toml"
fi

# Copilot
if [[ $INSTALL_COPILOT -eq 1 ]]; then
  echo "-> Instalando Copilot..."
  mkdir -p "$PROJECT_DIR/.github/skills" "$PROJECT_DIR/.github/agents"
  for skill in "${SKILLS[@]}"; do
    link_or_copy_skill "$RULES_DIR/.agents/skills/$skill" "../../.agents/skills/$skill" "$PROJECT_DIR/.github/skills/$skill"
  done
  cp "$RULES_DIR/.github/agents/"*.md "$PROJECT_DIR/.github/agents/" 2>/dev/null || \
  cp "$RULES_DIR/.github/agents/"*.agent.md "$PROJECT_DIR/.github/agents/"
fi

if [[ "$GENERATE_CONTEXTUAL_GOVERNANCE" == "1" ]]; then
  echo "-> Gerando governanca contextual..."
  INSTALL_CLAUDE="$INSTALL_CLAUDE" \
  INSTALL_GEMINI="$INSTALL_GEMINI" \
  INSTALL_COPILOT="$INSTALL_COPILOT" \
  bash "$GOVERNANCE_GENERATOR" "$PROJECT_DIR"
else
  cp "$RULES_DIR/AGENTS.md" "$PROJECT_DIR/AGENTS.md"
  [[ $INSTALL_CLAUDE -eq 1 ]] && cp "$RULES_DIR/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md"
  [[ $INSTALL_GEMINI -eq 1 ]] && cp "$RULES_DIR/GEMINI.md" "$PROJECT_DIR/GEMINI.md"
  [[ $INSTALL_COPILOT -eq 1 ]] && cp "$RULES_DIR/.github/copilot-instructions.md" "$PROJECT_DIR/.github/copilot-instructions.md"
fi

echo ""
echo "Governanca para IA instalada em: $PROJECT_DIR"
echo "Modo de instalacao da base canonica: $LINK_MODE"
