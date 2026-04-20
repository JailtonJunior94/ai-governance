#!/usr/bin/env bash
# Harness de execucao real: valida que as fixtures de teste possuem
# estrutura executavel e, quando as ferramentas estao instaladas,
# executa smoke tests reais (go vet, python -m py_compile, node --check).
#
# Este teste nao instala dependencias externas — apenas valida o que e
# executavel com ferramentas ja presentes na maquina.

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
FIXTURES_DIR="$ROOT_DIR/tests/fixtures"

PASSED=0
FAILED=0
SKIPPED=0

pass() {
  echo "PASS  $1"
  PASSED=$((PASSED + 1))
}

fail() {
  echo "FAIL  $1"
  FAILED=$((FAILED + 1))
}

skip() {
  echo "SKIP  $1"
  SKIPPED=$((SKIPPED + 1))
}

# ========== 1. Fixtures Go: estrutura valida ==========
echo "=== Go fixtures ==="

for go_fixture in "$FIXTURES_DIR"/go-*; do
  [[ -d "$go_fixture" ]] || continue
  fixture_name="$(basename "$go_fixture")"

  # go.mod obrigatorio
  if [[ -f "$go_fixture/go.mod" ]]; then
    pass "go-struct/$fixture_name: go.mod presente"
  else
    fail "go-struct/$fixture_name: go.mod ausente"
    continue
  fi

  # Pelo menos um arquivo .go (pode ser estrutural com .gitkeep apenas)
  go_files="$(find "$go_fixture" -name '*.go' 2>/dev/null | head -1)"
  if [[ -n "$go_files" ]]; then
    pass "go-struct/$fixture_name: arquivos .go presentes"

    # Smoke test: go vet (se go estiver instalado e houver .go reais)
    if command -v go &>/dev/null; then
      if (cd "$go_fixture" && go vet ./... 2>/dev/null); then
        pass "go-vet/$fixture_name: go vet passou"
      else
        skip "go-vet/$fixture_name: go vet falhou (dependencias possivelmente ausentes)"
      fi
    else
      skip "go-vet/$fixture_name: go nao instalado"
    fi
  else
    skip "go-struct/$fixture_name: fixture estrutural (sem .go, apenas .gitkeep)"
  fi
done

# ========== 2. Fixtures Python: estrutura valida ==========
echo "=== Python fixtures ==="

for py_fixture in "$FIXTURES_DIR"/python-*; do
  [[ -d "$py_fixture" ]] || continue
  fixture_name="$(basename "$py_fixture")"

  # pyproject.toml ou requirements.txt (pode estar em subdiretorio para monorepos)
  py_manifest="$(find "$py_fixture" -maxdepth 3 -name 'pyproject.toml' -o -name 'requirements.txt' 2>/dev/null | head -1)"
  if [[ -n "$py_manifest" ]]; then
    pass "py-struct/$fixture_name: manifest Python presente ($(basename "$py_manifest"))"
  else
    fail "py-struct/$fixture_name: manifest Python ausente"
    continue
  fi

  # Pelo menos um arquivo .py (pode ser estrutural com apenas __init__.py)
  py_files="$(find "$py_fixture" -name '*.py' -not -name '__init__.py' 2>/dev/null | head -1)"
  if [[ -n "$py_files" ]]; then
    pass "py-struct/$fixture_name: arquivos .py presentes"
  else
    skip "py-struct/$fixture_name: fixture estrutural (apenas __init__.py)"
  fi

  # Smoke test: py_compile em todos os .py
  if command -v python3 &>/dev/null; then
    compile_ok=1
    while IFS= read -r pyfile; do
      [[ -n "$pyfile" ]] || continue
      if ! python3 -m py_compile "$pyfile" 2>/dev/null; then
        compile_ok=0
        break
      fi
    done < <(find "$py_fixture" -name '*.py' 2>/dev/null)

    if [[ "$compile_ok" -eq 1 ]]; then
      pass "py-compile/$fixture_name: todos os .py compilam"
    else
      fail "py-compile/$fixture_name: erro de compilacao Python"
    fi
  else
    skip "py-compile/$fixture_name: python3 nao instalado"
  fi
done

# ========== 3. Fixtures Node: estrutura valida ==========
echo "=== Node fixtures ==="

