#!/usr/bin/env bash
# Gera adaptadores Claude agents, GitHub agents e Gemini commands a partir das skills.
# Uso: bash scripts/generate-adapters.sh [diretorio-alvo]
# Se nenhum diretorio for informado, usa o diretorio atual.
#
# Este script unifica a geracao de todos os adaptadores em uma unica fonte de verdade.
# Substitui a necessidade de manter adaptadores Claude e GitHub manualmente.

set -euo pipefail

PROJECT_DIR="${1:-.}"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERRO: diretorio alvo nao encontrado: $PROJECT_DIR" >&2
  exit 1
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
SKILLS_DIR="$PROJECT_DIR/.agents/skills"

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "ERRO: nenhuma skill encontrada em $SKILLS_DIR" >&2
  exit 1
fi

# Manifest lookup via case — compativel com bash 3.x (macOS)
get_claude_name() {
  case "$1" in
    bugfix) echo "bugfixer" ;;
    create-prd) echo "prd-writer" ;;
    analyze-project) echo "project-analyzer" ;;
    refactor) echo "refactorer" ;;
    review) echo "reviewer" ;;
    execute-task) echo "task-executor" ;;
    create-tasks) echo "task-planner" ;;
    create-technical-specification) echo "technical-specification-writer" ;;
  esac
}

get_claude_file() {
  echo "$(get_claude_name "$1").md"
}

get_github_name() {
  case "$1" in
    bugfix) echo "Corretor de Bugs" ;;
    create-prd) echo "Redator de PRD" ;;
    analyze-project) echo "Analisador de Projeto" ;;
    refactor) echo "Refatorador" ;;
    review) echo "Revisor" ;;
    execute-task) echo "Executor de Tarefa" ;;
    create-tasks) echo "Planejador de Tarefas" ;;
    create-technical-specification) echo "Redator de Especificacao Tecnica" ;;
  esac
}

get_github_file() {
  case "$1" in
    bugfix) echo "bugfix.agent.md" ;;
    create-prd) echo "prd-writer.agent.md" ;;
    analyze-project) echo "project-analyzer.agent.md" ;;
    refactor) echo "refactorer.agent.md" ;;
    review) echo "reviewer.agent.md" ;;
    execute-task) echo "task-executor.agent.md" ;;
    create-tasks) echo "task-planner.agent.md" ;;
    create-technical-specification) echo "technical-specification-writer.agent.md" ;;
  esac
}

get_instruction() {
  case "$1" in
    bugfix) echo "corrija os bugs no escopo acordado, rode validacao proporcional e retorne o relatorio de correcao mais o estado final" ;;
    create-prd) echo "colete o contexto minimo de produto, escreva ou atualize o PRD e retorne o caminho final ou um resumo conciso de needs_input" ;;
    analyze-project) echo "analise o projeto alvo, classifique a arquitetura, detecte a stack e ferramentas de IA, e gere os arquivos de governanca apropriados" ;;
    refactor) echo "fique dentro do escopo de refatoracao solicitado, preserve o comportamento observavel e retorne o caminho do relatorio mais o estado final" ;;
    review) echo "revise o diff solicitado, lidere com achados e retorne um veredito canonico" ;;
    execute-task) echo "execute uma tarefa elegivel, rode validacao proporcional e retorne o caminho do relatorio de execucao mais o estado final" ;;
    create-tasks) echo "produza o plano de alto nivel para aprovacao e so entao gere tasks.md e os arquivos por tarefa quando a aprovacao estiver disponivel" ;;
    create-technical-specification) echo "explore os caminhos de codigo relevantes, resolva bloqueios de arquitetura, escreva a especificacao tecnica e as ADRs e retorne os caminhos criados ou um resumo conciso de needs_input" ;;
  esac
}

PROCESSUAL_SKILLS="bugfix create-prd analyze-project refactor review execute-task create-tasks create-technical-specification"

extract_description() {
  local skill_file="$1"
  awk '/^---$/{n++; next} n==1 && /^description:/{sub(/^description:[[:space:]]*/, ""); print; exit}' "$skill_file"
}

short_description() {
  printf '%s' "$1" | sed 's/\. .*/\./' | head -c 120
}

generated_claude=0
generated_github=0

for skill in $PROCESSUAL_SKILLS; do
  skill_file="$SKILLS_DIR/$skill/SKILL.md"
  [[ -f "$skill_file" ]] || continue

  description="$(extract_description "$skill_file")"
  [[ -n "$description" ]] || continue

  short_desc="$(short_description "$description")"
  claude_name="$(get_claude_name "$skill")"
  claude_file="$(get_claude_file "$skill")"
  github_name="$(get_github_name "$skill")"
  github_file="$(get_github_file "$skill")"
  instruction="$(get_instruction "$skill")"

  # Claude agent
  if [[ -d "$PROJECT_DIR/.claude/agents" ]] || [[ -d "$PROJECT_DIR/.claude" ]]; then
    mkdir -p "$PROJECT_DIR/.claude/agents"
    cat > "$PROJECT_DIR/.claude/agents/$claude_file" <<CLAUDE
---
name: $claude_name
description: $short_desc
skills:
  - $skill
---

Use a habilidade pre-carregada \`$skill\` como processo canonico.
Mantenha este subagente estreito: $instruction.
CLAUDE
    generated_claude=$((generated_claude + 1))
  fi

  # GitHub agent
  if [[ -d "$PROJECT_DIR/.github/agents" ]] || [[ -d "$PROJECT_DIR/.github" ]]; then
    mkdir -p "$PROJECT_DIR/.github/agents"
    cat > "$PROJECT_DIR/.github/agents/$github_file" <<GITHUB
---
name: $github_name
description: $short_desc
---

Use a habilidade \`$skill\` como processo canonico.
Mantenha este agente estreito: $instruction.
GITHUB
    generated_github=$((generated_github + 1))
  fi
done

echo "Adaptadores gerados: $generated_claude Claude, $generated_github GitHub"

# Delegar geracao de Gemini commands para o script especializado
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GEMINI_SCRIPT="$SCRIPT_DIR/generate-gemini-commands.sh"
if [[ -f "$GEMINI_SCRIPT" && -d "$PROJECT_DIR/.gemini" ]]; then
  bash "$GEMINI_SCRIPT" "$PROJECT_DIR"
fi
