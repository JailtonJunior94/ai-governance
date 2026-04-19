#!/usr/bin/env bash
# Teste de integracao end-to-end entre skills:
# Simula o fluxo PRD -> TechSpec -> Tasks -> Execute -> Review -> Bugfix -> Final
# usando artefatos sinteticos e validadores reais.

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

# ========== Setup: projeto com governanca ==========
echo "=== Setup: projeto de integracao ==="

mkdir -p "$tmpdir/project"
cat > "$tmpdir/project/go.mod" <<'EOF'
module github.com/example/integration-test
go 1.22
EOF

bash "$ROOT_DIR/install.sh" --tools claude --langs go "$tmpdir/project" < /dev/null 2>/dev/null
if [[ -f "$tmpdir/project/AGENTS.md" ]]; then
  pass "setup: governanca instalada"
else
  fail "setup: governanca NAO instalada"
fi

# ========== Fase 1: PRD ==========
echo "=== Fase 1: PRD ==="

mkdir -p "$tmpdir/project/tasks/prd-integration-test"

cat > "$tmpdir/project/tasks/prd-integration-test/prd.md" <<'EOF'
# PRD: Teste de Integracao

## Visao Geral
Validar o fluxo completo de governanca entre skills.

## Objetivos
- Garantir rastreabilidade PRD -> tasks -> execution report.

## Historias de Usuario
- Como engenheiro, quero que o fluxo de governanca funcione end-to-end.

## Funcionalidades Core

### RF-01: Validar criacao de PRD
Criar documento de requisitos com numeracao RF.

### RF-02: Validar decomposicao em tasks
Decompor PRD em tarefas rastreavies.

### RF-03: Validar execucao e evidencia
Executar tarefa e produzir evidence report valido.

### RF-04: Validar review e bugfix
Produzir review e bugfix com evidencia valida.

## Restricoes Tecnicas
- Usar governanca padrao do repositorio.

## Fora de Escopo
- Implementacao de codigo real.
EOF

# Verificar que PRD tem RFs
rf_count="$(grep -c 'RF-0' "$tmpdir/project/tasks/prd-integration-test/prd.md")"
if [[ "$rf_count" -ge 4 ]]; then
  pass "prd: $rf_count requisitos RF encontrados"
else
  fail "prd: apenas $rf_count requisitos RF (esperado >= 4)"
fi

# ========== Fase 2: TechSpec ==========
echo "=== Fase 2: TechSpec ==="

cat > "$tmpdir/project/tasks/prd-integration-test/techspec.md" <<'EOF'
# Especificacao Tecnica: Teste de Integracao

## Arquitetura
- Validacao via scripts shell existentes.

## Decisoes (ADRs)
- ADR-001: Usar artefatos sinteticos para teste.

## Interfaces
- Input: PRD com RFs.
- Output: Execution reports validados.

## Riscos
- Nenhum risco tecnico real (teste sintetico).
EOF

if [[ -f "$tmpdir/project/tasks/prd-integration-test/techspec.md" ]]; then
  pass "techspec: arquivo criado"
else
  fail "techspec: arquivo NAO criado"
fi

# ========== Fase 3: Tasks (com spec-hash) ==========
echo "=== Fase 3: Tasks ==="

# Calcular hashes
if command -v sha256sum >/dev/null 2>&1; then
  prd_hash="$(sha256sum "$tmpdir/project/tasks/prd-integration-test/prd.md" | cut -c1-8)"
  ts_hash="$(sha256sum "$tmpdir/project/tasks/prd-integration-test/techspec.md" | cut -c1-8)"
elif command -v shasum >/dev/null 2>&1; then
  prd_hash="$(shasum -a 256 "$tmpdir/project/tasks/prd-integration-test/prd.md" | cut -c1-8)"
  ts_hash="$(shasum -a 256 "$tmpdir/project/tasks/prd-integration-test/techspec.md" | cut -c1-8)"
else
  prd_hash="skip"
  ts_hash="skip"
fi

cat > "$tmpdir/project/tasks/prd-integration-test/tasks.md" <<EOF
<!-- spec-hash-prd: ${prd_hash} -->
<!-- spec-hash-techspec: ${ts_hash} -->

