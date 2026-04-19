#!/usr/bin/env bash
# Testes para upgrade.sh.
# Uso: bash tests/test-upgrade.sh

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
UPGRADE_SCRIPT="$ROOT_DIR/upgrade.sh"
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
# Setup: instalar governanca em projeto temporario (modo copy)
# ============================================================
PROJECT="$TMP_DIR/upgrade-project"
mkdir -p "$PROJECT"
echo "module upgrade-test" > "$PROJECT/go.mod"

LINK_MODE=copy bash "$INSTALL_SCRIPT" --tools claude,gemini --langs all "$PROJECT" > /dev/null 2>&1

if [[ ! -f "$PROJECT/AGENTS.md" ]]; then
  echo "ERRO: setup falhou — AGENTS.md nao gerado"
  exit 1
fi

# ============================================================
# Caso 1: skills atualizadas — check retorna 0
# ============================================================
if bash "$UPGRADE_SCRIPT" --check "$PROJECT" > /dev/null 2>&1; then
  pass "up-to-date: --check retorna 0"
else
  fail "up-to-date: --check retorna erro inesperado"
fi

# ============================================================
# Caso 1b: skill opcional instalada continua sob gestao do upgrade
# ============================================================
mkdir -p "$PROJECT/.agents/skills/semantic-commit"
cp -R "$ROOT_DIR/.agents/skills/semantic-commit/." "$PROJECT/.agents/skills/semantic-commit/"
echo "# modificado" >> "$PROJECT/.agents/skills/semantic-commit/SKILL.md"

output="$(bash "$UPGRADE_SCRIPT" --check "$PROJECT" 2>&1 || true)"
if echo "$output" | grep -qi "CONTEUDO DIVERGENTE.*semantic-commit"; then
  pass "optional-installed: --check detecta skill opcional instalada e divergente"
else
  fail "optional-installed: --check nao gerencia skill opcional instalada"
fi

bash "$UPGRADE_SCRIPT" "$PROJECT" > /dev/null 2>&1

# ============================================================
# Caso 2: conteudo divergente detectado
# ============================================================
echo "# modificado" >> "$PROJECT/.agents/skills/agent-governance/SKILL.md"

output="$(bash "$UPGRADE_SCRIPT" --check "$PROJECT" 2>&1 || true)"
if echo "$output" | grep -qi "DIVERGENTE\|DESATUALIZADA"; then
  pass "divergent: --check detecta divergencia"
else
  fail "divergent: --check nao detecta divergencia"
fi

# ============================================================
# Caso 3: upgrade corrige divergencia
# ============================================================
bash "$UPGRADE_SCRIPT" "$PROJECT" > /dev/null 2>&1

# Apos upgrade, checar deve passar
if bash "$UPGRADE_SCRIPT" --check "$PROJECT" > /dev/null 2>&1; then
  pass "upgrade-fix: divergencia corrigida"
else
  fail "upgrade-fix: divergencia persiste apos upgrade"
fi

# ============================================================
# Caso 4: skill ausente detectada
# ============================================================
rm -rf "$PROJECT/.agents/skills/review"

output="$(bash "$UPGRADE_SCRIPT" --check "$PROJECT" 2>&1 || true)"
if echo "$output" | grep -qi "AUSENTE.*review"; then
  pass "missing-skill: skill ausente detectada"
else
  fail "missing-skill: skill ausente nao detectada"
fi

# ============================================================
# Caso 5: symlink detectado (pula copia)
# ============================================================
SYMLINK_PROJECT="$TMP_DIR/symlink-project"
mkdir -p "$SYMLINK_PROJECT"
echo "module symlink-test" > "$SYMLINK_PROJECT/go.mod"

# Instalar com symlinks (default)
bash "$INSTALL_SCRIPT" --tools claude --langs all "$SYMLINK_PROJECT" > /dev/null 2>&1

# Forcar divergencia artificial no source nao e possivel sem alterar o repo,
# mas podemos verificar que --check nao falha em projeto com symlinks
if bash "$UPGRADE_SCRIPT" --check "$SYMLINK_PROJECT" > /dev/null 2>&1; then
  pass "symlink: --check passa em projeto com symlinks"
else
  fail "symlink: --check falha em projeto com symlinks"
fi

# ============================================================
# Caso 6: ref explicita atualiza a partir do tag solicitado
# ============================================================
REF_REPO="$TMP_DIR/ref-upgrade-repo"
create_ref_fixture_repo "$REF_REPO"

REF_PROJECT="$TMP_DIR/ref-upgrade-project"
mkdir -p "$REF_PROJECT"
echo "module ref-upgrade" > "$REF_PROJECT/go.mod"

GENERATE_CONTEXTUAL_GOVERNANCE=0 LINK_MODE=copy bash "$REF_REPO/install.sh" --tools codex --langs go "$REF_PROJECT" > /dev/null 2>&1

