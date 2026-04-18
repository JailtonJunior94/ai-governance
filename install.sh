#!/usr/bin/env bash
# Instala o pacote de governanca para IA em um projeto alvo.
# Uso:
#   bash install.sh [--dry-run] [diretorio-alvo]
#   bash install.sh --tools claude,gemini --langs go,node [--dry-run] [diretorio-alvo]
#
# Modo interativo (default): pergunta quais ferramentas e linguagens instalar.
# Modo nao-interativo: usar --tools e/ou --langs para selecionar sem prompt.
#   --tools all | claude,gemini,codex,copilot
#   --langs all | go,node,python
# --dry-run: mostra o que seria criado/sobrescrito sem executar.

set -euo pipefail

DRY_RUN=0
TOOLS_ARG=""
LANGS_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --tools)
      TOOLS_ARG="$2"
      shift 2
      ;;
    --langs)
      LANGS_ARG="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

RULES_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-.}"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERRO: diretorio alvo nao encontrado: $PROJECT_DIR"
  exit 1
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

if [[ ! -w "$PROJECT_DIR" ]]; then
  echo "ERRO: sem permissao de escrita em: $PROJECT_DIR"
  exit 1
fi

LINK_MODE="${LINK_MODE:-symlink}"
GENERATE_CONTEXTUAL_GOVERNANCE="${GENERATE_CONTEXTUAL_GOVERNANCE:-1}"
GOVERNANCE_GENERATOR="$RULES_DIR/.agents/skills/analyze-project/scripts/generate-governance.sh"

# shellcheck source=scripts/lib/install-common.sh
source "$RULES_DIR/scripts/lib/install-common.sh"
# shellcheck source=scripts/lib/codex-config.sh
source "$RULES_DIR/scripts/lib/codex-config.sh"

if [[ "$RULES_DIR" == "$PROJECT_DIR" ]]; then
  echo "ERRO: o diretorio alvo nao pode ser o proprio repositorio de regras."
  exit 1
fi

# Skills comuns (sempre instaladas)
BASE_SKILLS=(create-prd create-technical-specification create-tasks execute-task refactor review analyze-project agent-governance bugfix)

# Skills de linguagem (selecionaveis pelo usuario)
LANG_SKILLS=()

# Selecao de ferramentas
INSTALL_CLAUDE=0
INSTALL_GEMINI=0
INSTALL_CODEX=0
INSTALL_COPILOT=0

# Selecao de linguagens
INSTALL_GO=0
INSTALL_NODE=0
INSTALL_PYTHON=0

if [[ -n "$TOOLS_ARG" ]]; then
  # Modo nao-interativo
  parse_tools "$TOOLS_ARG"
  if [[ -n "$LANGS_ARG" ]]; then
    parse_langs "$LANGS_ARG"
  fi
else
  # Modo interativo
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
      read -ra nums <<< "$selection"
      for num in "${nums[@]}"; do
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

  echo ""
  echo "Selecione as linguagens para instalar skills de implementacao:"
  echo ""
  echo "  1) go         (inclui go-implementation + object-calisthenics-go)"
  echo "  2) node       (inclui node-implementation)"
  echo "  3) python     (inclui python-implementation)"
  echo "  A) Todas"
  echo ""
  read -rp "Digite os numeros separados por espaco (exemplo: 1 2) ou A para todas: " lang_selection

  case "$lang_selection" in
    [aA])
      INSTALL_GO=1; INSTALL_NODE=1; INSTALL_PYTHON=1
      ;;
    "")
      echo "Nenhuma linguagem selecionada — apenas skills processuais serao instaladas."
      ;;
    *)
      read -ra lang_nums <<< "$lang_selection"
      for num in "${lang_nums[@]}"; do
        case "$num" in
          1) INSTALL_GO=1 ;;
          2) INSTALL_NODE=1 ;;
          3) INSTALL_PYTHON=1 ;;
          *) echo "AVISO: opcao '$num' ignorada (invalida)." ;;
        esac
      done
      ;;
  esac
fi

if [[ $((INSTALL_CLAUDE + INSTALL_GEMINI + INSTALL_CODEX + INSTALL_COPILOT)) -eq 0 ]]; then
  echo "Nenhuma ferramenta selecionada. Encerrando."
  exit 0
fi

selected_tools=""
[[ $INSTALL_CLAUDE -eq 1 ]] && selected_tools="$selected_tools claude"
[[ $INSTALL_GEMINI -eq 1 ]] && selected_tools="$selected_tools gemini"
[[ $INSTALL_CODEX -eq 1 ]]  && selected_tools="$selected_tools codex"
[[ $INSTALL_COPILOT -eq 1 ]] && selected_tools="$selected_tools copilot"
echo "Ferramentas selecionadas:$selected_tools"

[[ $INSTALL_GO -eq 1 ]]     && LANG_SKILLS+=(go-implementation object-calisthenics-go)
[[ $INSTALL_NODE -eq 1 ]]   && LANG_SKILLS+=(node-implementation)
[[ $INSTALL_PYTHON -eq 1 ]] && LANG_SKILLS+=(python-implementation)

SKILLS=("${BASE_SKILLS[@]}" "${LANG_SKILLS[@]}")

