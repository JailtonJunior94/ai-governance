#!/usr/bin/env bash
# Testes de integridade semantica: valida que cada SKILL.md referencia apenas
# arquivos que existem e que fixtures de linguagem sao detectados corretamente.
# Uso: bash tests/test-skill-references.sh

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

# ============================================================
# Validar que todas as referencias em SKILL.md apontam para
# arquivos que existem no disco.
# ============================================================
check_skill_references() {
  local skill_name="$1"
  local skill_dir="$ROOT_DIR/.agents/skills/$skill_name"
  local skill_file="$skill_dir/SKILL.md"

  if [[ ! -f "$skill_file" ]]; then
    fail "$skill_name: SKILL.md nao encontrado"
    return
  fi

  local has_missing=0

  # Extrai paths de referencias locais (references/*.md), excluindo cross-skill
  while IFS= read -r ref_path; do
    [[ -n "$ref_path" ]] || continue
    local full_path="$skill_dir/$ref_path"
    if [[ ! -f "$full_path" ]]; then
      fail "$skill_name: referencia inexistente: $ref_path"
      has_missing=1
    fi
  done < <(grep -v '\.\./agent-governance/' "$skill_file" | grep -oE 'references/[a-z0-9_-]+\.md' | sort -u)

  # Extrai paths de referencias cross-skill (../agent-governance/references/*.md)
  while IFS= read -r ref_path; do
    [[ -n "$ref_path" ]] || continue
    local full_path="$skill_dir/$ref_path"
    if [[ ! -f "$full_path" ]]; then
      fail "$skill_name: referencia cross-skill inexistente: $ref_path"
      has_missing=1
    fi
  done < <(grep -oE '\.\./agent-governance/references/[a-z0-9_-]+\.md' "$skill_file" | sort -u)

  if [[ "$has_missing" -eq 0 ]]; then
    pass "$skill_name: todas as referencias existem"
  fi
}

# Verificar todas as skills de linguagem
check_skill_references "go-implementation"
check_skill_references "node-implementation"
check_skill_references "python-implementation"
check_skill_references "agent-governance"
check_skill_references "object-calisthenics-go"
check_skill_references "bugfix"

# ============================================================
# Validar que fixtures de linguagem correspondem a skills
# corretas via detect-toolchain.sh
# ============================================================
DETECT_TOOLCHAIN="$ROOT_DIR/.agents/skills/agent-governance/scripts/detect-toolchain.sh"

# Go fixture
if output="$(bash "$DETECT_TOOLCHAIN" "$ROOT_DIR/tests/fixtures/go-microservice" 2>/dev/null)"; then
  if echo "$output" | grep -q '"go":{'; then
    pass "fixture-go-microservice: detectado como Go"
  else
    fail "fixture-go-microservice: Go nao detectado"
  fi
  if echo "$output" | grep -q '"lint":"golangci-lint run"'; then
    pass "fixture-go-microservice: lint Go deterministico"
  else
    fail "fixture-go-microservice: lint Go nao deterministico"
  fi
else
  fail "fixture-go-microservice: detect-toolchain falhou"
fi

# Node fixture
if output="$(bash "$DETECT_TOOLCHAIN" "$ROOT_DIR/tests/fixtures/node-monorepo" 2>/dev/null)"; then
  if echo "$output" | grep -q '"node":{'; then
    pass "fixture-node-monorepo: detectado como Node"
  else
    fail "fixture-node-monorepo: Node nao detectado"
  fi
else
  fail "fixture-node-monorepo: detect-toolchain falhou"
fi

# Python fixture
if output="$(bash "$DETECT_TOOLCHAIN" "$ROOT_DIR/tests/fixtures/python-fastapi" 2>/dev/null)"; then
  if echo "$output" | grep -q '"python":{'; then
    pass "fixture-python-fastapi: detectado como Python"
  else
    fail "fixture-python-fastapi: Python nao detectado"
  fi
else
  fail "fixture-python-fastapi: detect-toolchain falhou"
fi

# Python fixture em monorepo profundo com foco em path afetado
if output="$(DETECT_TOOLCHAIN_MAX_DEPTH=6 bash "$DETECT_TOOLCHAIN" "$ROOT_DIR/tests/fixtures/python-monorepo" "services/api/src/main.py" 2>/dev/null)"; then
  if echo "$output" | grep -q '"python":{'; then
    pass "fixture-python-monorepo: detectado com profundidade configuravel"
  else
    fail "fixture-python-monorepo: Python nao detectado com profundidade configuravel"
  fi
