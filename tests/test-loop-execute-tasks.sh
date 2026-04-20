#!/usr/bin/env bash
# Testes unitarios para os componentes do loop de execucao de tasks.
# Nao invoca CLIs de IA reais — testa task-selector, report-parser e loop-report-generator.
#
# Uso:
#   bash tests/test-loop-execute-tasks.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES="$SCRIPT_DIR/fixtures/loop-tasks"

pass=0
fail=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $label"
    pass=$((pass + 1))
  else
    echo "  FAIL: $label"
    echo "    esperado: '$expected'"
    echo "    obtido:   '$actual'"
    fail=$((fail + 1))
  fi
}

assert_exit() {
  local label="$1" expected_code="$2"
  shift 2
  local actual_code=0
  "$@" >/dev/null 2>&1 || actual_code=$?
  if [[ "$expected_code" -eq "$actual_code" ]]; then
    echo "  PASS: $label (exit $actual_code)"
    pass=$((pass + 1))
  else
    echo "  FAIL: $label"
    echo "    esperado exit: $expected_code"
    echo "    obtido exit:   $actual_code"
    fail=$((fail + 1))
  fi
}

echo "=== test-loop-execute-tasks ==="
echo ""

# --- task-selector ---
echo "[task-selector]"

# Cenario 1: todas done → nenhuma elegivel
assert_exit "todas done retorna 1" 1 \
  bash "$ROOT_DIR/scripts/lib/task-selector.sh" "$ROOT_DIR/tasks/prd-semver-automation-release/tasks.md"

# Cenario 2: pending com deps satisfeitas → seleciona 2.0
result="$(bash "$ROOT_DIR/scripts/lib/task-selector.sh" "$FIXTURES/tasks.md")"
task_id="$(echo "$result" | cut -f1)"
assert_eq "seleciona task 2.0 (deps ok)" "2.0" "$task_id"

# Cenario 3: pending sem deps → seleciona 1.0
result="$(bash "$ROOT_DIR/scripts/lib/task-selector.sh" "$FIXTURES/tasks-blocked-deps.md")"
task_id="$(echo "$result" | cut -f1)"
assert_eq "seleciona task 1.0 (sem deps)" "1.0" "$task_id"

# Cenario 4: arquivo inexistente → exit 2
assert_exit "arquivo inexistente retorna 2" 2 \
  bash "$ROOT_DIR/scripts/lib/task-selector.sh" "/tmp/nao-existe.md"

# Cenario 5: sem argumentos → exit 2
assert_exit "sem argumentos retorna 2" 2 \
  bash "$ROOT_DIR/scripts/lib/task-selector.sh"

echo ""

# --- report-parser ---
echo "[report-parser]"

# Cenario 1: report com estado done
state="$(bash "$ROOT_DIR/scripts/lib/report-parser.sh" "$FIXTURES/report-done.md")"
assert_eq "extrai estado done" "done" "$state"

# Cenario 2: report com estado blocked
state="$(bash "$ROOT_DIR/scripts/lib/report-parser.sh" "$FIXTURES/report-blocked.md")"
assert_eq "extrai estado blocked" "blocked" "$state"

# Cenario 3: arquivo inexistente → unknown + exit 1
state="$(bash "$ROOT_DIR/scripts/lib/report-parser.sh" "/tmp/nao-existe.md" 2>/dev/null || true)"
assert_eq "arquivo inexistente retorna unknown" "unknown" "$state"

# Cenario 4: sem argumentos → exit 2
assert_exit "sem argumentos retorna 2" 2 \
  bash "$ROOT_DIR/scripts/lib/report-parser.sh"

echo ""

# --- loop-report-generator ---
echo "[loop-report-generator]"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

# Criar estrutura minima
cp "$FIXTURES/tasks.md" "$tmp_dir/tasks.md"
mkdir -p "$tmp_dir/logs"

report_path="$(bash "$ROOT_DIR/scripts/lib/loop-report-generator.sh" \
  "test-feature" "done" "" "1.0 2.0" "$tmp_dir/logs" "2026-04-19 10:00:00" "$tmp_dir/tasks.md")"

# Verificar que o relatorio foi gerado
if [[ -f "$report_path" ]]; then
  echo "  PASS: relatorio gerado em $report_path"
  pass=$((pass + 1))
else
  echo "  FAIL: relatorio nao encontrado em $report_path"
  fail=$((fail + 1))
fi

# Verificar conteudo
if grep -q "Estado Final: done" "$report_path" 2>/dev/null; then
  echo "  PASS: contem estado final done"
  pass=$((pass + 1))
else
  echo "  FAIL: estado final nao encontrado no relatorio"
  fail=$((fail + 1))
fi

if grep -q "Feature: prd-test-feature" "$report_path" 2>/dev/null; then
  echo "  PASS: contem feature slug"
  pass=$((pass + 1))
else
  echo "  FAIL: feature slug nao encontrado no relatorio"
  fail=$((fail + 1))
fi

# Cenario com task de parada
report_path2="$(bash "$ROOT_DIR/scripts/lib/loop-report-generator.sh" \
  "test-feature" "blocked" "2.0" "1.0" "$tmp_dir/logs" "2026-04-19 10:00:00" "$tmp_dir/tasks.md")"

if grep -q "Estado Final: blocked" "$report_path2" 2>/dev/null; then
  echo "  PASS: contem estado blocked quando task para"
  pass=$((pass + 1))
else
  echo "  FAIL: estado blocked nao encontrado"
  fail=$((fail + 1))
fi

if grep -q "ID: 2.0" "$report_path2" 2>/dev/null; then
  echo "  PASS: contem task de parada 2.0"
  pass=$((pass + 1))
else
  echo "  FAIL: task de parada nao encontrada"
  fail=$((fail + 1))
fi

echo ""

# --- Resumo ---
total=$((pass + fail))
echo "=== Resultado: $pass/$total passaram ==="
if [[ "$fail" -gt 0 ]]; then
  echo "FALHA: $fail teste(s) falharam"
  exit 1
fi
echo "OK: todos os testes passaram"
exit 0
