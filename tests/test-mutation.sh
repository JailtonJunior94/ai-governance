#!/usr/bin/env bash
# Mutation testing: viola regras de governanca intencionalmente e verifica
# se hooks e validators detectam a violacao.

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

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# ========== 1. Hook validate-governance detecta edicao em SKILL.md ==========
echo "=== Mutacao: edicao em arquivo de governanca ==="

# Instalar projeto temporario
mkdir -p "$tmpdir/project"
cat > "$tmpdir/project/go.mod" <<'EOF'
module github.com/example/mutation-test
go 1.22
EOF

bash "$ROOT_DIR/install.sh" --tools claude --langs go "$tmpdir/project" < /dev/null 2>/dev/null

# Tentar editar SKILL.md deve ser bloqueado em modo fail
exit_code=0
echo '{"tool_input":{"file_path":"'"$tmpdir/project/.agents/skills/agent-governance/SKILL.md"'"}}' \
  | GOVERNANCE_HOOK_MODE=fail bash "$tmpdir/project/.claude/hooks/validate-governance.sh" 2>/dev/null || exit_code=$?

if [[ "$exit_code" -ne 0 ]]; then
  pass "mutation-governance: hook bloqueou edicao em SKILL.md (exit $exit_code)"
else
  fail "mutation-governance: hook NAO bloqueou edicao em SKILL.md"
fi

# Tentar editar AGENTS.md deve ser bloqueado
exit_code=0
echo '{"tool_input":{"file_path":"'"$tmpdir/project/AGENTS.md"'"}}' \
  | GOVERNANCE_HOOK_MODE=fail bash "$tmpdir/project/.claude/hooks/validate-governance.sh" 2>/dev/null || exit_code=$?

if [[ "$exit_code" -ne 0 ]]; then
  pass "mutation-governance: hook bloqueou edicao em AGENTS.md (exit $exit_code)"
else
  fail "mutation-governance: hook NAO bloqueou edicao em AGENTS.md"
fi

# Tentar editar references deve ser bloqueado
exit_code=0
echo '{"tool_input":{"file_path":"'"$tmpdir/project/.agents/skills/agent-governance/references/security.md"'"}}' \
  | GOVERNANCE_HOOK_MODE=fail bash "$tmpdir/project/.claude/hooks/validate-governance.sh" 2>/dev/null || exit_code=$?

if [[ "$exit_code" -ne 0 ]]; then
  pass "mutation-governance: hook bloqueou edicao em references/*.md (exit $exit_code)"
else
  fail "mutation-governance: hook NAO bloqueou edicao em references/*.md"
fi

# ========== 2. Hook validate-preload bloqueia sem contrato ==========
echo "=== Mutacao: edicao sem contrato de carga ==="

exit_code=0
echo '{"tool_input":{"file_path":"'"$tmpdir/project/main.go"'"}}' \
  | GOVERNANCE_PRELOAD_MODE=fail GOVERNANCE_PRELOAD_CONFIRMED=0 \
  bash "$tmpdir/project/.claude/hooks/validate-preload.sh" 2>/dev/null || exit_code=$?

if [[ "$exit_code" -ne 0 ]]; then
  pass "mutation-preload: bloqueou edicao .go sem contrato confirmado"
else
  fail "mutation-preload: NAO bloqueou edicao .go sem contrato"
fi

# Com GOVERNANCE_PRELOAD_CONFIRMED=1 deve passar
exit_code=0
echo '{"tool_input":{"file_path":"'"$tmpdir/project/main.go"'"}}' \
  | GOVERNANCE_PRELOAD_MODE=fail GOVERNANCE_PRELOAD_CONFIRMED=1 \
  bash "$tmpdir/project/.claude/hooks/validate-preload.sh" 2>/dev/null || exit_code=$?

if [[ "$exit_code" -eq 0 ]]; then
  pass "mutation-preload: permitiu edicao com contrato confirmado"