# Tarefas de Implementacao

## Metadados
- **PRD:** tasks/prd-integration-test/prd.md
- **Especificacao Tecnica:** tasks/prd-integration-test/techspec.md
- **Total de tarefas:** 2

## Tarefas

| # | Titulo | Status | Dependencias |
|---|--------|--------|-------------|
| 1.0 | Implementar validacao de PRD (RF-01, RF-02) | pending | — |
| 2.0 | Implementar review e bugfix (RF-03, RF-04) | pending | 1.0 |

## Dependencias Criticas
- Tarefa 2.0 depende de 1.0.
EOF

# Verificar cobertura RF
exit_code=0
bash "$ROOT_DIR/scripts/check-rf-coverage.sh" \
  "$tmpdir/project/tasks/prd-integration-test/prd.md" \
  "$tmpdir/project/tasks/prd-integration-test/tasks.md" > /dev/null 2>&1 || exit_code=$?

if [[ "$exit_code" -eq 0 ]]; then
  pass "tasks: cobertura RF 100%"
else
  fail "tasks: cobertura RF incompleta"
fi

# Verificar drift
exit_code=0
bash "$ROOT_DIR/scripts/check-spec-drift.sh" \
  "$tmpdir/project/tasks/prd-integration-test/tasks.md" > /dev/null 2>&1 || exit_code=$?

if [[ "$exit_code" -eq 0 ]]; then
  pass "tasks: sem spec drift"
else
  fail "tasks: spec drift detectado"
fi

# ========== Fase 4: Execution Report ==========
echo "=== Fase 4: Execution Report ==="

cat > "$tmpdir/project/tasks/prd-integration-test/1.0_execution_report.md" <<EOF
# Contexto Carregado

PRD: $tmpdir/project/tasks/prd-integration-test/prd.md
TechSpec: $tmpdir/project/tasks/prd-integration-test/techspec.md

# Comandos Executados

bash scripts/check-rf-coverage.sh -> PASS
bash scripts/check-spec-drift.sh -> PASS

# Arquivos Alterados

- tasks/prd-integration-test/tasks.md

# Resultados de Validacao

Testes: pass
Lint: pass
RF-01 e RF-02 validados com cobertura 100%.

# Suposicoes

Nenhuma.

# Riscos Residuais

Nenhum.

Estado: done

Veredito do Revisor: APPROVED
EOF

# Validar execution report
exit_code=0
bash "$ROOT_DIR/.claude/scripts/validate-task-evidence.sh" \
  "$tmpdir/project/tasks/prd-integration-test/1.0_execution_report.md" > /dev/null 2>&1 || exit_code=$?

if [[ "$exit_code" -eq 0 ]]; then
  pass "execution-report: validacao aprovada"
else
  fail "execution-report: validacao falhou"
fi

# Verificar rastreabilidade RF no report vs PRD
report_rfs="$(grep -Eoi 'RF-[0-9]+' "$tmpdir/project/tasks/prd-integration-test/1.0_execution_report.md" | sort -u | wc -l | tr -d '[:space:]')"
if [[ "$report_rfs" -ge 2 ]]; then
  pass "execution-report: $report_rfs RFs referenciados"
else
  fail "execution-report: apenas $report_rfs RFs referenciados (esperado >= 2)"
fi

# ========== Fase 5: Bugfix Report ==========
echo "=== Fase 5: Bugfix Report ==="

cat > "$tmpdir/bugfix-report.md" <<'EOF'
# Relatorio de Bugfix

- Total de bugs no escopo: 1
- Corrigidos: 1

## Bugs
- ID: BUG-001
- Severidade: minor
- Estado: fixed
- Causa raiz: validacao de RF-03 ausente no report
- Arquivos alterados: tasks/prd-integration-test/1.0_execution_report.md
- Teste de regressao: TestRFCoverage
- Validacao: pass

## Comandos Executados
- bash scripts/check-rf-coverage.sh -> PASS

## Riscos Residuais
- Nenhum

- Estado final: done
EOF

