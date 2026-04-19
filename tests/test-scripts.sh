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
  if echo "$output" | grep -q '"lint":"golangci-lint run"'; then
    pass "detect-toolchain: Go project retorna lint deterministico"
  else
    fail "detect-toolchain: Go project nao retorna lint deterministico"
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

# Caso: projeto Node com foco em workspace afetado
if output="$(bash "$DETECT_TOOLCHAIN" "$ROOT_DIR/tests/fixtures/node-monorepo" "apps/web/src/index.ts" 2>/dev/null)"; then
  if echo "$output" | grep -q '"test":"pnpm --filter @monorepo/web run test"'; then
    pass "detect-toolchain: Node respeita workspace focado"
  else
    fail "detect-toolchain: Node nao prioriza workspace focado"
  fi
else
  fail "detect-toolchain: Node com foco falhou"
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

# Caso: projeto Python com profundidade configuravel e foco em package
if output="$(DETECT_TOOLCHAIN_MAX_DEPTH=6 bash "$DETECT_TOOLCHAIN" "$ROOT_DIR/tests/fixtures/python-monorepo" "services/api/app/main.py" 2>/dev/null)"; then
  if echo "$output" | grep -q '"python":{'; then
    pass "detect-toolchain: Python respeita profundidade configuravel"
  else
    fail "detect-toolchain: Python nao detectado com profundidade configuravel"
  fi
else
  fail "detect-toolchain: Python com profundidade configuravel falhou"
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

# Caso: package.json com nome contendo aspas (json_escape edge case)
mkdir -p "$TMP_DIR/quote-project"
cat > "$TMP_DIR/quote-project/package.json" <<'QEOF'
{
  "name": "@scope/my\"pkg",
  "scripts": {
    "test": "jest",
    "lint": "eslint ."
  }
}
QEOF

if output="$(bash "$DETECT_TOOLCHAIN" "$TMP_DIR/quote-project" 2>/dev/null)"; then
  # Validar que o JSON e sintaticamente valido
  if python3 -c "import json, sys; json.loads(sys.argv[1])" "$output" 2>/dev/null; then
    pass "detect-toolchain: JSON valido com aspas no nome do package"
  else
    fail "detect-toolchain: JSON invalido com aspas no nome do package: $output"
  fi
else
  fail "detect-toolchain: falhou com aspas no nome do package"
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
RF-01 validado via teste unitario.

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
# semver-next.sh
# ============================================================
SEMVER_NEXT="$ROOT_DIR/scripts/semver-next.sh"

setup_git_repo() {
  local repo_dir="$1"
  mkdir -p "$repo_dir"
  git -C "$repo_dir" init -q
  git -C "$repo_dir" config user.name "Test User"
  git -C "$repo_dir" config user.email "test@example.com"
  git -C "$repo_dir" config commit.gpgsign false
  echo "1.0.0" > "$repo_dir/VERSION"
  cat > "$repo_dir/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased]

## [1.0.0] - 2025-05-01
EOF
}

make_commit() {
  local repo_dir="$1"
  local message="$2"
  printf '%s\n' "$message" > "$repo_dir/.git/COMMIT_EDITMSG.test"
  echo "$message" >> "$repo_dir/history.txt"
  git -C "$repo_dir" add VERSION CHANGELOG.md history.txt
  GIT_AUTHOR_DATE="2025-05-01T00:00:00Z" \
  GIT_COMMITTER_DATE="2025-05-01T00:00:00Z" \
    git -C "$repo_dir" commit -q -F "$repo_dir/.git/COMMIT_EDITMSG.test"
}

capture_output_value() {
  local output="$1"
  local key="$2"
  printf '%s\n' "$output" | sed -n "s/^${key}=//p" | head -1
}

# Caso: repositorio sem tags sinaliza bootstrap
BOOTSTRAP_REPO="$TMP_DIR/semver-bootstrap"
setup_git_repo "$BOOTSTRAP_REPO"
make_commit "$BOOTSTRAP_REPO" "docs: seed repository"

if output="$(bash "$SEMVER_NEXT" --repo "$BOOTSTRAP_REPO" 2>/dev/null)"; then
  if [[ "$(capture_output_value "$output" "action")" == "bootstrap" ]]; then
    pass "semver-next: sem tags retorna action bootstrap"
  else
    fail "semver-next: sem tags nao retorna action bootstrap"
  fi

  if [[ "$(capture_output_value "$output" "bootstrap_required")" == "true" ]]; then
    pass "semver-next: sem tags marca bootstrap_required=true"
  else
    fail "semver-next: sem tags nao marca bootstrap_required=true"
  fi

  if [[ "$(capture_output_value "$output" "target_version")" == "1.0.0" ]]; then
    pass "semver-next: sem tags preserva baseline 1.0.0"
  else
    fail "semver-next: sem tags nao preserva baseline 1.0.0"
  fi
