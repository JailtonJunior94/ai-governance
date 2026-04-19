#!/usr/bin/env bash
# Teste E2E: install → generate → hook → validate.
# Simula o fluxo completo de instalacao de governanca em um projeto temporario.

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

# Criar projeto temporario
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/project"
cat > "$tmpdir/project/go.mod" <<'EOF'
module github.com/example/e2e-test

go 1.22
EOF

# ========== ETAPA 1: Install ==========
echo "=== Etapa 1: Install ==="
if bash "$ROOT_DIR/install.sh" --tools claude,codex --langs go "$tmpdir/project" < /dev/null 2>/dev/null; then
  pass "install: concluiu sem erro"
else
  fail "install: falhou"
fi

# Verificar arquivos criados
for f in AGENTS.md CLAUDE.md .agents/skills/agent-governance/SKILL.md .agents/skills/go-implementation/SKILL.md .claude/hooks/validate-governance.sh .claude/hooks/validate-preload.sh .codex/config.toml; do
  if [[ -e "$tmpdir/project/$f" ]]; then
    pass "install-file: $f"
  else
    fail "install-file: $f ausente"
  fi
done

# ========== ETAPA 2: Generate (governanca contextual) ==========
echo "=== Etapa 2: Governance gerada ==="
if grep -q 'governance-schema' "$tmpdir/project/AGENTS.md" 2>/dev/null; then
  pass "generate: schema version presente em AGENTS.md"
else
  fail "generate: schema version ausente em AGENTS.md"
fi

if grep -q 'Go' "$tmpdir/project/AGENTS.md" 2>/dev/null; then
  pass "generate: stack Go detectada em AGENTS.md"
else
  fail "generate: stack Go nao detectada"
fi

# Verificar que AGENTS.md nao tem placeholders remanescentes
if grep -q '{{' "$tmpdir/project/AGENTS.md" 2>/dev/null; then
  fail "generate: placeholders {{ }} remanescentes em AGENTS.md"
else
  pass "generate: sem placeholders remanescentes"
fi

# ========== ETAPA 3: Hook validate-governance ==========
echo "=== Etapa 3: Hook validate-governance ==="

# Simular edicao de arquivo de governanca
hook_output="$(echo '{"tool_input":{"file_path":"'"$tmpdir/project/.agents/skills/agent-governance/SKILL.md"'"}}' | bash "$tmpdir/project/.claude/hooks/validate-governance.sh" 2>&1 || true)"
if echo "$hook_output" | grep -q "AVISO.*governanca"; then
  pass "hook-governance: alerta emitido para arquivo de governanca"
else
  fail "hook-governance: alerta nao emitido para arquivo de governanca"
fi

# Simular edicao de arquivo normal (nao deve alertar)
hook_output_normal="$(echo '{"tool_input":{"file_path":"'"$tmpdir/project/main.go"'"}}' | bash "$tmpdir/project/.claude/hooks/validate-governance.sh" 2>&1 || true)"
if [[ -z "$hook_output_normal" ]]; then
  pass "hook-governance: silencioso para arquivo normal"
else
  fail "hook-governance: emitiu alerta indevido para arquivo normal"
fi

# ========== ETAPA 4: Hook validate-preload ==========
echo "=== Etapa 4: Hook validate-preload ==="

hook_preload="$(echo '{"tool_input":{"file_path":"'"$tmpdir/project/main.go"'"}}' | bash "$tmpdir/project/.claude/hooks/validate-preload.sh" 2>&1 || true)"
if echo "$hook_preload" | grep -q "LEMBRETE"; then
  pass "hook-preload: lembrete emitido para arquivo .go"
else
  fail "hook-preload: lembrete nao emitido para arquivo .go"
fi

# Nao deve emitir para arquivos nao-codigo
hook_preload_md="$(echo '{"tool_input":{"file_path":"'"$tmpdir/project/README.md"'"}}' | bash "$tmpdir/project/.claude/hooks/validate-preload.sh" 2>&1 || true)"
if [[ -z "$hook_preload_md" ]]; then
  pass "hook-preload: silencioso para arquivo .md"
else
  fail "hook-preload: emitiu alerta indevido para arquivo .md"
fi

# ========== ETAPA 3b: Hook validate-governance modo fail ==========
echo "=== Etapa 3b: Hook validate-governance (fail mode) ==="

hook_fail_exit=0
echo '{"tool_input":{"file_path":"'"$tmpdir/project/.agents/skills/agent-governance/SKILL.md"'"}}' | GOVERNANCE_HOOK_MODE=fail bash "$tmpdir/project/.claude/hooks/validate-governance.sh" 2>/dev/null || hook_fail_exit=$?
if [[ "$hook_fail_exit" -ne 0 ]]; then
  pass "hook-governance-fail: exit 1 para arquivo de governanca em modo fail"
