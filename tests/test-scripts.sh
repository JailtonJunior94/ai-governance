#!/usr/bin/env bash
# Testes para scripts auxiliares do projeto de governanca.
# Uso: bash tests/test-scripts.sh

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
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
# validate-bug-input.py
# ============================================================
VALIDATE_BUG="$ROOT_DIR/.agents/skills/bugfix/scripts/validate-bug-input.py"

# Caso: input valido
cat > "$TMP_DIR/valid-bugs.json" <<'EOF'
[
  {
    "id": "BUG-001",
    "severity": "critical",
    "file": "internal/service/foo.go",
    "line": 42,
    "reproduction": "Executar X com Y",
    "expected": "Resultado esperado",
    "actual": "Resultado observado"
  }
]
EOF

if python3 "$VALIDATE_BUG" --input "$TMP_DIR/valid-bugs.json" > /dev/null 2>&1; then
  pass "validate-bug-input: input valido aceito"
else
  fail "validate-bug-input: input valido rejeitado"
fi

# Caso: multiplos bugs validos
cat > "$TMP_DIR/multi-bugs.json" <<'EOF'
[
  {"id":"BUG-001","severity":"critical","file":"a.go","line":1,"reproduction":"r","expected":"e","actual":"a"},
  {"id":"BUG-002","severity":"minor","file":"b.go","line":2,"reproduction":"r","expected":"e","actual":"a"}
]
EOF

if python3 "$VALIDATE_BUG" --input "$TMP_DIR/multi-bugs.json" > /dev/null 2>&1; then
  pass "validate-bug-input: multiplos bugs validos aceitos"
else
  fail "validate-bug-input: multiplos bugs validos rejeitados"
fi

# Caso: campo faltando
cat > "$TMP_DIR/missing-field.json" <<'EOF'
[{"id":"BUG-001","severity":"critical","file":"a.go","line":1}]
EOF

if python3 "$VALIDATE_BUG" --input "$TMP_DIR/missing-field.json" > /dev/null 2>&1; then
  fail "validate-bug-input: campo faltando nao detectado"
else
  pass "validate-bug-input: campo faltando rejeitado"
fi

# Caso: severidade invalida
cat > "$TMP_DIR/bad-severity.json" <<'EOF'
[{"id":"BUG-001","severity":"blocker","file":"a.go","line":1,"reproduction":"r","expected":"e","actual":"a"}]
EOF

if python3 "$VALIDATE_BUG" --input "$TMP_DIR/bad-severity.json" > /dev/null 2>&1; then
  fail "validate-bug-input: severidade invalida aceita"
else
  pass "validate-bug-input: severidade invalida rejeitada"
fi

# Caso: id fora do padrao BUG-NNN
cat > "$TMP_DIR/bad-id.json" <<'EOF'
[{"id":"FIX-1","severity":"minor","file":"a.go","line":1,"reproduction":"r","expected":"e","actual":"a"}]
EOF

if python3 "$VALIDATE_BUG" --input "$TMP_DIR/bad-id.json" > /dev/null 2>&1; then
  fail "validate-bug-input: id fora do padrao aceito"
else
  pass "validate-bug-input: id fora do padrao rejeitado"
fi

# Caso: line nao inteiro
cat > "$TMP_DIR/bad-line.json" <<'EOF'
[{"id":"BUG-001","severity":"minor","file":"a.go","line":"abc","reproduction":"r","expected":"e","actual":"a"}]
EOF

if python3 "$VALIDATE_BUG" --input "$TMP_DIR/bad-line.json" > /dev/null 2>&1; then
  fail "validate-bug-input: line nao inteiro aceito"
else
  pass "validate-bug-input: line nao inteiro rejeitado"
fi

# Caso: campo extra rejeitado
cat > "$TMP_DIR/extra-field.json" <<'EOF'
[{"id":"BUG-001","severity":"minor","file":"a.go","line":1,"reproduction":"r","expected":"e","actual":"a","extra":"x"}]
EOF

if python3 "$VALIDATE_BUG" --input "$TMP_DIR/extra-field.json" > /dev/null 2>&1; then
  fail "validate-bug-input: campo extra aceito"