else
  fail "semver-next: execucao falhou no caso sem tags"
fi

# Caso: feat gera minor
MINOR_REPO="$TMP_DIR/semver-minor"
setup_git_repo "$MINOR_REPO"
make_commit "$MINOR_REPO" "chore: baseline"
git -C "$MINOR_REPO" tag -a v1.0.0 -m "v1.0.0"
make_commit "$MINOR_REPO" "feat: add release dry-run"

if output="$(bash "$SEMVER_NEXT" --repo "$MINOR_REPO" 2>/dev/null)"; then
  if [[ "$(capture_output_value "$output" "bump")" == "minor" ]] && [[ "$(capture_output_value "$output" "target_version")" == "1.1.0" ]]; then
    pass "semver-next: feat gera bump minor e versao 1.1.0"
  else
    fail "semver-next: feat nao gera bump minor"
  fi
else
  fail "semver-next: execucao falhou no caso feat"
fi

# Caso: fix gera patch
PATCH_REPO="$TMP_DIR/semver-patch"
setup_git_repo "$PATCH_REPO"
make_commit "$PATCH_REPO" "chore: baseline"
git -C "$PATCH_REPO" tag -a v1.0.0 -m "v1.0.0"
make_commit "$PATCH_REPO" "fix: stabilize parser"

if output="$(bash "$SEMVER_NEXT" --repo "$PATCH_REPO" 2>/dev/null)"; then
  if [[ "$(capture_output_value "$output" "bump")" == "patch" ]] && [[ "$(capture_output_value "$output" "target_version")" == "1.0.1" ]]; then
    pass "semver-next: fix gera bump patch e versao 1.0.1"
  else
    fail "semver-next: fix nao gera bump patch"
  fi
else
  fail "semver-next: execucao falhou no caso fix"
fi

# Caso: feat! gera major
MAJOR_BANG_REPO="$TMP_DIR/semver-major-bang"
setup_git_repo "$MAJOR_BANG_REPO"
make_commit "$MAJOR_BANG_REPO" "chore: baseline"
git -C "$MAJOR_BANG_REPO" tag -a v1.0.0 -m "v1.0.0"
make_commit "$MAJOR_BANG_REPO" "feat!: change public contract"

if output="$(bash "$SEMVER_NEXT" --repo "$MAJOR_BANG_REPO" 2>/dev/null)"; then
  if [[ "$(capture_output_value "$output" "bump")" == "major" ]] && [[ "$(capture_output_value "$output" "target_version")" == "2.0.0" ]]; then
    pass "semver-next: feat! gera bump major e versao 2.0.0"
  else
    fail "semver-next: feat! nao gera bump major"
  fi
else
  fail "semver-next: execucao falhou no caso feat!"
fi

# Caso: BREAKING CHANGE no corpo gera major
MAJOR_BODY_REPO="$TMP_DIR/semver-major-body"
setup_git_repo "$MAJOR_BODY_REPO"
make_commit "$MAJOR_BODY_REPO" "chore: baseline"
git -C "$MAJOR_BODY_REPO" tag -a v1.0.0 -m "v1.0.0"
cat > "$MAJOR_BODY_REPO/.git/COMMIT_EDITMSG.test" <<'EOF'
refactor: replace release parser

BREAKING CHANGE: output contract renamed
EOF
echo "breaking body" >> "$MAJOR_BODY_REPO/history.txt"
git -C "$MAJOR_BODY_REPO" add VERSION CHANGELOG.md history.txt
GIT_AUTHOR_DATE="2025-05-01T00:00:00Z" \
GIT_COMMITTER_DATE="2025-05-01T00:00:00Z" \
  git -C "$MAJOR_BODY_REPO" commit -q -F "$MAJOR_BODY_REPO/.git/COMMIT_EDITMSG.test"

if output="$(bash "$SEMVER_NEXT" --repo "$MAJOR_BODY_REPO" 2>/dev/null)"; then
  if [[ "$(capture_output_value "$output" "bump")" == "major" ]]; then
    pass "semver-next: BREAKING CHANGE no corpo gera major"
  else
    fail "semver-next: BREAKING CHANGE no corpo nao gera major"
  fi
else
  fail "semver-next: execucao falhou no caso BREAKING CHANGE"
fi

