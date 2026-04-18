#!/usr/bin/env bash
# Testes end-to-end para install.sh.
# Uso: bash tests/test-install.sh

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
INSTALL_SCRIPT="$ROOT_DIR/install.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

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

# ============================================================
# Caso 1: dry-run nao cria arquivos
# ============================================================
DRY_TARGET="$TMP_DIR/dry-run-project"
mkdir -p "$DRY_TARGET"
echo "module dry-run" > "$DRY_TARGET/go.mod"

output="$(echo "A" | echo "1" | bash "$INSTALL_SCRIPT" --dry-run "$DRY_TARGET" 2>&1 <<EOF
A
1
EOF
)" || true

if [[ ! -f "$DRY_TARGET/AGENTS.md" ]]; then
  pass "dry-run: AGENTS.md nao criado"
else
  fail "dry-run: AGENTS.md criado indevidamente"
fi

if [[ ! -d "$DRY_TARGET/.claude" ]]; then
  pass "dry-run: .claude/ nao criado"
else
  fail "dry-run: .claude/ criado indevidamente"
fi

# ============================================================
# Caso 2: instalacao completa com todas as ferramentas e Go
# ============================================================
FULL_TARGET="$TMP_DIR/full-project"
mkdir -p "$FULL_TARGET"
echo "module full" > "$FULL_TARGET/go.mod"

bash "$INSTALL_SCRIPT" "$FULL_TARGET" 2>/dev/null <<EOF
A
1
EOF

# AGENTS.md gerado
if [[ -f "$FULL_TARGET/AGENTS.md" ]]; then
  pass "full-install: AGENTS.md gerado"
else
  fail "full-install: AGENTS.md ausente"
fi

# Claude Code instalado
if [[ -d "$FULL_TARGET/.claude/skills" ]]; then
  pass "full-install: .claude/skills criado"
else
  fail "full-install: .claude/skills ausente"
fi

if [[ -f "$FULL_TARGET/CLAUDE.md" ]]; then
  pass "full-install: CLAUDE.md gerado"
else
  fail "full-install: CLAUDE.md ausente"
fi

# Gemini instalado
if [[ -d "$FULL_TARGET/.gemini/commands" ]]; then
  pass "full-install: .gemini/commands criado"
else
  fail "full-install: .gemini/commands ausente"
fi

if [[ -f "$FULL_TARGET/GEMINI.md" ]]; then
  pass "full-install: GEMINI.md gerado"
else
  fail "full-install: GEMINI.md ausente"
fi

# Codex instalado
if [[ -f "$FULL_TARGET/.codex/config.toml" ]]; then
  pass "full-install: .codex/config.toml criado"
else
  fail "full-install: .codex/config.toml ausente"
fi

# Copilot instalado
if [[ -d "$FULL_TARGET/.github/agents" ]]; then
  pass "full-install: .github/agents criado"
else
  fail "full-install: .github/agents ausente"
fi

if [[ -d "$FULL_TARGET/.github/skills" ]]; then
  pass "full-install: .github/skills criado"
else
  fail "full-install: .github/skills ausente"
fi

if [[ -e "$FULL_TARGET/.github/skills/agent-governance/SKILL.md" ]]; then
  pass "full-install: .github/skills/agent-governance presente"
else
  fail "full-install: .github/skills/agent-governance ausente"
fi

# Skill canonica presente
if [[ -e "$FULL_TARGET/.agents/skills/agent-governance/SKILL.md" ]]; then
  pass "full-install: skill agent-governance presente"
else
  fail "full-install: skill agent-governance ausente"
fi

# Skill Go presente
if [[ -e "$FULL_TARGET/.agents/skills/go-implementation/SKILL.md" ]]; then
  pass "full-install: skill go-implementation presente"
else
  fail "full-install: skill go-implementation ausente"
fi