exit_code=0
bash "$ROOT_DIR/.claude/scripts/validate-bugfix-evidence.sh" \
  "$tmpdir/bugfix-report.md" > /dev/null 2>&1 || exit_code=$?

if [[ "$exit_code" -eq 0 ]]; then
  pass "bugfix-report: validacao aprovada"
else
  fail "bugfix-report: validacao falhou"
fi

# ========== Fase 6: Refactor Report ==========
echo "=== Fase 6: Refactor Report ==="

cat > "$tmpdir/refactor-report.md" <<'EOF'
# Relatorio de Refatoracao

## Escopo
- Alvo: tasks/prd-integration-test/tasks.md
- Modo: advisory
- Estado: done

## Invariantes Preservadas
- Cobertura RF-01..RF-04 mantida

## Mudancas Propostas ou Aplicadas
- Reorganizar tabela de tarefas

## Comandos Executados
- bash scripts/check-rf-coverage.sh -> PASS

## Resultados de Validacao
- Testes: pass
- Lint: pass

## Riscos Residuais
- Nenhum
EOF

exit_code=0
bash "$ROOT_DIR/.claude/scripts/validate-refactor-evidence.sh" \
  "$tmpdir/refactor-report.md" > /dev/null 2>&1 || exit_code=$?

if [[ "$exit_code" -eq 0 ]]; then
  pass "refactor-report: validacao aprovada"
else
  fail "refactor-report: validacao falhou"
fi

# ========== Fase 7: Token budget ==========
echo "=== Fase 7: Token budget ==="

exit_code=0
bash "$ROOT_DIR/scripts/check-token-budget.sh" --max 20000 \
  "$tmpdir/project/AGENTS.md" \
  "$tmpdir/project/.agents/skills/agent-governance/SKILL.md" \
  "$tmpdir/project/.agents/skills/go-implementation/SKILL.md" > /dev/null 2>&1 || exit_code=$?

if [[ "$exit_code" -eq 0 ]]; then
  pass "token-budget: baseline Go dentro do budget"
else
  fail "token-budget: baseline Go excedeu budget"
fi

# ========== Fase 8: Pre-dispatch ==========
echo "=== Fase 8: Pre-dispatch ==="

cd "$tmpdir/project"

exit_code=0
bash "$ROOT_DIR/scripts/check-skill-prerequisites.sh" "go-implementation" "." > /dev/null 2>&1 || exit_code=$?
if [[ "$exit_code" -eq 0 ]]; then
  pass "pre-dispatch: go-implementation com go.mod presente"
else
  fail "pre-dispatch: go-implementation rejeitado com go.mod presente"
fi

exit_code=0
bash "$ROOT_DIR/scripts/check-skill-prerequisites.sh" "create-tasks" \
  "$tmpdir/project/tasks/prd-integration-test" > /dev/null 2>&1 || exit_code=$?
if [[ "$exit_code" -eq 0 ]]; then
  pass "pre-dispatch: create-tasks com PRD+TechSpec presentes"
else
  fail "pre-dispatch: create-tasks rejeitado com PRD+TechSpec presentes"
fi

cd "$ROOT_DIR"

# ========== Fase 9: Spec drift apos mutacao ==========
echo "=== Fase 9: Drift apos mutacao de PRD ==="

# Mutar o PRD (adicionar RF-05)
cat >> "$tmpdir/project/tasks/prd-integration-test/prd.md" <<'EOF'

### RF-05: Requisito adicionado pos-tasks
Novo requisito que nao esta coberto nas tasks.
EOF

# Drift semantico deve ser detectado (RF-05 ausente em tasks.md)
exit_code=0
bash "$ROOT_DIR/scripts/check-spec-drift.sh" \
  "$tmpdir/project/tasks/prd-integration-test/tasks.md" > /dev/null 2>&1 || exit_code=$?

if [[ "$exit_code" -ne 0 ]]; then
  pass "drift-mutacao: detectou RF-05 ausente em tasks.md"
else
  fail "drift-mutacao: NAO detectou RF-05 ausente em tasks.md"
fi

# ========== Resumo ==========
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"
if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
