#!/usr/bin/env bash
# Testa os 3 evidence validators (task, bugfix, refactor) como gate de CI.
# Garante que relatorios validos passam e invalidos falham.

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

# ========== 1. validate-task-evidence.sh ==========
echo "=== Task evidence validator ==="

task_validator="$ROOT_DIR/.claude/scripts/validate-task-evidence.sh"

# 1a. Relatorio valido
cat > "$tmpdir/task-valid.md" <<'EOF'
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
EOF

if bash "$task_validator" "$tmpdir/task-valid.md" > /dev/null 2>&1; then
  pass "task-evidence: aceita relatorio valido"
else
  fail "task-evidence: rejeitou relatorio valido"
fi

# 1b. Relatorio sem Contexto Carregado
cat > "$tmpdir/task-no-context.md" <<'EOF'
# Comandos Executados

go test ./...

# Arquivos Alterados

- file.go

# Resultados de Validacao

Testes: pass
Lint: pass

# Suposicoes

Nenhuma.

# Riscos Residuais

Nenhum.

Estado: done

Veredito do Revisor: APPROVED
EOF

if bash "$task_validator" "$tmpdir/task-no-context.md" > /dev/null 2>&1; then
  fail "task-evidence: aceitou relatorio sem Contexto Carregado"
else
  pass "task-evidence: rejeitou relatorio sem Contexto Carregado"
fi

# 1c. Relatorio sem estado terminal
cat > "$tmpdir/task-no-state.md" <<'EOF'
# Contexto Carregado

PRD: tasks/prd-test/prd.md
TechSpec: tasks/prd-test/techspec.md

# Comandos Executados

go test ./...

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

Veredito do Revisor: APPROVED
EOF

if bash "$task_validator" "$tmpdir/task-no-state.md" > /dev/null 2>&1; then
  fail "task-evidence: aceitou relatorio sem estado terminal"
else
  pass "task-evidence: rejeitou relatorio sem estado terminal"
fi

# 1d. Relatorio sem veredito do revisor
cat > "$tmpdir/task-no-verdict.md" <<'EOF'
# Contexto Carregado

PRD: tasks/prd-test/prd.md
TechSpec: tasks/prd-test/techspec.md

# Comandos Executados

go test ./...

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
EOF

if bash "$task_validator" "$tmpdir/task-no-verdict.md" > /dev/null 2>&1; then
  fail "task-evidence: aceitou relatorio sem veredito"
else
  pass "task-evidence: rejeitou relatorio sem veredito"
fi

# 1e. Relatorio com secoes vazias (apenas placeholders) deve falhar
cat > "$tmpdir/task-empty-sections.md" <<'EOF'
# Contexto Carregado

PRD: tasks/prd-test/prd.md
TechSpec: tasks/prd-test/techspec.md

# Comandos Executados

Nenhum.

# Arquivos Alterados

Nenhum.

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

if bash "$task_validator" "$tmpdir/task-empty-sections.md" > /dev/null 2>&1; then
  fail "task-evidence: aceitou relatorio com Comandos Executados vazio"
else
  pass "task-evidence: rejeitou relatorio com Comandos Executados vazio"
fi

# ========== 2. validate-bugfix-evidence.sh ==========
echo "=== Bugfix evidence validator ==="

bugfix_validator="$ROOT_DIR/.claude/scripts/validate-bugfix-evidence.sh"

# 2a. Relatorio valido
cat > "$tmpdir/bugfix-valid.md" <<'EOF'
# Relatorio de Bugfix

- Total de bugs no escopo: 1
- Corrigidos: 1

## Bugs
- ID: BUG-001
- Severidade: major
- Estado: fixed
- Causa raiz: nil pointer no handler de autenticacao
- Arquivos alterados: internal/auth/handler.go
- Teste de regressao: TestAuthHandler_NilToken
- Validacao: go test ./internal/auth/... pass

## Comandos Executados
- go test ./internal/auth/... -> PASS