else
  fail "mutation-preload: bloqueou edicao com contrato confirmado"
fi

# ========== 3. Depth control bloqueia profundidade excessiva ==========
echo "=== Mutacao: profundidade de invocacao ==="

# Profundidade 0 deve passar
exit_code=0
AI_INVOCATION_DEPTH=0 bash "$ROOT_DIR/scripts/lib/check-invocation-depth.sh" > /dev/null 2>&1 || exit_code=$?
if [[ "$exit_code" -eq 0 ]]; then
  pass "mutation-depth: profundidade 0 aceita"
else
  fail "mutation-depth: profundidade 0 rejeitada"
fi

# Profundidade 1 deve passar
exit_code=0
AI_INVOCATION_DEPTH=1 bash "$ROOT_DIR/scripts/lib/check-invocation-depth.sh" > /dev/null 2>&1 || exit_code=$?
if [[ "$exit_code" -eq 0 ]]; then
  pass "mutation-depth: profundidade 1 aceita"
else
  fail "mutation-depth: profundidade 1 rejeitada"
fi

# Profundidade 2 (= max default) deve ser bloqueada
exit_code=0
AI_INVOCATION_DEPTH=2 bash "$ROOT_DIR/scripts/lib/check-invocation-depth.sh" > /dev/null 2>&1 || exit_code=$?
if [[ "$exit_code" -ne 0 ]]; then
  pass "mutation-depth: profundidade 2 bloqueada (limite default)"
else
  fail "mutation-depth: profundidade 2 NAO bloqueada"
fi

# Profundidade 5 deve ser bloqueada
exit_code=0
AI_INVOCATION_DEPTH=5 bash "$ROOT_DIR/scripts/lib/check-invocation-depth.sh" > /dev/null 2>&1 || exit_code=$?
if [[ "$exit_code" -ne 0 ]]; then
  pass "mutation-depth: profundidade 5 bloqueada"
else
  fail "mutation-depth: profundidade 5 NAO bloqueada"
fi

# ========== 4. Evidence validator rejeita relatorio mutado (secao removida) ==========
echo "=== Mutacao: relatorio com secoes removidas ==="

task_validator="$ROOT_DIR/.claude/scripts/validate-task-evidence.sh"

# Relatorio sem "Comandos Executados"
cat > "$tmpdir/task-no-cmds.md" <<'EOF'
# Contexto Carregado

PRD: tasks/prd-test/prd.md
TechSpec: tasks/prd-test/techspec.md

# Arquivos Alterados

- file.go

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
EOF

if bash "$task_validator" "$tmpdir/task-no-cmds.md" > /dev/null 2>&1; then
  fail "mutation-evidence: aceitou relatorio sem Comandos Executados"
else
  pass "mutation-evidence: rejeitou relatorio sem Comandos Executados"
fi

# Relatorio sem "Arquivos Alterados"
cat > "$tmpdir/task-no-files.md" <<'EOF'
# Contexto Carregado

PRD: tasks/prd-test/prd.md
TechSpec: tasks/prd-test/techspec.md

# Comandos Executados

go test ./...

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
EOF

if bash "$task_validator" "$tmpdir/task-no-files.md" > /dev/null 2>&1; then
  fail "mutation-evidence: aceitou relatorio sem Arquivos Alterados"
else
  pass "mutation-evidence: rejeitou relatorio sem Arquivos Alterados"
fi

# ========== 5. Spec drift detecta hash modificado ==========
echo "=== Mutacao: spec drift por hash ==="

mkdir -p "$tmpdir/drift-test"

cat > "$tmpdir/drift-test/prd.md" <<'EOF'
# PRD Test
## Requisitos
- RF-01: Requisito um
- RF-02: Requisito dois
EOF

# Calcular hash real
if command -v sha256sum >/dev/null 2>&1; then
  real_hash="$(sha256sum "$tmpdir/drift-test/prd.md" | cut -c1-8)"