# Caso: commits nao elegiveis resultam em no_release
NO_RELEASE_REPO="$TMP_DIR/semver-no-release"
setup_git_repo "$NO_RELEASE_REPO"
make_commit "$NO_RELEASE_REPO" "chore: baseline"
git -C "$NO_RELEASE_REPO" tag -a v1.0.0 -m "v1.0.0"
make_commit "$NO_RELEASE_REPO" "docs: expand release notes"

if output="$(bash "$SEMVER_NEXT" --repo "$NO_RELEASE_REPO" 2>/dev/null)"; then
  if [[ "$(capture_output_value "$output" "action")" == "no_release" ]] && [[ "$(capture_output_value "$output" "bump")" == "no_release" ]]; then
    pass "semver-next: commits nao elegiveis resultam em no_release"
  else
    fail "semver-next: commits nao elegiveis nao resultam em no_release"
  fi
else
  fail "semver-next: execucao falhou no caso no_release"
fi

for commit_type in docs chore test ci build refactor; do
  NON_RELEASE_REPO="$TMP_DIR/semver-non-release-$commit_type"
  setup_git_repo "$NON_RELEASE_REPO"
  make_commit "$NON_RELEASE_REPO" "chore: baseline"
  git -C "$NON_RELEASE_REPO" tag -a v1.0.0 -m "v1.0.0"
  make_commit "$NON_RELEASE_REPO" "$commit_type: non release change"

  if output="$(bash "$SEMVER_NEXT" --repo "$NON_RELEASE_REPO" 2>/dev/null)"; then
    if [[ "$(capture_output_value "$output" "action")" == "no_release" ]] &&
       [[ "$(capture_output_value "$output" "bump")" == "no_release" ]] &&
       [[ "$(capture_output_value "$output" "release_required")" == "false" ]]; then
      pass "semver-next: $commit_type sem ! nao cria release"
    else
      fail "semver-next: $commit_type sem ! deveria resultar em no_release"
    fi
  else
    fail "semver-next: execucao falhou no caso $commit_type sem !"
  fi
done

# Caso: mesma faixa de commits produz saida estavel
if first_output="$(bash "$SEMVER_NEXT" --repo "$MINOR_REPO" 2>/dev/null)" && second_output="$(bash "$SEMVER_NEXT" --repo "$MINOR_REPO" 2>/dev/null)"; then
  if [[ "$first_output" == "$second_output" ]]; then
    pass "semver-next: mesma faixa de commits produz saida estavel"
  else
    fail "semver-next: mesma faixa de commits nao produz saida estavel"
  fi
else
  fail "semver-next: execucao falhou no teste de estabilidade"
fi

# ============================================================
# update-version.sh + update-changelog-release.sh
# ============================================================
UPDATE_VERSION="$ROOT_DIR/scripts/update-version.sh"
UPDATE_CHANGELOG="$ROOT_DIR/scripts/update-changelog-release.sh"

MATERIALIZE_REPO="$TMP_DIR/semver-materialize"
setup_git_repo "$MATERIALIZE_REPO"

cat > "$MATERIALIZE_REPO/CHANGELOG.expected.md" <<'EOF'
# Changelog

## [Unreleased]

## [1.1.0] - 2025-05-10

### Added
- New release automation

### Fixed
- Stable changelog parser

## [1.0.0] - 2025-05-01
EOF

cat > "$MATERIALIZE_REPO/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased]

### Added
- New release automation

### Fixed
- Stable changelog parser

## [1.0.0] - 2025-05-01
EOF

version_before="$(cat "$MATERIALIZE_REPO/VERSION")"
if bash "$UPDATE_VERSION" --version 1.1.0 --version-file "$MATERIALIZE_REPO/VERSION" &&
   bash "$UPDATE_CHANGELOG" --version 1.1.0 --date 2025-05-10 --changelog-file "$MATERIALIZE_REPO/CHANGELOG.md"; then
  version_after="$(cat "$MATERIALIZE_REPO/VERSION")"
  if [[ "$version_before" == "1.0.0" ]] && [[ "$version_after" == "1.1.0" ]]; then
    pass "release-materialization: VERSION atualizado de 1.0.0 para 1.1.0"
  else
    fail "release-materialization: VERSION nao foi atualizado corretamente"
  fi

  if cmp -s "$MATERIALIZE_REPO/CHANGELOG.expected.md" "$MATERIALIZE_REPO/CHANGELOG.md"; then
    pass "release-materialization: changelog promovido com secao Unreleased preservada"
  else
    fail "release-materialization: changelog promovido difere do snapshot esperado"
  fi
else
  fail "release-materialization: scripts falharam no caminho feliz"
fi