else
  fail "hook-governance-fail: exit 0 indevido em modo fail"
fi

# Arquivo normal deve passar mesmo em modo fail
hook_normal_fail=0
echo '{"tool_input":{"file_path":"'"$tmpdir/project/main.go"'"}}' | GOVERNANCE_HOOK_MODE=fail bash "$tmpdir/project/.claude/hooks/validate-governance.sh" 2>/dev/null || hook_normal_fail=$?
if [[ "$hook_normal_fail" -eq 0 ]]; then
  pass "hook-governance-fail: exit 0 para arquivo normal em modo fail"
else
  fail "hook-governance-fail: exit nao-zero indevido para arquivo normal"
fi

# ========== ETAPA 4b: Hook validate-preload modo fail ==========
echo "=== Etapa 4b: Hook validate-preload (fail mode) ==="

hook_preload_fail=0
echo '{"tool_input":{"file_path":"'"$tmpdir/project/main.go"'"}}' | GOVERNANCE_PRELOAD_MODE=fail bash "$tmpdir/project/.claude/hooks/validate-preload.sh" 2>/dev/null || hook_preload_fail=$?
if [[ "$hook_preload_fail" -ne 0 ]]; then
  pass "hook-preload-fail: exit 1 para arquivo .go em modo fail"
else
  fail "hook-preload-fail: exit 0 indevido para .go em modo fail"
fi

# Arquivo nao-codigo deve passar mesmo em modo fail
hook_md_fail=0
echo '{"tool_input":{"file_path":"'"$tmpdir/project/README.md"'"}}' | GOVERNANCE_PRELOAD_MODE=fail bash "$tmpdir/project/.claude/hooks/validate-preload.sh" 2>/dev/null || hook_md_fail=$?
if [[ "$hook_md_fail" -eq 0 ]]; then
  pass "hook-preload-fail: exit 0 para arquivo .md em modo fail"
else
  fail "hook-preload-fail: exit nao-zero indevido para .md"
fi

# ========== ETAPA 5: Validate task evidence ==========
echo "=== Etapa 5: Validate task evidence ==="

# Criar relatorio valido para teste (headings sem acentos para portabilidade de locale)
cat > "$tmpdir/report.md" <<'REPORT'
# Contexto Carregado

PRD: tasks/prd-test/prd.md
TechSpec: tasks/prd-test/techspec.md

# Comandos Executados

go test ./...

# Arquivos Alterados

- internal/order/service.go

# Resultados de Validacao

Testes: pass
Lint: pass
RF-01 validado.

# Suposicoes

Nenhuma.

# Riscos Residuais

Nenhum.

Estado: done

Veredito do Revisor: APPROVED
REPORT

if bash "$ROOT_DIR/.claude/scripts/validate-task-evidence.sh" "$tmpdir/report.md" 2>/dev/null; then
  pass "validate-evidence: relatorio valido aceito"
else
  fail "validate-evidence: relatorio valido rejeitado"
fi

# Relatorio sem requisito ID deve falhar (rastreabilidade PRD→teste)
cat > "$tmpdir/report-bad.md" <<'REPORT_BAD'
# Contexto Carregado

PRD: tasks/prd-test/prd.md
TechSpec: tasks/prd-test/techspec.md

# Comandos Executados

go test ./...

# Arquivos Alterados

- internal/order/service.go

# Resultados de Validacao

Testes: pass
Lint: pass

# Suposicoes

Nenhuma.

# Riscos Residuais

Nenhum.

Estado: done

Veredito do Revisor: APPROVED
REPORT_BAD

if bash "$ROOT_DIR/.claude/scripts/validate-task-evidence.sh" "$tmpdir/report-bad.md" 2>/dev/null; then
  fail "validate-evidence: relatorio sem RF-nn aceito indevidamente"
else
  pass "validate-evidence: relatorio sem RF-nn rejeitado corretamente"
fi

# ========== ETAPA 6: Settings hooks configurados ==========
echo "=== Etapa 6: Settings ==="

if grep -q 'validate-preload' "$tmpdir/project/.claude/settings.local.json" 2>/dev/null; then
  pass "settings: PreToolUse hook configurado"
else
  fail "settings: PreToolUse hook ausente"
fi

if grep -q 'validate-governance' "$tmpdir/project/.claude/settings.local.json" 2>/dev/null; then
  pass "settings: PostToolUse hook configurado"
else
  fail "settings: PostToolUse hook ausente"
fi

echo ""
echo "Resultado: $PASSED passed, $FAILED failed"
if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