elif command -v shasum >/dev/null 2>&1; then
  real_hash="$(shasum -a 256 "$tmpdir/drift-test/prd.md" | cut -c1-8)"
else
  real_hash="abcd1234"
fi

# tasks.md com hash correto — nao deve ter drift
cat > "$tmpdir/drift-test/tasks.md" <<EOF
<!-- spec-hash-prd: ${real_hash} -->
# Tasks
- RF-01: Tarefa 1
- RF-02: Tarefa 2
EOF

exit_code=0
bash "$ROOT_DIR/scripts/check-spec-drift.sh" "$tmpdir/drift-test/tasks.md" 2>/dev/null || exit_code=$?
if [[ "$exit_code" -eq 0 ]]; then
  pass "mutation-drift: sem drift com hash correto"
else
  fail "mutation-drift: drift falso-positivo com hash correto"
fi

# Mutar o PRD (alterar conteudo)
cat > "$tmpdir/drift-test/prd.md" <<'EOF'
# PRD Test MUTADO
## Requisitos
- RF-01: Requisito um ALTERADO
- RF-02: Requisito dois
- RF-03: Requisito tres NOVO
EOF

exit_code=0
bash "$ROOT_DIR/scripts/check-spec-drift.sh" "$tmpdir/drift-test/tasks.md" 2>/dev/null || exit_code=$?
if [[ "$exit_code" -ne 0 ]]; then
  pass "mutation-drift: detectou drift apos mutacao do PRD"
else
  fail "mutation-drift: NAO detectou drift apos mutacao do PRD"
fi

# ========== 6. Token budget rejeita carga excessiva ==========
echo "=== Mutacao: budget de tokens excedido ==="

# Criar arquivo grande
python3 -c "print('x ' * 50000)" > "$tmpdir/large-file.md"

exit_code=0
bash "$ROOT_DIR/scripts/check-token-budget.sh" --max 100 "$tmpdir/large-file.md" > /dev/null 2>&1 || exit_code=$?
if [[ "$exit_code" -ne 0 ]]; then
  pass "mutation-budget: bloqueou arquivo que excede budget"
else
  fail "mutation-budget: NAO bloqueou arquivo que excede budget"
fi

# Arquivo pequeno deve passar
echo "small file" > "$tmpdir/small-file.md"

exit_code=0
bash "$ROOT_DIR/scripts/check-token-budget.sh" --max 1000 "$tmpdir/small-file.md" > /dev/null 2>&1 || exit_code=$?
if [[ "$exit_code" -eq 0 ]]; then
  pass "mutation-budget: aceitou arquivo dentro do budget"
else
  fail "mutation-budget: rejeitou arquivo dentro do budget"
fi

# ========== 7. Pre-dispatch rejeita skill sem pre-requisitos ==========
echo "=== Mutacao: pre-dispatch sem pre-requisitos ==="

mkdir -p "$tmpdir/empty-project"
cat > "$tmpdir/empty-project/AGENTS.md" <<'EOF'
# Agents
EOF
mkdir -p "$tmpdir/empty-project/.agents/skills/agent-governance"
echo "---" > "$tmpdir/empty-project/.agents/skills/agent-governance/SKILL.md"
echo "---" >> "$tmpdir/empty-project/.agents/skills/agent-governance/SKILL.md"

cd "$tmpdir/empty-project"

exit_code=0
bash "$ROOT_DIR/scripts/check-skill-prerequisites.sh" "go-implementation" "." > /dev/null 2>&1 || exit_code=$?
if [[ "$exit_code" -ne 0 ]]; then
  pass "mutation-prereq: rejeitou go-implementation sem go.mod"
else
  fail "mutation-prereq: aceitou go-implementation sem go.mod"
fi

cd "$ROOT_DIR"

# ========== Resumo ==========
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"
if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