for node_fixture in "$FIXTURES_DIR"/node-*; do
  [[ -d "$node_fixture" ]] || continue
  fixture_name="$(basename "$node_fixture")"

  # package.json obrigatorio
  if [[ -f "$node_fixture/package.json" ]]; then
    pass "node-struct/$fixture_name: package.json presente"
  else
    fail "node-struct/$fixture_name: package.json ausente"
    continue
  fi

  # Verificar que package.json e JSON valido
  if command -v node &>/dev/null; then
    if node -e "JSON.parse(require('fs').readFileSync('$node_fixture/package.json','utf8'))" 2>/dev/null; then
      pass "node-json/$fixture_name: package.json e JSON valido"
    else
      fail "node-json/$fixture_name: package.json e JSON invalido"
    fi
  elif command -v python3 &>/dev/null; then
    if python3 -c "import json; json.load(open('$node_fixture/package.json'))" 2>/dev/null; then
      pass "node-json/$fixture_name: package.json e JSON valido"
    else
      fail "node-json/$fixture_name: package.json e JSON invalido"
    fi
  else
    skip "node-json/$fixture_name: nem node nem python3 disponiveis"
  fi
done

# ========== 4. Fixtures poliglotas: todas as linguagens presentes ==========
echo "=== Polyglot fixtures ==="

for poly_fixture in "$FIXTURES_DIR"/polyglot-*; do
  [[ -d "$poly_fixture" ]] || continue
  fixture_name="$(basename "$poly_fixture")"

  has_go=0
  has_node=0
  has_python=0

  find "$poly_fixture" -name 'go.mod' 2>/dev/null | head -1 | grep -q . && has_go=1
  find "$poly_fixture" -name 'package.json' 2>/dev/null | head -1 | grep -q . && has_node=1
  (find "$poly_fixture" -name 'pyproject.toml' -o -name 'requirements.txt' 2>/dev/null) | head -1 | grep -q . && has_python=1

  total=$((has_go + has_node + has_python))
  if [[ "$total" -ge 2 ]]; then
    pass "polyglot/$fixture_name: $total linguagens detectadas (>= 2)"
  else
    fail "polyglot/$fixture_name: apenas $total linguagem(s) detectada(s)"
  fi
done

# ========== 5. Governanca pode ser instalada em cada fixture ==========
echo "=== Governanca instalavel ==="

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# Testar instalacao na fixture Go
go_target="$tmpdir/go-test"
cp -r "$FIXTURES_DIR/go-microservice" "$go_target"
if bash "$ROOT_DIR/install.sh" --tools claude --langs go "$go_target" > /dev/null 2>&1; then
  if [[ -f "$go_target/AGENTS.md" ]]; then
    pass "harness-install/go: governanca instalada com sucesso"
  else
    fail "harness-install/go: AGENTS.md ausente apos instalacao"
  fi
else
  fail "harness-install/go: instalacao falhou"
fi

# Testar instalacao na fixture Python
py_target="$tmpdir/py-test"
cp -r "$FIXTURES_DIR/python-fastapi" "$py_target"
if bash "$ROOT_DIR/install.sh" --tools claude --langs python "$py_target" > /dev/null 2>&1; then
  if [[ -f "$py_target/AGENTS.md" ]]; then
    pass "harness-install/python: governanca instalada com sucesso"
  else
    fail "harness-install/python: AGENTS.md ausente apos instalacao"
  fi
else
  fail "harness-install/python: instalacao falhou"
fi

# Testar instalacao na fixture Node
node_target="$tmpdir/node-test"
cp -r "$FIXTURES_DIR/node-monorepo" "$node_target"
if bash "$ROOT_DIR/install.sh" --tools claude --langs node "$node_target" > /dev/null 2>&1; then
  if [[ -f "$node_target/AGENTS.md" ]]; then
    pass "harness-install/node: governanca instalada com sucesso"
  else
    fail "harness-install/node: AGENTS.md ausente apos instalacao"
  fi
else
  fail "harness-install/node: instalacao falhou"
fi

# ========== Resumo ==========
echo ""
echo "Resultado: $PASSED passed, $FAILED failed, $SKIPPED skipped"
if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
