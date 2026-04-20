#!/usr/bin/env bash
# Teste E2E dedicado para o GitHub Copilot CLI adapter.
# Valida integridade dos agents, delegacao para skills canonicas,
# instrucoes contextuais e workflow completo equivalente ao Gemini E2E.

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"

PASSED=0
FAILED=0

pass() {
  echo "PASS  $1"
  PASSED=$((PASSED + 1))
}

fail() {
  echo "FAIL  $1"
  FAILED=$((FAILED + 1))
}

AGENTS_DIR="$ROOT_DIR/.github/agents"
SKILLS_DIR="$ROOT_DIR/.agents/skills"
COPILOT_MD="$ROOT_DIR/.github/copilot-instructions.md"

# ========== 1. copilot-instructions.md existe e referencia AGENTS.md ==========
echo "=== copilot-instructions.md ==="

if [[ -f "$COPILOT_MD" ]]; then
  pass "copilot-md: copilot-instructions.md existe"
else
  fail "copilot-md: copilot-instructions.md ausente"
fi

if grep -q 'AGENTS\.md' "$COPILOT_MD" 2>/dev/null; then
  pass "copilot-md: referencia AGENTS.md"
else
  fail "copilot-md: nao referencia AGENTS.md"
fi

if grep -q '\.agents/skills/' "$COPILOT_MD" 2>/dev/null; then
  pass "copilot-md: referencia .agents/skills/ como fonte canonica"
else
  fail "copilot-md: nao referencia .agents/skills/ como fonte canonica"
fi

# ========== 2. Cada agent delega para skill canonica existente ==========
echo "=== Delegacao para skill canonica ==="

for agent_file in "$AGENTS_DIR"/*.agent.md; do
  [[ -f "$agent_file" ]] || continue
  agent_name="$(basename "$agent_file" .agent.md)"

  # Mapear nome do agent para skill canonica
  skill_name=""
  case "$agent_name" in
    bugfix) skill_name="bugfix" ;;
    project-analyzer) skill_name="analyze-project" ;;
    prd-writer) skill_name="create-prd" ;;
    refactorer) skill_name="refactor" ;;
    reviewer) skill_name="review" ;;
    task-executor) skill_name="execute-task" ;;
    task-planner) skill_name="create-tasks" ;;
    technical-specification-writer) skill_name="create-technical-specification" ;;
    *) skill_name="$agent_name" ;;
  esac

  skill_md="$SKILLS_DIR/$skill_name/SKILL.md"
  if [[ -f "$skill_md" ]]; then
    pass "copilot-skill/$agent_name: SKILL.md canonica existe ($skill_name)"
  else
    fail "copilot-skill/$agent_name: SKILL.md canonica ausente ($skill_name)"
  fi
done

# ========== 3. Cada agent referencia o caminho correto da skill ==========
echo "=== Referencia ao caminho da skill no prompt ==="

for agent_file in "$AGENTS_DIR"/*.agent.md; do
  [[ -f "$agent_file" ]] || continue
  agent_name="$(basename "$agent_file" .agent.md)"
  if grep -q '\.agents/skills/' "$agent_file" 2>/dev/null; then
    pass "copilot-ref/$agent_name: prompt referencia .agents/skills/"
  else
    fail "copilot-ref/$agent_name: prompt nao referencia .agents/skills/"
  fi
done

# ========== 4. Cada agent menciona contrato de carga base ==========
echo "=== Contrato de carga base no prompt ==="

for agent_file in "$AGENTS_DIR"/*.agent.md; do
  [[ -f "$agent_file" ]] || continue
  agent_name="$(basename "$agent_file" .agent.md)"
  if grep -q 'AGENTS\.md' "$agent_file" 2>/dev/null; then
    pass "copilot-base/$agent_name: prompt menciona AGENTS.md"
  else
    fail "copilot-base/$agent_name: prompt nao menciona AGENTS.md"
  fi
done

# ========== 5. Skills expostas em .github/skills/ ==========
echo "=== Skills expostas ==="

if [[ -d "$ROOT_DIR/.github/skills" ]]; then
  pass "copilot-skills-dir: .github/skills/ existe"

  # Verificar que pelo menos as skills core estao expostas
  for core_skill in agent-governance execute-task review bugfix refactor; do
    if [[ -e "$ROOT_DIR/.github/skills/$core_skill/SKILL.md" ]]; then
      pass "copilot-skills/$core_skill: exposta em .github/skills"
    else
      fail "copilot-skills/$core_skill: ausente em .github/skills"
    fi
  done
else
  fail "copilot-skills-dir: .github/skills/ ausente"
fi

# ========== 6. Contagem de agents >= 8 ==========
echo "=== Contagem de agents ==="

agent_count=0
for agent_file in "$AGENTS_DIR"/*.agent.md; do
  [[ -f "$agent_file" ]] || continue
  agent_count=$((agent_count + 1))
done

if [[ "$agent_count" -ge 8 ]]; then
  pass "copilot-count: $agent_count agents (>= 8 esperados)"
else
  fail "copilot-count: apenas $agent_count agents (esperado >= 8)"
fi

# ========== 7. Workflow spec-driven: PRD → TechSpec → Tasks → Execute ==========
echo "=== Workflow spec-driven ==="

# Verificar que agents cobrem o fluxo completo
for required_agent in prd-writer.agent.md technical-specification-writer.agent.md task-planner.agent.md task-executor.agent.md reviewer.agent.md; do
  if [[ -f "$AGENTS_DIR/$required_agent" ]]; then
    pass "copilot-workflow: $required_agent presente"
  else
    fail "copilot-workflow: $required_agent ausente (quebra fluxo spec-driven)"
  fi
done

# ========== Resumo ==========
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"
if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