initial_ref_version="$(awk '/^---$/{n++; next} n==1 && /^version:/{print $2; exit}' "$REF_PROJECT/.agents/skills/agent-governance/SKILL.md")"
if [[ "$initial_ref_version" == "1.0.2" ]]; then
  pass "explicit-ref-upgrade: setup instalou HEAD atual"
else
  fail "explicit-ref-upgrade: setup nao instalou HEAD esperado ($initial_ref_version)"
fi

ref_upgrade_output="$(bash "$REF_REPO/upgrade.sh" --ref v1.0.1-test "$REF_PROJECT" 2>&1)"
upgraded_ref_version="$(awk '/^---$/{n++; next} n==1 && /^version:/{print $2; exit}' "$REF_PROJECT/.agents/skills/agent-governance/SKILL.md")"
if [[ "$upgraded_ref_version" == "1.0.1" ]]; then
  pass "explicit-ref-upgrade: restaurou snapshot do tag solicitado"
else
  fail "explicit-ref-upgrade: nao aplicou conteudo do tag solicitado ($upgraded_ref_version)"
fi

if echo "$ref_upgrade_output" | grep -q 'Fonte: ref explicita: v1.0.1-test'; then
  pass "explicit-ref-upgrade: log exibe ref utilizada"
else
  fail "explicit-ref-upgrade: log nao exibe ref utilizada"
fi

# ============================================================
# Caso 7: ref invalida falha com mensagem clara
# ============================================================
invalid_ref_output="$(bash "$REF_REPO/upgrade.sh" --ref ref-inexistente "$REF_PROJECT" 2>&1 || true)"
if echo "$invalid_ref_output" | grep -q 'ERRO: ref/tag invalida ou inexistente: ref-inexistente'; then
  pass "invalid-ref-upgrade: ref invalida reportada com clareza"
else
  fail "invalid-ref-upgrade: mensagem de erro insuficiente para ref invalida"
fi

if bash "$REF_REPO/upgrade.sh" --ref v1.0.1-test "$REF_REPO" > /dev/null 2>&1; then
  fail "self-upgrade-ref: aceito com ref explicita"
else
  pass "self-upgrade-ref: rejeitado mesmo com ref explicita"
fi

# ============================================================
# Caso 8: diretorio inexistente
# ============================================================
if bash "$UPGRADE_SCRIPT" "$TMP_DIR/nonexistent" > /dev/null 2>&1; then
  fail "nonexistent-dir: aceito sem erro"
else
  pass "nonexistent-dir: rejeitado com erro"
fi

# ============================================================
# Caso 9: diretorio sem governanca instalada
# ============================================================
EMPTY_PROJECT="$TMP_DIR/empty-project"
mkdir -p "$EMPTY_PROJECT"

if bash "$UPGRADE_SCRIPT" "$EMPTY_PROJECT" > /dev/null 2>&1; then
  fail "no-governance: aceito sem erro"
else
  pass "no-governance: rejeitado com erro"
fi

# ============================================================
# Caso 10: diretorio alvo igual ao repo fonte
# ============================================================
if bash "$UPGRADE_SCRIPT" "$ROOT_DIR" > /dev/null 2>&1; then
  fail "self-upgrade: aceito sem erro"
else
  pass "self-upgrade: rejeitado com erro"
fi

# ============================================================
# Caso 11: adaptadores atualizados durante upgrade
# ============================================================
ADAPTER_PROJECT="$TMP_DIR/adapter-project"
mkdir -p "$ADAPTER_PROJECT"
echo "module adapter-test" > "$ADAPTER_PROJECT/go.mod"

LINK_MODE=copy bash "$INSTALL_SCRIPT" --tools claude,gemini --langs all "$ADAPTER_PROJECT" > /dev/null 2>&1

# Modificar um adapter e uma skill para forcar upgrade
echo "# modificado" >> "$ADAPTER_PROJECT/.agents/skills/agent-governance/SKILL.md"
echo "# old" >> "$ADAPTER_PROJECT/.claude/agents/reviewer.md"

output="$(bash "$UPGRADE_SCRIPT" "$ADAPTER_PROJECT" 2>&1)"
if echo "$output" | grep -qi "Adaptadores atualizados"; then
  pass "adapter-upgrade: adaptadores atualizados durante upgrade"
else
  fail "adapter-upgrade: adaptadores nao atualizados"
fi

# Verificar que o adapter foi restaurado
if diff -q "$ROOT_DIR/.claude/agents/reviewer.md" "$ADAPTER_PROJECT/.claude/agents/reviewer.md" > /dev/null 2>&1; then
  pass "adapter-upgrade: reviewer.md restaurado ao conteudo fonte"
else
  fail "adapter-upgrade: reviewer.md nao restaurado"