else
  pass "validate-bug-input: campo extra rejeitado"
fi

# Caso: lista vazia
cat > "$TMP_DIR/empty-list.json" <<'EOF'
[]
EOF

if python3 "$VALIDATE_BUG" --input "$TMP_DIR/empty-list.json" > /dev/null 2>&1; then
  fail "validate-bug-input: lista vazia aceita"
else
  pass "validate-bug-input: lista vazia rejeitada"
fi

# Caso: JSON invalido
echo "not json" > "$TMP_DIR/invalid.json"

if python3 "$VALIDATE_BUG" --input "$TMP_DIR/invalid.json" > /dev/null 2>&1; then
  fail "validate-bug-input: JSON invalido aceito"
else
  pass "validate-bug-input: JSON invalido rejeitado"
fi

# ============================================================
# verify-go-mod.sh
# ============================================================
VERIFY_GO_MOD="$ROOT_DIR/.agents/skills/go-implementation/scripts/verify-go-mod.sh"

# Caso: go.mod presente
mkdir -p "$TMP_DIR/with-gomod"
echo "module test" > "$TMP_DIR/with-gomod/go.mod"

if (cd "$TMP_DIR/with-gomod" && bash "$VERIFY_GO_MOD") > /dev/null 2>&1; then
  pass "verify-go-mod: go.mod presente aceito"
else
  fail "verify-go-mod: go.mod presente rejeitado"
fi

# Caso: go.mod ausente
mkdir -p "$TMP_DIR/no-gomod"

if (cd "$TMP_DIR/no-gomod" && bash "$VERIFY_GO_MOD") > /dev/null 2>&1; then
  fail "verify-go-mod: go.mod ausente aceito"
else
  pass "verify-go-mod: go.mod ausente rejeitado"
fi

# ============================================================
# detect-toolchain.sh
# ============================================================
DETECT_TOOLCHAIN="$ROOT_DIR/.agents/skills/agent-governance/scripts/detect-toolchain.sh"

# Caso: projeto Go
if output="$(bash "$DETECT_TOOLCHAIN" "$ROOT_DIR/tests/fixtures/go-microservice" 2>/dev/null)"; then
  if echo "$output" | grep -q '"fmt":"gofmt'; then
    pass "detect-toolchain: Go project retorna gofmt"
  else
    fail "detect-toolchain: Go project nao retorna gofmt"
  fi
  if echo "$output" | grep -q '"test":"go test'; then
    pass "detect-toolchain: Go project retorna go test"
  else
    fail "detect-toolchain: Go project nao retorna go test"
  fi
else
  fail "detect-toolchain: Go project falhou"
fi

# Caso: projeto Node
if output="$(bash "$DETECT_TOOLCHAIN" "$ROOT_DIR/tests/fixtures/node-monorepo" 2>/dev/null)"; then
  if echo "$output" | grep -q '"test":"pnpm --filter @monorepo/web run test"'; then
    pass "detect-toolchain: Node monorepo detecta script de workspace"
  else
    fail "detect-toolchain: Node monorepo nao detecta script de workspace"
  fi
  if echo "$output" | grep -q '"lint":"pnpm --filter @monorepo/web run lint"'; then
    pass "detect-toolchain: Node monorepo detecta lint de workspace"
  else
    fail "detect-toolchain: Node monorepo nao detecta lint de workspace"
  fi
else
  fail "detect-toolchain: Node project falhou"
fi

# Caso: projeto Python com pyproject em subdiretorio
if output="$(bash "$DETECT_TOOLCHAIN" "$ROOT_DIR/tests/fixtures/python-monorepo" 2>/dev/null)"; then
  if echo "$output" | grep -q '"test":"pytest"'; then
    pass "detect-toolchain: Python em subdiretorio detecta pytest"
  else
    fail "detect-toolchain: Python em subdiretorio nao detecta pytest"
  fi
  if echo "$output" | grep -q '"lint":"ruff check \."'; then
    pass "detect-toolchain: Python em subdiretorio detecta ruff"
  else
    fail "detect-toolchain: Python em subdiretorio nao detecta ruff"
  fi