## Riscos Residuais
- Nenhum

- Estado final: done
EOF

if bash "$bugfix_validator" "$tmpdir/bugfix-valid.md" > /dev/null 2>&1; then
  pass "bugfix-evidence: aceita relatorio valido"
else
  fail "bugfix-evidence: rejeitou relatorio valido"
fi

# 2b. Relatorio sem causa raiz
cat > "$tmpdir/bugfix-no-cause.md" <<'EOF'
# Relatorio de Bugfix

- Corrigidos: 1

## Bugs
- Estado: fixed

## Comandos Executados
- go test

## Riscos Residuais
- Nenhum

- Estado final: done
EOF

if bash "$bugfix_validator" "$tmpdir/bugfix-no-cause.md" > /dev/null 2>&1; then
  fail "bugfix-evidence: aceitou relatorio sem causa raiz"
else
  pass "bugfix-evidence: rejeitou relatorio sem causa raiz"
fi

# 2c. Relatorio com Bugs vazio (apenas placeholder)
cat > "$tmpdir/bugfix-empty-bugs.md" <<'EOF'
# Relatorio de Bugfix

- Corrigidos: 1

## Bugs

Nenhum.

## Comandos Executados
- go test ./internal/auth/... -> PASS

## Riscos Residuais
- Nenhum

- Estado: fixed
- Causa raiz: nil pointer
- Teste de regressao: TestFoo
- Validacao: pass
- Estado final: done
EOF

if bash "$bugfix_validator" "$tmpdir/bugfix-empty-bugs.md" > /dev/null 2>&1; then
  fail "bugfix-evidence: aceitou relatorio com secao Bugs vazia"
else
  pass "bugfix-evidence: rejeitou relatorio com secao Bugs vazia"
fi

# 2d. Rastreabilidade RF via --rf
cat > "$tmpdir/bugfix-rf.md" <<'EOF'
# Relatorio de Bugfix

- Corrigidos: 1

## Bugs
- Estado: fixed
- Causa raiz: erro de validacao em RF-01
- Teste de regressao: TestValidation
- Validacao: pass

## Comandos Executados
- go test

## Riscos Residuais
- Nenhum

- Estado final: done
EOF

if bash "$bugfix_validator" --rf RF-01 "$tmpdir/bugfix-rf.md" > /dev/null 2>&1; then
  pass "bugfix-evidence: aceita relatorio com RF-01 presente"
else
  fail "bugfix-evidence: rejeitou relatorio com RF-01 presente"
fi

if bash "$bugfix_validator" --rf RF-99 "$tmpdir/bugfix-rf.md" > /dev/null 2>&1; then
  fail "bugfix-evidence: aceitou relatorio sem RF-99"
else
  pass "bugfix-evidence: rejeitou relatorio sem RF-99"
fi

# ========== 3. validate-refactor-evidence.sh ==========
echo "=== Refactor evidence validator ==="

refactor_validator="$ROOT_DIR/.claude/scripts/validate-refactor-evidence.sh"

# 3a. Relatorio valido (advisory)
cat > "$tmpdir/refactor-valid.md" <<'EOF'
# Relatorio de Refatoracao

## Escopo
- Alvo: internal/order/domain.go
- Modo: advisory
- Estado: done

## Invariantes Preservadas
- Contrato publico OrderRepository mantido

## Mudancas Propostas ou Aplicadas
- Extrair calculo de preco para metodo isolado

## Comandos Executados
- go test ./internal/order/... -> PASS

## Resultados de Validacao
- Testes: pass
- Lint: pass

## Riscos Residuais
- Nenhum
EOF

if bash "$refactor_validator" "$tmpdir/refactor-valid.md" > /dev/null 2>&1; then
  pass "refactor-evidence: aceita advisory valido"
else
  fail "refactor-evidence: rejeitou advisory valido"
fi

