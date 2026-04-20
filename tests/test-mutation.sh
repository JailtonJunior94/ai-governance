#!/usr/bin/env bash
# Mutation testing wrapper: instala bats-core se necessario, executa
# test-mutation.bats com TAP output e gera relatorio de cobertura de mutacao.

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"

# ---------- Garantir bats disponivel ----------
BATS_BIN=""
if command -v bats >/dev/null 2>&1; then
  BATS_BIN="bats"
elif [[ -x "$TESTS_DIR/lib/bats-core/bin/bats" ]]; then
  BATS_BIN="$TESTS_DIR/lib/bats-core/bin/bats"
else
  echo "bats-core nao encontrado. Instalando..."
  bash "$TESTS_DIR/lib/install-bats.sh"
  if [[ -x "$TESTS_DIR/lib/bats-core/bin/bats" ]]; then
    BATS_BIN="$TESTS_DIR/lib/bats-core/bin/bats"
  else
    echo "ERRO: falha ao instalar bats-core"
    exit 1
  fi
fi

# ---------- Executar bats com TAP ----------
TAP_FILE="$(mktemp)"
trap 'rm -f "$TAP_FILE"' EXIT

set +e
"$BATS_BIN" --tap "$TESTS_DIR/test-mutation.bats" 2>&1 | tee "$TAP_FILE"
BATS_EXIT=$?
set -e

# ---------- Gerar relatorio de cobertura de mutacao ----------
echo ""
echo "=== Relatorio de Cobertura de Mutacao ==="

TOTAL=0
PASSED=0
FAILED=0
MUTANTS_TOTAL=0
MUTANTS_KILLED=0
MUTANTS_SURVIVED=0
CONTROLS_TOTAL=0
CONTROLS_PASSED=0
CONTROLS_FAILED=0

while IFS= read -r line; do
  case "$line" in
    "ok "*)
      TOTAL=$((TOTAL + 1))
      PASSED=$((PASSED + 1))
      if echo "$line" | grep -q "mutant:"; then
        MUTANTS_TOTAL=$((MUTANTS_TOTAL + 1))
        MUTANTS_KILLED=$((MUTANTS_KILLED + 1))
      elif echo "$line" | grep -q "control:"; then
        CONTROLS_TOTAL=$((CONTROLS_TOTAL + 1))
        CONTROLS_PASSED=$((CONTROLS_PASSED + 1))
      fi
      ;;
    "not ok "*)
      TOTAL=$((TOTAL + 1))
      FAILED=$((FAILED + 1))
      if echo "$line" | grep -q "mutant:"; then
        MUTANTS_TOTAL=$((MUTANTS_TOTAL + 1))
        MUTANTS_SURVIVED=$((MUTANTS_SURVIVED + 1))
      elif echo "$line" | grep -q "control:"; then
        CONTROLS_TOTAL=$((CONTROLS_TOTAL + 1))
        CONTROLS_FAILED=$((CONTROLS_FAILED + 1))
      fi
      ;;
  esac
done < "$TAP_FILE"

if [[ "$MUTANTS_TOTAL" -gt 0 ]]; then
  KILL_RATE=$((MUTANTS_KILLED * 100 / MUTANTS_TOTAL))
else
  KILL_RATE=0
fi

echo ""
echo "Mutantes introduzidos:  $MUTANTS_TOTAL"
echo "Mutantes mortos:        $MUTANTS_KILLED"
echo "Mutantes sobreviventes: $MUTANTS_SURVIVED"
echo "Taxa de deteccao:       ${KILL_RATE}%"
echo ""
echo "Controles executados:   $CONTROLS_TOTAL"
echo "Controles corretos:     $CONTROLS_PASSED"
echo "Controles violados:     $CONTROLS_FAILED"
echo ""
echo "Total de testes:        $TOTAL"
echo "Passou:                 $PASSED"
echo "Falhou:                 $FAILED"
echo ""

if [[ "$MUTANTS_SURVIVED" -gt 0 ]]; then
  echo "ATENCAO: $MUTANTS_SURVIVED mutante(s) sobreviveram — gaps de deteccao identificados."
fi

if [[ "$CONTROLS_FAILED" -gt 0 ]]; then
  echo "ATENCAO: $CONTROLS_FAILED controle(s) falharam — falsos positivos detectados."
fi

echo ""
echo "Resultado: $PASSED passed, $FAILED failed (kill rate: ${KILL_RATE}%)"

exit "$BATS_EXIT"