else
  fail "detect-toolchain: Python em subdiretorio falhou"
fi

# Caso: diretorio inexistente
if bash "$DETECT_TOOLCHAIN" "$TMP_DIR/nonexistent" > /dev/null 2>&1; then
  fail "detect-toolchain: diretorio inexistente aceito"
else
  pass "detect-toolchain: diretorio inexistente rejeitado"
fi

# Caso: diretorio vazio (sem stack)
mkdir -p "$TMP_DIR/empty-project"
if output="$(bash "$DETECT_TOOLCHAIN" "$TMP_DIR/empty-project" 2>/dev/null)"; then
  if echo "$output" | grep -q '"fmt":null'; then
    pass "detect-toolchain: projeto vazio retorna nulls"
  else
    fail "detect-toolchain: projeto vazio nao retorna nulls"
  fi
else
  fail "detect-toolchain: projeto vazio falhou"
fi

# ============================================================
# validate-task-evidence.sh
# ============================================================
VALIDATE_EVIDENCE="$ROOT_DIR/.claude/scripts/validate-task-evidence.sh"

# Caso: relatorio completo
cat > "$TMP_DIR/valid-report.md" <<'EOF'
# Relatório de Execução

## Contexto Carregado
PRD: tasks/prd-feature/prd.md
TechSpec: tasks/prd-feature/techspec.md

## Comandos Executados
- go test ./...
- golangci-lint run

## Arquivos Alterados
- internal/service/foo.go

## Resultados de Validacao
testes: pass
lint: pass

## Suposicoes
Nenhuma.

## Riscos Residuais
Nenhum risco residual identificado.

Estado: done
Veredito do revisor: APPROVED
EOF

if bash "$VALIDATE_EVIDENCE" "$TMP_DIR/valid-report.md" > /dev/null 2>&1; then
  pass "validate-task-evidence: relatorio completo aceito"
else
  fail "validate-task-evidence: relatorio completo rejeitado"
fi

# Caso: relatorio incompleto (sem PRD)
cat > "$TMP_DIR/incomplete-report.md" <<'EOF'
# Relatório de Execução

## Contexto Carregado
Nenhum.

## Comandos Executados
- go test ./...

## Arquivos Alterados
- foo.go

## Resultados de Validação
testes: pass
lint: pass

## Suposições
Nenhuma.

## Riscos Residuais
Nenhum.

Estado: done
Veredito do revisor: APPROVED
EOF

if bash "$VALIDATE_EVIDENCE" "$TMP_DIR/incomplete-report.md" > /dev/null 2>&1; then
  fail "validate-task-evidence: relatorio sem PRD aceito"
else
  pass "validate-task-evidence: relatorio sem PRD rejeitado"
fi

# Caso: arquivo inexistente
if bash "$VALIDATE_EVIDENCE" "$TMP_DIR/nonexistent.md" > /dev/null 2>&1; then
  fail "validate-task-evidence: arquivo inexistente aceito"
else
  pass "validate-task-evidence: arquivo inexistente rejeitado"
fi

# ============================================================
# Gemini commands: {{args}} presente no prompt
# ============================================================
GEMINI_COMMANDS_DIR="$ROOT_DIR/.gemini/commands"

for cmd_file in "$GEMINI_COMMANDS_DIR"/*.toml; do
  cmd_name="$(basename "$cmd_file" .toml)"

  # Deve conter {{args}} no prompt
  if grep -q '{{args}}' "$cmd_file"; then
    pass "gemini-command-$cmd_name: contem {{args}}"
  else
    fail "gemini-command-$cmd_name: {{args}} ausente no prompt"
  fi

  # Deve referenciar .agents/skills/ no prompt
  if grep -q '\.agents/skills/' "$cmd_file"; then
    pass "gemini-command-$cmd_name: referencia skill canonica"
  else
    fail "gemini-command-$cmd_name: nao referencia skill canonica"
  fi
done

# ============================================================
# Resumo
# ============================================================
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
