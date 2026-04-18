#!/usr/bin/env bash
# Detecta comandos de fmt, test e lint disponiveis no projeto.
# Suporta multiplas linguagens simultaneamente (monorepos).
# Uso: bash detect-toolchain.sh [diretorio]
# Saida: JSON com chave por linguagem detectada, cada uma com fmt, test, lint.
# Exemplo: {"go":{"fmt":"gofmt -w .","test":"go test ./...","lint":"golangci-lint run"},"node":{"fmt":"pnpm run fmt","test":"pnpm run test","lint":"pnpm run lint"}}
# Se nenhuma linguagem for detectada, emite fallbacks de Makefile/Taskfile quando disponiveis.
set -euo pipefail

PROJECT_DIR="${1:-.}"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo '{"error":"diretorio nao encontrado"}' >&2
  exit 1
fi

cd "$PROJECT_DIR"

json_val() {
  if [[ -n "$1" ]]; then
    printf '"%s"' "$1"
  else
    printf 'null'
  fi
}

json_entry() {
  local lang="$1" fmt="$2" test_cmd="$3" lint="$4"
  printf '"%s":{"fmt":%s,"test":%s,"lint":%s}' "$lang" "$(json_val "$fmt")" "$(json_val "$test_cmd")" "$(json_val "$lint")"
}

entries=()

# --- Go ---
if [[ -f "go.mod" ]]; then
  go_fmt="gofmt -w ."
  go_test="go test ./..."
  go_lint=""
  if command -v golangci-lint >/dev/null 2>&1; then
    go_lint="golangci-lint run"
  elif [[ -f ".golangci.yml" ]] || [[ -f ".golangci.yaml" ]]; then
    go_lint="golangci-lint run"
  fi
  entries+=("$(json_entry "go" "$go_fmt" "$go_test" "$go_lint")")
fi

# --- Node/TypeScript ---
if [[ -f "package.json" ]]; then
  pm="npm"
  if [[ -f "pnpm-lock.yaml" ]]; then
    pm="pnpm"
  elif [[ -f "yarn.lock" ]]; then
    pm="yarn"
  elif [[ -f "bun.lockb" ]]; then
    pm="bun"
  fi

  scripts=""
  if command -v jq >/dev/null 2>&1; then
    scripts="$(jq -r '.scripts // {} | keys[]' package.json 2>/dev/null || true)"
  fi

  node_fmt=""
  if echo "$scripts" | grep -qx "fmt"; then
    node_fmt="$pm run fmt"
  elif echo "$scripts" | grep -qx "format"; then
    node_fmt="$pm run format"
  elif command -v prettier >/dev/null 2>&1 || [[ -f ".prettierrc" ]] || [[ -f ".prettierrc.json" ]]; then
    node_fmt="npx prettier --write ."
  fi

  node_test=""
  if echo "$scripts" | grep -qx "test"; then
    node_test="$pm run test"
  elif echo "$scripts" | grep -qx "test:unit"; then
    node_test="$pm run test:unit"
  fi

  node_lint=""
  if echo "$scripts" | grep -qx "lint"; then
    node_lint="$pm run lint"
  elif [[ -f ".eslintrc.js" ]] || [[ -f ".eslintrc.json" ]] || [[ -f "eslint.config.js" ]] || [[ -f "eslint.config.mjs" ]]; then
    node_lint="npx eslint ."
  fi

  entries+=("$(json_entry "node" "$node_fmt" "$node_test" "$node_lint")")
fi

# --- Python ---
if [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "Pipfile" ]]; then
  py_fmt=""
  py_lint=""
  if command -v ruff >/dev/null 2>&1 || [[ -f "ruff.toml" ]] || [[ -f ".ruff.toml" ]]; then
    py_fmt="ruff format ."
    py_lint="ruff check ."
  elif command -v black >/dev/null 2>&1; then
    py_fmt="black ."
    if command -v flake8 >/dev/null 2>&1; then
      py_lint="flake8 ."
    fi
  fi

  py_test=""
  if command -v pytest >/dev/null 2>&1 || [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]]; then
    py_test="pytest"
  fi

  entries+=("$(json_entry "python" "$py_fmt" "$py_test" "$py_lint")")
fi

# --- Rust ---
if [[ -f "Cargo.toml" ]]; then
  entries+=("$(json_entry "rust" "cargo fmt" "cargo test" "cargo clippy")")
fi

# --- Java (Maven) ---
if [[ -f "pom.xml" ]]; then
  entries+=("$(json_entry "java" "" "mvn test" "mvn verify")")
fi

# --- Java (Gradle) ---
if [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
  entries+=("$(json_entry "java" "" "gradle test" "gradle check")")
fi

# --- C# / .NET ---
if ls ./*.csproj >/dev/null 2>&1 || ls ./*.sln >/dev/null 2>&1; then
  entries+=("$(json_entry "dotnet" "dotnet format" "dotnet test" "dotnet format --verify-no-changes")")
fi

# --- Fallback: Makefile / Taskfile (quando nenhuma linguagem foi detectada) ---
if [[ ${#entries[@]} -eq 0 ]]; then
  fallback_fmt=""
  fallback_test=""
  fallback_lint=""

  if [[ -f "Makefile" ]]; then
    grep -q '^fmt:' Makefile 2>/dev/null && fallback_fmt="make fmt"
    grep -q '^test:' Makefile 2>/dev/null && fallback_test="make test"
    grep -q '^lint:' Makefile 2>/dev/null && fallback_lint="make lint"
  fi

  if [[ -f "Taskfile.yml" ]] || [[ -f "Taskfile.yaml" ]]; then
    if command -v task >/dev/null 2>&1; then
      [[ -z "$fallback_fmt" ]] && fallback_fmt="task fmt"
      [[ -z "$fallback_test" ]] && fallback_test="task test"
      [[ -z "$fallback_lint" ]] && fallback_lint="task lint"
    fi
  fi

  entries+=("$(json_entry "unknown" "$fallback_fmt" "$fallback_test" "$fallback_lint")")
fi

# --- Makefile/Taskfile overrides para linguagens detectadas ---
# Se uma linguagem foi detectada mas falta algum comando, tentar Makefile/Taskfile como complemento
if [[ ${#entries[@]} -gt 0 ]] && { [[ -f "Makefile" ]] || [[ -f "Taskfile.yml" ]] || [[ -f "Taskfile.yaml" ]]; }; then
  # Este bloco nao altera entries ja construidas — o override de Makefile/Taskfile
  # so se aplica ao fallback acima. Para linguagens detectadas, os comandos nativos prevalecem.
  :
fi

# Emitir JSON
printf '{'
for i in "${!entries[@]}"; do
  if [[ "$i" -gt 0 ]]; then
    printf ','
  fi
  printf '%s' "${entries[$i]}"
done
printf '}\n'