materialized_once="$(cat "$MATERIALIZE_REPO/CHANGELOG.md")"
if bash "$UPDATE_CHANGELOG" --version 1.1.0 --date 2025-05-10 --changelog-file "$MATERIALIZE_REPO/CHANGELOG.md"; then
  materialized_twice="$(cat "$MATERIALIZE_REPO/CHANGELOG.md")"
  if [[ "$materialized_once" == "$materialized_twice" ]]; then
    pass "release-materialization: rerun do changelog e idempotente"
  else
    fail "release-materialization: rerun do changelog alterou arquivo ja materializado"
  fi
else
  fail "release-materialization: rerun do changelog falhou"
fi

if bash "$UPDATE_VERSION" --version 1.1.0 --version-file "$MATERIALIZE_REPO/VERSION"; then
  if [[ "$(cat "$MATERIALIZE_REPO/VERSION")" == "1.1.0" ]]; then
    pass "release-materialization: rerun do VERSION e idempotente"
  else
    fail "release-materialization: rerun do VERSION alterou conteudo esperado"
  fi
else
  fail "release-materialization: rerun do VERSION falhou"
fi

INVALID_CHANGELOG="$TMP_DIR/invalid-changelog.md"
cat > "$INVALID_CHANGELOG" <<'EOF'
# Changelog

## [1.0.0] - 2025-05-01
EOF

if bash "$UPDATE_CHANGELOG" --version 1.1.0 --date 2025-05-10 --changelog-file "$INVALID_CHANGELOG" > /dev/null 2>&1; then
  fail "release-materialization: changelog sem Unreleased foi aceito"
else
  pass "release-materialization: changelog sem Unreleased e rejeitado"
fi

echo "v1.0.0" > "$TMP_DIR/invalid-version.txt"
if bash "$UPDATE_VERSION" --version 1.1.0 --version-file "$TMP_DIR/invalid-version.txt" > /dev/null 2>&1; then
  fail "release-materialization: VERSION atual invalido foi aceito"
else
  pass "release-materialization: VERSION atual invalido e rejeitado"
fi

# ============================================================
# release-dry-run workflow
# ============================================================
RELEASE_DRY_RUN_WORKFLOW="$ROOT_DIR/.github/workflows/release-dry-run.yml"

if [[ -f "$RELEASE_DRY_RUN_WORKFLOW" ]]; then
  pass "release-dry-run: workflow file criado"
else
  fail "release-dry-run: workflow file ausente"
fi

if grep -Eq '^  workflow_dispatch:$' "$RELEASE_DRY_RUN_WORKFLOW"; then
  pass "release-dry-run: workflow_dispatch habilitado"
else
  fail "release-dry-run: workflow_dispatch ausente"
fi

if grep -Eq 'fetch-depth:[[:space:]]*0' "$RELEASE_DRY_RUN_WORKFLOW" &&
   grep -Eq 'fetch-tags:[[:space:]]*true' "$RELEASE_DRY_RUN_WORKFLOW" &&
   grep -Eq 'git fetch --force --tags' "$RELEASE_DRY_RUN_WORKFLOW"; then
  pass "release-dry-run: checkout com historico completo e tags"
else
  fail "release-dry-run: checkout nao garante historico completo com tags"
fi

if grep -Eq 'bash scripts/semver-next\.sh' "$RELEASE_DRY_RUN_WORKFLOW" &&
   grep -Eq 'bash scripts/update-version\.sh' "$RELEASE_DRY_RUN_WORKFLOW" &&
   grep -Eq 'bash scripts/update-changelog-release\.sh' "$RELEASE_DRY_RUN_WORKFLOW"; then
  pass "release-dry-run: workflow invoca scripts de semver e materializacao"
else
  fail "release-dry-run: workflow nao invoca todos os scripts esperados"
fi

if grep -Eq 'git --no-pager diff -- VERSION CHANGELOG\.md' "$RELEASE_DRY_RUN_WORKFLOW" &&
   grep -Eq 'git status --short VERSION CHANGELOG\.md' "$RELEASE_DRY_RUN_WORKFLOW"; then
  pass "release-dry-run: workflow exibe diff e arquivos afetados"
else
  fail "release-dry-run: workflow nao exibe diff esperado"
fi

if grep -Eq '^permissions:$' "$RELEASE_DRY_RUN_WORKFLOW" &&
   grep -Eq 'contents:[[:space:]]*read' "$RELEASE_DRY_RUN_WORKFLOW" &&
   grep -Eq 'persist-credentials:[[:space:]]*false' "$RELEASE_DRY_RUN_WORKFLOW" &&
   grep -Eq 'dry-run nao pode criar tags locais' "$RELEASE_DRY_RUN_WORKFLOW"; then
  pass "release-dry-run: workflow define guard rails sem efeitos colaterais"