fi

# ============================================================
# Caso 12: Codex config regenerado durante upgrade
# ============================================================
CODEX_PROJECT="$TMP_DIR/codex-project"
mkdir -p "$CODEX_PROJECT"
echo "module codex-test" > "$CODEX_PROJECT/go.mod"

LINK_MODE=copy bash "$INSTALL_SCRIPT" --tools codex --langs go "$CODEX_PROJECT" > /dev/null 2>&1

# Corromper o config do Codex e forcar divergencia em uma skill
echo "# stale config" > "$CODEX_PROJECT/.codex/config.toml"
echo "# modificado" >> "$CODEX_PROJECT/.agents/skills/agent-governance/SKILL.md"

bash "$UPGRADE_SCRIPT" "$CODEX_PROJECT" > /dev/null 2>&1

if grep -q '".agents/skills/go-implementation"' "$CODEX_PROJECT/.codex/config.toml"; then
  pass "codex-upgrade: config regenerado com skill Go"
else
  fail "codex-upgrade: config nao regenerado"
fi

if grep -q '# stale config' "$CODEX_PROJECT/.codex/config.toml"; then
  fail "codex-upgrade: config antigo nao substituido"
else
  pass "codex-upgrade: config antigo substituido"
fi

# ============================================================
# Caso 13: schema version bump detectado e regenerado
# ============================================================
SCHEMA_PROJECT="$TMP_DIR/schema-project"
mkdir -p "$SCHEMA_PROJECT"
echo "module schema-test" > "$SCHEMA_PROJECT/go.mod"

LINK_MODE=copy bash "$INSTALL_SCRIPT" --tools claude --langs go "$SCHEMA_PROJECT" > /dev/null 2>&1

# Verificar que AGENTS.md tem schema version 1.0.0
if grep -q 'governance-schema: 1.0.0' "$SCHEMA_PROJECT/AGENTS.md" 2>/dev/null; then
  pass "schema-bump: AGENTS.md contém schema 1.0.0 apos install"
else
  fail "schema-bump: schema version ausente apos install"
fi

# Simular versao antiga no AGENTS.md do projeto (como se tivesse sido instalado com versao anterior)
sed 's/governance-schema: 1.0.0/governance-schema: 0.9.0/' "$SCHEMA_PROJECT/AGENTS.md" > "$SCHEMA_PROJECT/AGENTS.md.tmp"
mv "$SCHEMA_PROJECT/AGENTS.md.tmp" "$SCHEMA_PROJECT/AGENTS.md"

if grep -q 'governance-schema: 0.9.0' "$SCHEMA_PROJECT/AGENTS.md"; then
  pass "schema-bump: AGENTS.md downgraded para 0.9.0"
else
  fail "schema-bump: falha ao simular downgrade"
fi

# Rodar upgrade — deve regenerar AGENTS.md com schema atualizado
bash "$UPGRADE_SCRIPT" "$SCHEMA_PROJECT" > /dev/null 2>&1

if grep -q 'governance-schema: 1.0.0' "$SCHEMA_PROJECT/AGENTS.md" 2>/dev/null; then
  pass "schema-bump: AGENTS.md atualizado para 1.0.0 apos upgrade"
else
  fail "schema-bump: schema version nao atualizado apos upgrade"
fi

# Verificar que o AGENTS.md nao tem placeholders remanescentes apos upgrade
if grep -q '{{' "$SCHEMA_PROJECT/AGENTS.md" 2>/dev/null; then
  fail "schema-bump: placeholders remanescentes apos upgrade"
else
  pass "schema-bump: sem placeholders apos upgrade"
fi

# ============================================================
# Caso 14: cross-version upgrade preserva personalizacao local
# ============================================================
CUSTOM_PROJECT="$TMP_DIR/custom-project"
mkdir -p "$CUSTOM_PROJECT"
echo "module custom-test" > "$CUSTOM_PROJECT/go.mod"

LINK_MODE=copy bash "$INSTALL_SCRIPT" --tools claude,gemini --langs go "$CUSTOM_PROJECT" > /dev/null 2>&1

# Simular personalizacao local: usuario editou settings.local.json com permissoes extras
original_settings="$(cat "$CUSTOM_PROJECT/.claude/settings.local.json")"
python3 -c "
import json, sys
with open('$CUSTOM_PROJECT/.claude/settings.local.json') as f:
    data = json.load(f)
