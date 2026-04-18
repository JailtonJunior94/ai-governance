#!/usr/bin/env bash
# Testes de snapshot para generate-governance.sh.
# Gera AGENTS.md para cada fixture e compara com o snapshot salvo.
#
# Uso:
#   bash tests/test-generate-governance.sh             # verifica snapshots
#   bash tests/test-generate-governance.sh --update     # atualiza snapshots

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
GENERATOR="$ROOT_DIR/.agents/skills/analyze-project/scripts/generate-governance.sh"
FIXTURES_DIR="$TESTS_DIR/fixtures"
SNAPSHOTS_DIR="$TESTS_DIR/snapshots"

UPDATE=0
if [[ "${1:-}" == "--update" ]]; then
  UPDATE=1
fi

PASSED=0
FAILED=0
UPDATED=0

for fixture_dir in "$FIXTURES_DIR"/*/; do
  fixture_name="$(basename "$fixture_dir")"
  snapshot_file="$SNAPSHOTS_DIR/${fixture_name}.agents.md"
  output_file="$fixture_dir/AGENTS.md"

  # Limpar output anterior
  rm -f "$output_file"

  # Rodar o gerador com todas as flags desligadas (nao gera CLAUDE.md etc.)
  INSTALL_CLAUDE=0 INSTALL_GEMINI=0 INSTALL_COPILOT=0 \
    bash "$GENERATOR" "$fixture_dir" 2>/dev/null

  if [[ ! -f "$output_file" ]]; then
    echo "FAIL  $fixture_name — AGENTS.md nao foi gerado"
    FAILED=$((FAILED + 1))
    continue
  fi

  if [[ "$UPDATE" -eq 1 ]]; then
    cp "$output_file" "$snapshot_file"
    echo "UPDATED  $fixture_name"
    UPDATED=$((UPDATED + 1))
  elif [[ ! -f "$snapshot_file" ]]; then
    echo "FAIL  $fixture_name — snapshot nao encontrado (execute com --update para criar)"
    FAILED=$((FAILED + 1))
  elif diff -u "$snapshot_file" "$output_file" > /dev/null 2>&1; then
    echo "PASS  $fixture_name"
    PASSED=$((PASSED + 1))
  else
    echo "FAIL  $fixture_name — output difere do snapshot:"
    diff -u "$snapshot_file" "$output_file" || true
    FAILED=$((FAILED + 1))
  fi

  # Limpar output gerado na fixture
  rm -f "$output_file"
done

echo ""
if [[ "$UPDATE" -eq 1 ]]; then
  echo "Snapshots atualizados: $UPDATED"
else
  echo "Resultado: $PASSED passed, $FAILED failed"
  if [[ "$FAILED" -gt 0 ]]; then
    exit 1
  fi
fi