else
  fail "release-dry-run: workflow sem guard rails completos"
fi

# ============================================================
# release workflow
# ============================================================
RELEASE_WORKFLOW="$ROOT_DIR/.github/workflows/release.yml"

if [[ -f "$RELEASE_WORKFLOW" ]]; then
  pass "release: workflow file criado"
else
  fail "release: workflow file ausente"
fi

if grep -Eq '^  push:$' "$RELEASE_WORKFLOW" &&
   grep -Eq '^      - main$' "$RELEASE_WORKFLOW"; then
  pass "release: workflow limitado a push em main"
else
  fail "release: workflow nao esta restrito a push em main"
fi

if grep -Eq '^concurrency:$' "$RELEASE_WORKFLOW" &&
   grep -Eq 'group:[[:space:]]*release-\$\{\{ github\.ref \}\}' "$RELEASE_WORKFLOW" &&
   grep -Eq 'cancel-in-progress:[[:space:]]*false' "$RELEASE_WORKFLOW"; then
  pass "release: workflow define concorrencia por ref"
else
  fail "release: workflow sem protecao de concorrencia esperada"
fi

if grep -Eq 'contains\(github\.event\.head_commit\.message, '\''\[skip ci\]'\''\)' "$RELEASE_WORKFLOW" &&
   grep -Eq 'chore\(release\): \$\{target_tag\} \[skip ci\]' "$RELEASE_WORKFLOW"; then
  pass "release: workflow evita loop com commit automatizado"
else
  fail "release: workflow nao protege contra loop de CI"
fi

if grep -Eq 'fetch-depth:[[:space:]]*0' "$RELEASE_WORKFLOW" &&
   grep -Eq 'fetch-tags:[[:space:]]*true' "$RELEASE_WORKFLOW" &&
   grep -Eq 'git fetch --force --tags origin \+refs/heads/main:refs/remotes/origin/main' "$RELEASE_WORKFLOW"; then
  pass "release: workflow revalida tags e branch main antes de publicar"
else
  fail "release: workflow nao refaz fetch completo antes de publicar"
fi

if grep -Eq 'bash scripts/semver-next\.sh' "$RELEASE_WORKFLOW" &&
   grep -Eq 'bash scripts/update-version\.sh' "$RELEASE_WORKFLOW" &&
   grep -Eq 'bash scripts/update-changelog-release\.sh' "$RELEASE_WORKFLOW"; then
  pass "release: workflow usa scripts canonicos de decisao e materializacao"
else
  fail "release: workflow nao usa todos os scripts canonicos esperados"
fi

if grep -Eq 'git rev-parse -q --verify "refs/tags/\$target_tag"' "$RELEASE_WORKFLOW" &&
   grep -Eq 'rerun deve ser no-op' "$RELEASE_WORKFLOW"; then
  pass "release: workflow trata rerun com tag existente como no-op"
else
  fail "release: workflow nao protege rerun com tag existente"
fi

if grep -Eq 'git log origin/main --format=%s \| grep -Fx "\$release_commit_message"' "$RELEASE_WORKFLOW" &&
   grep -Eq 'ERRO: commit de release \$release_commit_message existe em origin/main sem o tag \$target_tag' "$RELEASE_WORKFLOW"; then
  pass "release: workflow falha explicitamente em divergencia commit/tag"
else
  fail "release: workflow nao detecta divergencia commit/tag"
fi

if grep -Eq 'VERSION=1\.0\.0' "$RELEASE_WORKFLOW" &&
   grep -Eq '## \[1\.0\.0\] - 2025-05-01' "$RELEASE_WORKFLOW" &&
   grep -Eq 'mode=bootstrap' "$RELEASE_WORKFLOW"; then
  pass "release: workflow documenta e valida bootstrap inicial"
else
  fail "release: workflow nao cobre bootstrap inicial"
fi

if grep -Eq 'git commit -m "\$\{\{ steps\.release_guard\.outputs\.release_commit_message \}\}"' "$RELEASE_WORKFLOW" &&
   grep -Eq 'git tag -a "\$\{\{ steps\.release_guard\.outputs\.target_tag \}\}" -m "\$\{\{ steps\.release_guard\.outputs\.target_tag \}\}"' "$RELEASE_WORKFLOW" &&
   grep -Eq 'git push --atomic origin HEAD:main "refs/tags/\$\{\{ steps\.release_guard\.outputs\.target_tag \}\}"' "$RELEASE_WORKFLOW"; then
  pass "release: workflow cria commit e tag anotada para release real"
else
  fail "release: workflow nao materializa commit e tag como esperado"
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