selected_langs=""
[[ $INSTALL_GO -eq 1 ]]     && selected_langs="$selected_langs go"
[[ $INSTALL_NODE -eq 1 ]]   && selected_langs="$selected_langs node"
[[ $INSTALL_PYTHON -eq 1 ]] && selected_langs="$selected_langs python"
echo "Linguagens selecionadas:${selected_langs:- nenhuma}"
echo ""

# Base comum (AGENTS.md + skills canonicas selecionadas)
safe_mkdir "$PROJECT_DIR/.agents/skills"
for skill in "${SKILLS[@]}"; do
  _rel_target="$(compute_relpath "$RULES_DIR/.agents/skills/$skill" "$PROJECT_DIR/.agents/skills")"
  link_or_copy_skill "$RULES_DIR/.agents/skills/$skill" "$_rel_target" "$PROJECT_DIR/.agents/skills/$skill"
done

# Claude Code
if [[ $INSTALL_CLAUDE -eq 1 ]]; then
  echo "-> Instalando Claude Code..."
  safe_mkdir "$PROJECT_DIR/.claude/skills"
  safe_mkdir "$PROJECT_DIR/.claude/agents"
  safe_mkdir "$PROJECT_DIR/.claude/rules"
  safe_mkdir "$PROJECT_DIR/.claude/scripts"
  for skill in "${SKILLS[@]}"; do
    link_or_copy_skill "$RULES_DIR/.agents/skills/$skill" "../../.agents/skills/$skill" "$PROJECT_DIR/.claude/skills/$skill"
  done
  safe_cp "$RULES_DIR/.claude/rules/governance.md" "$PROJECT_DIR/.claude/rules/governance.md"
  safe_cp "$RULES_DIR/.claude/scripts/validate-task-evidence.sh" "$PROJECT_DIR/.claude/scripts/"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry_log "gerar .claude/agents/*.md via generate-adapters.sh"
  else
    bash "$RULES_DIR/scripts/generate-adapters.sh" "$PROJECT_DIR" 2>/dev/null || \
      safe_cp "$RULES_DIR/.claude/agents/"*.md "$PROJECT_DIR/.claude/agents/"
  fi
fi

# Gemini CLI
if [[ $INSTALL_GEMINI -eq 1 ]]; then
  echo "-> Instalando Gemini CLI..."
  safe_mkdir "$PROJECT_DIR/.gemini/commands"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry_log "gerar .gemini/commands/*.toml via generate-gemini-commands.sh"
  else
    bash "$RULES_DIR/scripts/generate-gemini-commands.sh" "$PROJECT_DIR"
  fi
fi

# Codex
if [[ $INSTALL_CODEX -eq 1 ]]; then
  echo "-> Instalando Codex..."
  safe_mkdir "$PROJECT_DIR/.codex"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry_log "gerar .codex/config.toml dinamico"
  else
    build_codex_config "$INSTALL_GO" "$INSTALL_NODE" "$INSTALL_PYTHON" > "$PROJECT_DIR/.codex/config.toml"
  fi
fi

# Copilot
if [[ $INSTALL_COPILOT -eq 1 ]]; then
  echo "-> Instalando Copilot..."
  safe_mkdir "$PROJECT_DIR/.github/skills"
  safe_mkdir "$PROJECT_DIR/.github/agents"
  for skill in "${SKILLS[@]}"; do
    link_or_copy_skill "$RULES_DIR/.agents/skills/$skill" "../../.agents/skills/$skill" "$PROJECT_DIR/.github/skills/$skill"
  done
  safe_cp "$RULES_DIR/.github/agents/"*.agent.md "$PROJECT_DIR/.github/agents/"
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo ""
  echo "-> [dry-run] Geracao de governanca contextual seria executada aqui."
  echo ""
  echo "[dry-run] Nenhum arquivo foi alterado."
elif [[ "$GENERATE_CONTEXTUAL_GOVERNANCE" == "1" ]]; then
  echo "-> Gerando governanca contextual..."
  INSTALL_CLAUDE="$INSTALL_CLAUDE" \
  INSTALL_GEMINI="$INSTALL_GEMINI" \
  INSTALL_CODEX="$INSTALL_CODEX" \
  INSTALL_COPILOT="$INSTALL_COPILOT" \
  INSTALL_GO="$INSTALL_GO" \
  INSTALL_NODE="$INSTALL_NODE" \
  INSTALL_PYTHON="$INSTALL_PYTHON" \
  bash "$GOVERNANCE_GENERATOR" "$PROJECT_DIR"
else
  safe_cp "$RULES_DIR/AGENTS.md" "$PROJECT_DIR/AGENTS.md"
  [[ $INSTALL_CLAUDE -eq 1 ]] && safe_cp "$RULES_DIR/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md"
  [[ $INSTALL_GEMINI -eq 1 ]] && safe_cp "$RULES_DIR/GEMINI.md" "$PROJECT_DIR/GEMINI.md"
  [[ $INSTALL_COPILOT -eq 1 ]] && safe_cp "$RULES_DIR/.github/copilot-instructions.md" "$PROJECT_DIR/.github/copilot-instructions.md"
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  echo ""
  echo "Governanca para IA instalada em: $PROJECT_DIR"
  echo "Modo de instalacao da base canonica: $LINK_MODE"
fi