else
  fail "fixture-python-monorepo: detect-toolchain com profundidade configuravel falhou"
fi

# ============================================================
# Validar que SKILL.md de linguagem contem secoes mandatorias
# ============================================================
check_mandatory_sections() {
  local skill_name="$1"
  local skill_file="$ROOT_DIR/.agents/skills/$skill_name/SKILL.md"

  for section in "Etapa 1:" "Etapa 2:" "Economia de contexto" "Tratamento de Erros"; do
    if grep -q "$section" "$skill_file"; then
      pass "$skill_name: secao '$section' presente"
    else
      fail "$skill_name: secao '$section' ausente"
    fi
  done
}

check_mandatory_sections "go-implementation"
check_mandatory_sections "node-implementation"
check_mandatory_sections "python-implementation"

# ============================================================
# Validar que architecture.md e mandatorio (Etapa 1) em todas
# as skills de linguagem
# ============================================================
for skill in go-implementation node-implementation python-implementation; do
  skill_file="$ROOT_DIR/.agents/skills/$skill/SKILL.md"
  # Extrair bloco da Etapa 1 (entre "Etapa 1:" e "Etapa 2:" ou proximo header)
  etapa1_block="$(sed -n '/Etapa 1:/,/Etapa 2:/p' "$skill_file")"
  if echo "$etapa1_block" | grep -q 'architecture.md'; then
    pass "$skill: architecture.md mandatorio na Etapa 1"
  else
    fail "$skill: architecture.md NAO esta na Etapa 1"
  fi
done

# ============================================================
# Validar que todo SKILL.md carrega base obrigatoria
# (AGENTS.md + agent-governance) nas primeiras linhas
# ============================================================
for skill_dir in "$ROOT_DIR/.agents/skills"/*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  skill_file="$skill_dir/SKILL.md"
  [[ -f "$skill_file" ]] || continue

  # agent-governance nao precisa referenciar a si mesmo
  if [[ "$skill_name" == "agent-governance" ]]; then
    if grep -q 'AGENTS\.md' "$skill_file"; then
      pass "$skill_name: referencia AGENTS.md"
    else
      fail "$skill_name: nao referencia AGENTS.md"
    fi
    continue
  fi

  # Todas as outras skills devem mencionar o contrato de carga base (AGENTS.md)
  if grep -q 'AGENTS\.md' "$skill_file"; then
    pass "$skill_name: referencia contrato AGENTS.md"
  else
    fail "$skill_name: NAO referencia contrato AGENTS.md"
  fi

  # Skills que alteram codigo devem referenciar agent-governance
  case "$skill_name" in
    go-implementation|node-implementation|python-implementation|execute-task|refactor|bugfix|object-calisthenics-go)
      if grep -q 'agent-governance' "$skill_file"; then
        pass "$skill_name: referencia agent-governance"
      else
        fail "$skill_name: NAO referencia agent-governance"
      fi
      ;;
  esac
done

# ============================================================
# Validar depends_on: skills declaradas existem no disco
# ============================================================
validate_depends_on() {
  local skill_name="$1"
  local skill_file="$ROOT_DIR/.agents/skills/$skill_name/SKILL.md"

  [[ -f "$skill_file" ]] || return 0

  # Extrair campo depends_on do frontmatter (formato: depends_on: [a, b])
  local deps_line
  deps_line="$(awk '/^---$/{n++; next} n==1 && /^depends_on:/{print; exit}' "$skill_file")"
  [[ -n "$deps_line" ]] || return 0

  # Extrair nomes das dependencias sem colar entradas adjacentes.
  while IFS= read -r dep; do
    dep="$(printf '%s' "$dep" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -n "$dep" ]] || continue
    if [[ -d "$ROOT_DIR/.agents/skills/$dep" ]]; then
      pass "$skill_name: depends_on '$dep' existe"
    else
      fail "$skill_name: depends_on '$dep' NAO encontrada"
    fi
  done < <(printf '%s' "$deps_line" | sed 's/^depends_on:[[:space:]]*\[//;s/\][[:space:]]*$//' | tr ',' '\n')
}

for skill_dir in "$ROOT_DIR/.agents/skills"/*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  validate_depends_on "$skill_name"
done

# ============================================================
# Resumo
# ============================================================
echo ""
echo "Resultado: $PASSED passed, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