# ============================================================
# Caso 3: instalacao parcial (apenas Claude + Node)
# ============================================================
PARTIAL_TARGET="$TMP_DIR/partial-project"
mkdir -p "$PARTIAL_TARGET"
echo '{"name":"partial"}' > "$PARTIAL_TARGET/package.json"

bash "$INSTALL_SCRIPT" "$PARTIAL_TARGET" 2>/dev/null <<EOF
1
2
EOF

if [[ -f "$PARTIAL_TARGET/CLAUDE.md" ]]; then
  pass "partial-install: CLAUDE.md gerado"
else
  fail "partial-install: CLAUDE.md ausente"
fi

if [[ ! -f "$PARTIAL_TARGET/GEMINI.md" ]]; then
  pass "partial-install: GEMINI.md nao gerado (correto)"
else
  fail "partial-install: GEMINI.md criado indevidamente"
fi

if [[ -e "$PARTIAL_TARGET/.agents/skills/node-implementation/SKILL.md" ]]; then
  pass "partial-install: skill node-implementation presente"
else
  fail "partial-install: skill node-implementation ausente"
fi

# ============================================================
# Caso 4: diretorio inexistente
# ============================================================
if bash "$INSTALL_SCRIPT" "$TMP_DIR/nonexistent" > /dev/null 2>&1 <<EOF
A
1
EOF
then
  fail "nonexistent-dir: aceito sem erro"
else
  pass "nonexistent-dir: rejeitado com erro"
fi

# ============================================================
# Caso 5: diretorio alvo igual ao repositorio de regras
# ============================================================
if bash "$INSTALL_SCRIPT" "$ROOT_DIR" > /dev/null 2>&1 <<EOF
A
1
EOF
then
  fail "self-install: aceito sem erro"
else
  pass "self-install: rejeitado com erro"
fi

# ============================================================
# Caso 6: modo copy (sem symlinks)
# ============================================================
COPY_TARGET="$TMP_DIR/copy-project"
mkdir -p "$COPY_TARGET"
echo "module copy" > "$COPY_TARGET/go.mod"

LINK_MODE=copy bash "$INSTALL_SCRIPT" "$COPY_TARGET" 2>/dev/null <<EOF
1
1
EOF

if [[ -d "$COPY_TARGET/.agents/skills/agent-governance" ]] && [[ ! -L "$COPY_TARGET/.agents/skills/agent-governance" ]]; then
  pass "copy-mode: agent-governance e diretorio (nao symlink)"
else
  fail "copy-mode: agent-governance e symlink ou ausente"
fi

# ============================================================
# Caso 7: Codex dinamico sem geracao contextual
# ============================================================
NON_CONTEXTUAL_TARGET="$TMP_DIR/non-contextual-project"
mkdir -p "$NON_CONTEXTUAL_TARGET"
echo '{"name":"non-contextual"}' > "$NON_CONTEXTUAL_TARGET/package.json"

GENERATE_CONTEXTUAL_GOVERNANCE=0 bash "$INSTALL_SCRIPT" --tools codex --langs node "$NON_CONTEXTUAL_TARGET" > /dev/null 2>&1

if grep -q '".agents/skills/node-implementation"' "$NON_CONTEXTUAL_TARGET/.codex/config.toml"; then
  pass "non-contextual-codex: inclui skill Node selecionada"
else
  fail "non-contextual-codex: nao inclui skill Node selecionada"
fi

if grep -q '".agents/skills/go-implementation"' "$NON_CONTEXTUAL_TARGET/.codex/config.toml"; then
  fail "non-contextual-codex: inclui skill Go indevida"
else
  pass "non-contextual-codex: nao inclui skill Go indevida"
fi

if grep -q '".agents/skills/analyze-project"' "$NON_CONTEXTUAL_TARGET/.codex/config.toml"; then
  fail "non-contextual-codex: inclui skill pesada fora do perfil minimal"
else
  pass "non-contextual-codex: nao inclui skill pesada fora do perfil minimal"
fi

# ============================================================
# Resumo
# ============================================================
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
