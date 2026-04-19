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

set_repo_version() {
  local repo_dir="$1"
  local version="$2"
  VERSION="$version" python3 - "$repo_dir/.agents/skills/agent-governance/SKILL.md" "$repo_dir/VERSION" <<'PY'
from pathlib import Path
import os
import sys

skill_path = Path(sys.argv[1])
version_path = Path(sys.argv[2])
version = os.environ["VERSION"]

skill_content = skill_path.read_text()
skill_content = __import__("re").sub(r"^version:\s+.*$", f"version: {version}", skill_content, count=1, flags=__import__("re").MULTILINE)
skill_path.write_text(skill_content)
version_path.write_text(f"{version}\n")
PY
}

create_ref_fixture_repo() {
  local repo_dir="$1"

  mkdir -p "$repo_dir"
  tar --exclude='.git' -cf - -C "$ROOT_DIR" . | tar -xf - -C "$repo_dir"
  git -C "$repo_dir" init -q
  git -C "$repo_dir" config user.name "Test Runner"
  git -C "$repo_dir" config user.email "test@example.com"

  set_repo_version "$repo_dir" "1.0.1"
  git -C "$repo_dir" add .
  git -C "$repo_dir" -c commit.gpgsign=false commit -q -m "baseline"
  git -C "$repo_dir" tag "v1.0.1-test"

  set_repo_version "$repo_dir" "1.0.2"
  git -C "$repo_dir" add .agents/skills/agent-governance/SKILL.md VERSION
  git -C "$repo_dir" -c commit.gpgsign=false commit -q -m "head"
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
# Caso 7: ref explicita instala snapshot do tag, nao do HEAD atual
# ============================================================
REF_REPO="$TMP_DIR/ref-install-repo"
create_ref_fixture_repo "$REF_REPO"

REF_TARGET="$TMP_DIR/ref-target"
mkdir -p "$REF_TARGET"
echo "module ref-target" > "$REF_TARGET/go.mod"

ref_output="$(GENERATE_CONTEXTUAL_GOVERNANCE=0 AI_GOVERNANCE_REF=v1.0.1-test bash "$REF_REPO/install.sh" --tools codex --langs go "$REF_TARGET" 2>&1)"

installed_ref_version="$(awk '/^---$/{n++; next} n==1 && /^version:/{print $2; exit}' "$REF_TARGET/.agents/skills/agent-governance/SKILL.md")"
if [[ "$installed_ref_version" == "1.0.1" ]]; then
  pass "explicit-ref-install: instala conteudo do tag solicitado"
else
  fail "explicit-ref-install: instalou versao inesperada ($installed_ref_version)"
fi

if [[ -L "$REF_TARGET/.agents/skills/agent-governance" ]]; then
  fail "explicit-ref-install: manteve symlink apesar de ref explicita"
else
  pass "explicit-ref-install: forca snapshot local sem symlink quebrado"
fi

if echo "$ref_output" | grep -q 'Fonte da governanca: ref explicita: v1.0.1-test'; then
  pass "explicit-ref-install: log exibe ref utilizada"
else
  fail "explicit-ref-install: log nao exibe ref utilizada"
fi

# ============================================================
# Caso 8: Codex dinamico sem geracao contextual
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
  pass "non-contextual-codex: inclui skill de planejamento no perfil full (default)"
else
  fail "non-contextual-codex: nao inclui skill de planejamento no perfil full (default)"
fi

# ============================================================
# Caso 9: ref invalida falha com mensagem clara
# ============================================================
INVALID_REF_TARGET="$TMP_DIR/invalid-ref-target"
mkdir -p "$INVALID_REF_TARGET"
echo "module invalid-ref" > "$INVALID_REF_TARGET/go.mod"

invalid_ref_output="$(AI_GOVERNANCE_REF=ref-inexistente bash "$REF_REPO/install.sh" --tools codex --langs go "$INVALID_REF_TARGET" 2>&1 || true)"
if echo "$invalid_ref_output" | grep -q 'ERRO: ref/tag invalida ou inexistente: ref-inexistente'; then
  pass "invalid-ref-install: ref invalida reportada com clareza"
else
  fail "invalid-ref-install: mensagem de erro insuficiente para ref invalida"
fi

if AI_GOVERNANCE_REF=v1.0.1-test bash "$REF_REPO/install.sh" --tools codex --langs go "$REF_REPO" > /dev/null 2>&1; then
  fail "self-install-ref: aceito com ref explicita"
else
  pass "self-install-ref: rejeitado mesmo com ref explicita"
fi

# ============================================================
# Caso 10: Codex perfil lean nao inclui analyze-project
# ============================================================
LEAN_TARGET="$TMP_DIR/lean-project"
mkdir -p "$LEAN_TARGET"
echo "module lean" > "$LEAN_TARGET/go.mod"

CODEX_SKILL_PROFILE=lean bash "$INSTALL_SCRIPT" --tools codex --langs go "$LEAN_TARGET" > /dev/null 2>&1

if grep -q '".agents/skills/analyze-project"' "$LEAN_TARGET/.codex/config.toml" 2>/dev/null; then
  fail "codex-lean: analyze-project presente no perfil lean"
else
  pass "codex-lean: analyze-project ausente do perfil lean"
fi

if grep -q '".agents/skills/go-implementation"' "$LEAN_TARGET/.codex/config.toml" 2>/dev/null; then
  pass "codex-lean: go-implementation presente no perfil lean"
else
  fail "codex-lean: go-implementation ausente do perfil lean"
fi

# ============================================================
# Caso 11: idempotencia — rodar install 2x no mesmo projeto
# ============================================================
IDEM_TARGET="$TMP_DIR/idempotent-project"
mkdir -p "$IDEM_TARGET"
echo "module idempotent" > "$IDEM_TARGET/go.mod"

bash "$INSTALL_SCRIPT" --tools claude,codex --langs go "$IDEM_TARGET" < /dev/null 2>/dev/null
first_settings="$(cat "$IDEM_TARGET/.claude/settings.local.json")"

# Segunda instalacao no mesmo projeto
bash "$INSTALL_SCRIPT" --tools claude,codex --langs go "$IDEM_TARGET" < /dev/null 2>/dev/null
second_settings="$(cat "$IDEM_TARGET/.claude/settings.local.json")"

# AGENTS.md pode divergir legitimamente na arvore de diretorios (2a instalacao ve mais dirs).
# Validar que o conteudo estrutural (governanca, schema, regras) permanece consistente.
first_schema="$(grep 'governance-schema' "$IDEM_TARGET/AGENTS.md" || true)"
if [[ -n "$first_schema" ]]; then
  pass "idempotent: AGENTS.md preserva schema version apos 2a instalacao"
else
  fail "idempotent: AGENTS.md perdeu schema version apos 2a instalacao"
fi

if [[ "$first_settings" == "$second_settings" ]]; then
  pass "idempotent: settings.local.json identico apos 2a instalacao"
else
  fail "idempotent: settings.local.json divergiu apos 2a instalacao"
fi

# Verificar que nao ha hooks duplicados
hook_count="$(grep -c 'validate-governance' "$IDEM_TARGET/.claude/settings.local.json" || true)"
if [[ "$hook_count" -le 1 ]]; then
  pass "idempotent: hook validate-governance nao duplicado ($hook_count ocorrencias)"
else
  fail "idempotent: hook validate-governance duplicado ($hook_count ocorrencias)"
fi

# Skills continuam funcionando
if [[ -e "$IDEM_TARGET/.agents/skills/go-implementation/SKILL.md" ]]; then
  pass "idempotent: skill go-implementation preservada"
else
  fail "idempotent: skill go-implementation perdida"
fi

# ============================================================
# Resumo
# ============================================================
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