# 3b. Execution sem veredito deve falhar
cat > "$tmpdir/refactor-exec-no-verdict.md" <<'EOF'
## Escopo
- Modo: execution
- Estado: done

## Invariantes Preservadas
- Invariante A

## Mudancas Propostas ou Aplicadas
- Mudanca X

## Comandos Executados
- cmd -> result

## Resultados de Validacao
- Testes: pass
- Lint: pass

## Riscos Residuais
- Nenhum
EOF

if bash "$refactor_validator" "$tmpdir/refactor-exec-no-verdict.md" > /dev/null 2>&1; then
  fail "refactor-evidence: aceitou execution sem veredito"
else
  pass "refactor-evidence: rejeitou execution sem veredito"
fi

# 3c. Execution com veredito deve passar
cat > "$tmpdir/refactor-exec-verdict.md" <<'EOF'
## Escopo
- Modo: execution
- Estado: done

## Invariantes Preservadas
- Invariante A

## Mudancas Propostas ou Aplicadas
- Mudanca X

## Comandos Executados
- cmd -> result

## Resultados de Validacao
- Testes: pass
- Lint: pass
- Veredito do Revisor: APPROVED

## Riscos Residuais
- Nenhum
EOF

if bash "$refactor_validator" "$tmpdir/refactor-exec-verdict.md" > /dev/null 2>&1; then
  pass "refactor-evidence: aceita execution com veredito"
else
  fail "refactor-evidence: rejeitou execution com veredito"
fi

# 3d. Relatorio com secao Mudancas vazia deve falhar
cat > "$tmpdir/refactor-empty-changes.md" <<'EOF'
## Escopo
- Modo: advisory
- Estado: done

## Invariantes Preservadas
- Contrato publico mantido

## Mudancas Propostas ou Aplicadas

Nenhum.

## Comandos Executados
- go test ./internal/order/... -> PASS

## Resultados de Validacao
- Testes: pass
- Lint: pass

## Riscos Residuais
- Nenhum
EOF

if bash "$refactor_validator" "$tmpdir/refactor-empty-changes.md" > /dev/null 2>&1; then
  fail "refactor-evidence: aceitou relatorio com Mudancas vazia"
else
  pass "refactor-evidence: rejeitou relatorio com Mudancas vazia"
fi

# 3e. Relatorio sem modo deve falhar
cat > "$tmpdir/refactor-no-mode.md" <<'EOF'
## Escopo
- Estado: done

## Invariantes Preservadas
- X

## Mudancas Propostas ou Aplicadas
- Y

## Comandos Executados
- cmd

## Resultados de Validacao
- Testes: pass
- Lint: pass

## Riscos Residuais
- Nenhum
EOF

if bash "$refactor_validator" "$tmpdir/refactor-no-mode.md" > /dev/null 2>&1; then
  fail "refactor-evidence: aceitou relatorio sem modo"
else
  pass "refactor-evidence: rejeitou relatorio sem modo"
fi

# ========== 4. Uso incorreto ==========
echo "=== Uso incorreto ==="

exit_code=0
bash "$task_validator" 2>/dev/null || exit_code=$?
if [[ "$exit_code" -eq 2 ]]; then
  pass "task-evidence: exit 2 sem argumentos"
else
  fail "task-evidence: exit $exit_code (esperado 2) sem argumentos"
fi

exit_code=0
bash "$bugfix_validator" 2>/dev/null || exit_code=$?
if [[ "$exit_code" -eq 2 ]]; then
  pass "bugfix-evidence: exit 2 sem argumentos"
else
  fail "bugfix-evidence: exit $exit_code (esperado 2) sem argumentos"
fi

exit_code=0
bash "$refactor_validator" 2>/dev/null || exit_code=$?
if [[ "$exit_code" -eq 2 ]]; then
  pass "refactor-evidence: exit 2 sem argumentos"
else
  fail "refactor-evidence: exit $exit_code (esperado 2) sem argumentos"
fi

# ========== Resumo ==========
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"
if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
