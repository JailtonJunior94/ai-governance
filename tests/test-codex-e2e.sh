#!/usr/bin/env bash
# Teste E2E dedicado para o Codex adapter.
# Valida integridade do config.toml, delegacao para skills canonicas,
# perfis de skill e workflow operacional.

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
INSTALL_SCRIPT="$ROOT_DIR/install.sh"

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

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

CODEX_CONFIG="$ROOT_DIR/.codex/config.toml"
SKILLS_DIR="$ROOT_DIR/.agents/skills"

# ========== 1. config.toml existe e e valido ==========
echo "=== config.toml ==="

if [[ -f "$CODEX_CONFIG" ]]; then
  pass "codex-config: config.toml existe"
else
  fail "codex-config: config.toml ausente"
fi

# ========== 2. Cada skill referenciada no config aponta para skill canonica existente ==========
echo "=== Delegacao para skill canonica ==="

if [[ -f "$CODEX_CONFIG" ]]; then
  while IFS= read -r skill_path; do
    [[ -n "$skill_path" ]] || continue
    # Extrair path
    clean_path="$(echo "$skill_path" | sed 's/.*path[[:space:]]*=[[:space:]]*"//' | sed 's/".*//')"
    skill_md="$ROOT_DIR/$clean_path/SKILL.md"
    skill_name="$(basename "$clean_path")"
    if [[ -f "$skill_md" ]]; then
      pass "codex-skill/$skill_name: SKILL.md canonica existe"
    else
      fail "codex-skill/$skill_name: SKILL.md canonica ausente em $skill_md"
    fi
  done < <(grep 'path' "$CODEX_CONFIG")
fi

# ========== 3. Todas as skills estao enabled ==========
echo "=== Skills habilitadas ==="

if [[ -f "$CODEX_CONFIG" ]]; then
  disabled_count="$(grep -c 'enabled = false' "$CODEX_CONFIG" || true)"
  if [[ "$disabled_count" -eq 0 ]]; then
    pass "codex-enabled: todas as skills estao enabled"
  else
    fail "codex-enabled: $disabled_count skill(s) desabilitada(s)"
  fi
fi

# ========== 4. Instalacao codex-only com Go ==========
echo "=== Instalacao codex-only ==="

CODEX_TARGET="$tmpdir/codex-go-project"
mkdir -p "$CODEX_TARGET"
echo "module example.com/codex-test" > "$CODEX_TARGET/go.mod"
echo "go 1.23" >> "$CODEX_TARGET/go.mod"

bash "$INSTALL_SCRIPT" --tools codex --langs go "$CODEX_TARGET" > /dev/null 2>&1

if [[ -f "$CODEX_TARGET/AGENTS.md" ]]; then
  pass "codex-install: AGENTS.md gerado"
else
  fail "codex-install: AGENTS.md ausente"
fi

if [[ -f "$CODEX_TARGET/.codex/config.toml" ]]; then
  pass "codex-install: config.toml gerado"
else
  fail "codex-install: config.toml ausente"
fi

if [[ -e "$CODEX_TARGET/.agents/skills/go-implementation/SKILL.md" ]]; then
  pass "codex-install: skill Go exposta"
else
  fail "codex-install: skill Go ausente"
fi

if [[ ! -d "$CODEX_TARGET/.claude" && ! -d "$CODEX_TARGET/.gemini" && ! -d "$CODEX_TARGET/.github/agents" ]]; then
  pass "codex-install: nenhuma ferramenta nao solicitada instalada"
else
  fail "codex-install: ferramentas nao solicitadas instaladas"
fi

# ========== 5. Config gerado referencia skills corretas ==========
echo "=== Config gerado ==="

if [[ -f "$CODEX_TARGET/.codex/config.toml" ]]; then
  if grep -q 'agent-governance' "$CODEX_TARGET/.codex/config.toml"; then
    pass "codex-gen-config: agent-governance presente"
  else
    fail "codex-gen-config: agent-governance ausente"
  fi

  if grep -q 'go-implementation' "$CODEX_TARGET/.codex/config.toml"; then
    pass "codex-gen-config: go-implementation presente"
  else
    fail "codex-gen-config: go-implementation ausente"
  fi
fi

# ========== 6. Perfil lean ==========
echo "=== Perfil lean ==="

CODEX_LEAN_TARGET="$tmpdir/codex-lean-project"
mkdir -p "$CODEX_LEAN_TARGET"
echo "module example.com/codex-lean" > "$CODEX_LEAN_TARGET/go.mod"
echo "go 1.23" >> "$CODEX_LEAN_TARGET/go.mod"

CODEX_SKILL_PROFILE=lean bash "$INSTALL_SCRIPT" --tools codex --langs go "$CODEX_LEAN_TARGET" > /dev/null 2>&1

if [[ -f "$CODEX_LEAN_TARGET/.codex/config.toml" ]]; then
  lean_skills="$(grep -c 'enabled = true' "$CODEX_LEAN_TARGET/.codex/config.toml" || true)"
  if [[ "$lean_skills" -le 7 ]]; then
    pass "codex-lean: perfil lean com $lean_skills skills (<= 7)"
  else
    fail "codex-lean: perfil lean com $lean_skills skills (esperado <= 7)"
  fi
else
  fail "codex-lean: config.toml ausente no perfil lean"
fi

# ========== 7. Workflow spec-driven: skills core presentes ==========
echo "=== Workflow spec-driven ==="

if [[ -f "$CODEX_TARGET/.codex/config.toml" ]]; then
  for core in execute-task review bugfix; do
    if grep -q "$core" "$CODEX_TARGET/.codex/config.toml"; then
      pass "codex-workflow: skill $core presente no config"
    else
      fail "codex-workflow: skill $core ausente no config"
    fi
  done
fi

# ========== Resumo ==========
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"
if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
