#!/usr/bin/env bash
# Instala o pacote de governanca para IA em um projeto alvo.
# Uso: bash install.sh [--dry-run] [diretorio-alvo]
# Se omitido, o diretorio atual sera usado.
# O script pergunta quais ferramentas devem ser instaladas.
# --dry-run: mostra o que seria criado/sobrescrito sem executar.

set -euo pipefail

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi

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

if [[ "$RULES_DIR" == "$PROJECT_DIR" ]]; then
  echo "ERRO: o diretorio alvo nao pode ser o proprio repositorio de regras."
  exit 1
fi

SKILLS=(create-prd create-technical-specification create-tasks execute-task refactor review analyze-project agent-governance go-implementation object-calisthenics-go bugfix)

dry_log() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] $*"
  fi
}

safe_mkdir() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ ! -d "$1" ]]; then
      dry_log "mkdir -p $1"
    fi
    return
  fi
  mkdir -p "$1"
}

safe_cp() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry_log "cp $1 -> $2"
    return
  fi
  cp "$@"
}

safe_cp_r() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry_log "cp -R $1 -> $2"
    return
  fi
  cp -R "$@"
}

safe_ln() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    dry_log "ln -sfn $1 -> $2"
    return
  fi
  ln -sfn "$1" "$2"
}

link_or_copy_dir() {
  local source="$1"
  local destination="$2"

  safe_mkdir "$(dirname "$destination")"

  if [[ "$LINK_MODE" == "copy" ]]; then
    if [[ "$DRY_RUN" -eq 0 ]]; then
      rm -rf "$destination"
    fi
    safe_cp_r "$source" "$destination"
    return
  fi

  safe_ln "$source" "$destination"
}

link_or_copy_skill() {
  local source_abs="$1"
  local link_target="$2"
  local destination="$3"

  safe_mkdir "$(dirname "$destination")"

  if [[ "$LINK_MODE" == "copy" ]]; then
    if [[ "$DRY_RUN" -eq 0 ]]; then
      rm -rf "$destination"
    fi
    safe_cp_r "$source_abs" "$destination"
    return
  fi

  safe_ln "$link_target" "$destination"
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
safe_mkdir "$PROJECT_DIR/.agents"
link_or_copy_dir "$RULES_DIR/.agents/skills" "$PROJECT_DIR/.agents/skills"

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
  safe_cp "$RULES_DIR/.claude/agents/"*.md "$PROJECT_DIR/.claude/agents/"
  safe_cp "$RULES_DIR/.claude/scripts/validate-task-evidence.sh" "$PROJECT_DIR/.claude/scripts/"
fi

# Gemini CLI
if [[ $INSTALL_GEMINI -eq 1 ]]; then
  echo "-> Instalando Gemini CLI..."
  safe_mkdir "$PROJECT_DIR/.gemini/commands"
  safe_cp "$RULES_DIR/.gemini/commands/"*.toml "$PROJECT_DIR/.gemini/commands/"
fi

# Codex
if [[ $INSTALL_CODEX -eq 1 ]]; then
  echo "-> Instalando Codex..."
  safe_mkdir "$PROJECT_DIR/.codex"
  safe_cp "$RULES_DIR/.codex/config.toml" "$PROJECT_DIR/.codex/config.toml"
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
  INSTALL_COPILOT="$INSTALL_COPILOT" \
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