data.setdefault('permissions', {}).setdefault('allow', []).append('Bash(make:*)')
with open('$CUSTOM_PROJECT/.claude/settings.local.json', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null

custom_settings="$(cat "$CUSTOM_PROJECT/.claude/settings.local.json")"

# Simular schema antigo para forcar upgrade
sed 's/governance-schema: 1.0.0/governance-schema: 0.8.0/' "$CUSTOM_PROJECT/AGENTS.md" > "$CUSTOM_PROJECT/AGENTS.md.tmp"
mv "$CUSTOM_PROJECT/AGENTS.md.tmp" "$CUSTOM_PROJECT/AGENTS.md"

# Forcar divergencia em skill para triggerar upgrade
echo "# modificado" >> "$CUSTOM_PROJECT/.agents/skills/agent-governance/SKILL.md"

# Rodar upgrade
bash "$UPGRADE_SCRIPT" "$CUSTOM_PROJECT" > /dev/null 2>&1

# Verificar que settings.local.json preservou a personalizacao (upgrade nao sobrescreve)
if grep -q 'make' "$CUSTOM_PROJECT/.claude/settings.local.json" 2>/dev/null; then
  pass "cross-version: settings.local.json preservou personalizacao"
else
  fail "cross-version: settings.local.json perdeu personalizacao"
fi

# Verificar que hooks continuam presentes
if grep -q 'validate-governance' "$CUSTOM_PROJECT/.claude/settings.local.json" 2>/dev/null; then
  pass "cross-version: hooks preservados em settings"
else
  fail "cross-version: hooks perdidos apos upgrade"
fi

# Verificar que AGENTS.md foi regenerado com schema atualizado
if grep -q 'governance-schema: 1.0.0' "$CUSTOM_PROJECT/AGENTS.md" 2>/dev/null; then
  pass "cross-version: AGENTS.md atualizado para schema 1.0.0"
else
  fail "cross-version: AGENTS.md nao atualizado"
fi

# Verificar que skills foram restauradas
if ! grep -q '# modificado' "$CUSTOM_PROJECT/.agents/skills/agent-governance/SKILL.md" 2>/dev/null; then
  pass "cross-version: skill agent-governance restaurada"
else
  fail "cross-version: skill agent-governance nao restaurada"
fi

# ============================================================
# Caso 15: cross-tool upgrade — codex-only → codex+claude
# ============================================================
CROSS_CODEX="$TMP_DIR/cross-codex-project"
mkdir -p "$CROSS_CODEX"
echo "module cross-codex" > "$CROSS_CODEX/go.mod"

# Instalar apenas codex
LINK_MODE=copy bash "$INSTALL_SCRIPT" --tools codex --langs go "$CROSS_CODEX" > /dev/null 2>&1

if [[ -f "$CROSS_CODEX/.codex/config.toml" ]] && [[ ! -d "$CROSS_CODEX/.claude" ]]; then
  pass "cross-tool-codex: instalacao inicial apenas codex"
else
  fail "cross-tool-codex: estado inicial inesperado"
fi

# Agora instalar claude no mesmo projeto
LINK_MODE=copy bash "$INSTALL_SCRIPT" --tools claude --langs go "$CROSS_CODEX" > /dev/null 2>&1

if [[ -f "$CROSS_CODEX/.claude/hooks/validate-governance.sh" ]]; then
  pass "cross-tool-codex: claude adicionado com hooks"
else
  fail "cross-tool-codex: claude nao adicionado"
fi

if [[ -f "$CROSS_CODEX/.codex/config.toml" ]]; then
  pass "cross-tool-codex: codex preservado apos adicionar claude"
else
  fail "cross-tool-codex: codex perdido apos adicionar claude"
fi

# ============================================================
# Caso 16: cross-tool upgrade — copilot-only → copilot+gemini
# ============================================================
CROSS_COPILOT="$TMP_DIR/cross-copilot-project"
mkdir -p "$CROSS_COPILOT"
echo "module cross-copilot" > "$CROSS_COPILOT/go.mod"

# Instalar apenas copilot
LINK_MODE=copy bash "$INSTALL_SCRIPT" --tools copilot --langs go "$CROSS_COPILOT" > /dev/null 2>&1

if [[ -d "$CROSS_COPILOT/.github/agents" ]] && [[ ! -d "$CROSS_COPILOT/.gemini" ]]; then
  pass "cross-tool-copilot: instalacao inicial apenas copilot"
else
  fail "cross-tool-copilot: estado inicial inesperado"
fi

# Agora instalar gemini no mesmo projeto
LINK_MODE=copy bash "$INSTALL_SCRIPT" --tools gemini --langs go "$CROSS_COPILOT" > /dev/null 2>&1

if [[ -d "$CROSS_COPILOT/.gemini/commands" ]]; then
  pass "cross-tool-copilot: gemini adicionado com commands"
else
  fail "cross-tool-copilot: gemini nao adicionado"
fi

if [[ -d "$CROSS_COPILOT/.github/agents" ]]; then
  pass "cross-tool-copilot: copilot preservado apos adicionar gemini"
else
  fail "cross-tool-copilot: copilot perdido apos adicionar gemini"
fi

# ============================================================
# Resumo
# ============================================================
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
