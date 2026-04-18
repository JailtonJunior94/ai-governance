#!/usr/bin/env bash
# Valida paridade entre skills canonicas e adaptadores por ferramenta.
# Cada skill processual deve ter adaptadores em Claude agents, Gemini commands e GitHub agents.
# Skills de linguagem e agent-governance sao excluidas por design (carregadas via SKILL.md, nao via adaptador).
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"

FAILED=0
PASSED=0

check_file() {
  local label="$1" path="$2"
  if [[ -e "$path" ]]; then
    PASSED=$((PASSED + 1))
  else
    echo "FAIL  $label -> $path"
    FAILED=$((FAILED + 1))
  fi
}

check_codex() {
  local skill="$1"
  if grep -q "\"\.agents/skills/$skill\"" "$ROOT_DIR/.codex/config.toml" 2>/dev/null; then
    PASSED=$((PASSED + 1))
  else
    echo "FAIL  codex-config/$skill -> not found in .codex/config.toml"
    FAILED=$((FAILED + 1))
  fi
}

echo "=== Claude agents ==="
check_file "claude-agent/create-prd" "$ROOT_DIR/.claude/agents/prd-writer.md"
check_file "claude-agent/create-technical-specification" "$ROOT_DIR/.claude/agents/technical-specification-writer.md"
check_file "claude-agent/create-tasks" "$ROOT_DIR/.claude/agents/task-planner.md"
check_file "claude-agent/execute-task" "$ROOT_DIR/.claude/agents/task-executor.md"
check_file "claude-agent/refactor" "$ROOT_DIR/.claude/agents/refactorer.md"
check_file "claude-agent/review" "$ROOT_DIR/.claude/agents/reviewer.md"
check_file "claude-agent/analyze-project" "$ROOT_DIR/.claude/agents/project-analyzer.md"
check_file "claude-agent/bugfix" "$ROOT_DIR/.claude/agents/bugfixer.md"

echo "=== GitHub agents ==="
check_file "github-agent/create-prd" "$ROOT_DIR/.github/agents/prd-writer.agent.md"
check_file "github-agent/create-technical-specification" "$ROOT_DIR/.github/agents/technical-specification-writer.agent.md"
check_file "github-agent/create-tasks" "$ROOT_DIR/.github/agents/task-planner.agent.md"
check_file "github-agent/execute-task" "$ROOT_DIR/.github/agents/task-executor.agent.md"
check_file "github-agent/refactor" "$ROOT_DIR/.github/agents/refactorer.agent.md"
check_file "github-agent/review" "$ROOT_DIR/.github/agents/reviewer.agent.md"
check_file "github-agent/analyze-project" "$ROOT_DIR/.github/agents/project-analyzer.agent.md"
check_file "github-agent/bugfix" "$ROOT_DIR/.github/agents/bugfix.agent.md"

echo "=== Gemini commands ==="
for skill in create-prd create-technical-specification create-tasks execute-task refactor review analyze-project bugfix object-calisthenics-go go-implementation node-implementation python-implementation; do
  check_file "gemini-cmd/$skill" "$ROOT_DIR/.gemini/commands/${skill}.toml"
done

echo "=== Codex config ==="
for skill in agent-governance go-implementation node-implementation python-implementation analyze-project create-prd create-technical-specification create-tasks execute-task refactor review object-calisthenics-go bugfix; do
  check_codex "$skill"
done

echo ""
echo "Resultado: $PASSED passed, $FAILED failed"
if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
