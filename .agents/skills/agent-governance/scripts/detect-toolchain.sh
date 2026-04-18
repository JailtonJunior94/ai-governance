#!/usr/bin/env bash
# Detecta comandos de fmt, test e lint disponiveis no projeto.
# Suporta multiplas linguagens simultaneamente (inclusive manifests em subdiretorios).
# Uso: bash detect-toolchain.sh [diretorio]
# Saida: JSON com chave por linguagem detectada, cada uma com fmt, test, lint.
set -euo pipefail

PROJECT_DIR="${1:-.}"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo '{"error":"diretorio nao encontrado"}' >&2
  exit 1
fi

cd "$PROJECT_DIR"

find_manifests() {
  local pattern="$1"
  local maxdepth="${2:-4}"

  find . -maxdepth "$maxdepth" -type f -name "$pattern" \
    -not -path "*/node_modules/*" \
    -not -path "*/vendor/*" \
    -not -path "*/dist/*" \
    -not -path "*/build/*" \
    -not -path "*/__pycache__/*" \
    | LC_ALL=C sort
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

json_val() {
  if [[ -n "$1" ]]; then
    printf '"%s"' "$(json_escape "$1")"
  else
    printf 'null'
  fi
}

json_entry() {
  local lang="$1" fmt="$2" test_cmd="$3" lint="$4"
  printf '"%s":{"fmt":%s,"test":%s,"lint":%s}' "$lang" "$(json_val "$fmt")" "$(json_val "$test_cmd")" "$(json_val "$lint")"
}

has_python_dev_package() {
  local manifest="$1"
  local target="$2"

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$manifest" "$target" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
target = sys.argv[2].lower()
text = path.read_text(encoding="utf-8")

for match in re.finditer(r'(?ms)^\[project\.optional-dependencies(?:\.[^\]]+)?\](.*?)(?:^\[|\Z)', text):
    deps = re.findall(r'"([^"]+)"', match.group(1))
    for dep in deps:
        name = re.split(r"[<>=!~ \[]", dep, 1)[0].strip().lower()
        if name == target:
            sys.exit(0)

sys.exit(1)
PY
    return
  fi

  # Fallback: grep for the target name inside optional-dependencies sections
  grep -qi "\"${target}[\"<>=!~ []" "$manifest" 2>/dev/null
}

package_scripts_bash() {
  local pkg="$1"
  # Extract keys from "scripts": { ... } block using sed+grep.
  # Works for standard package.json formatting (one key per line).
  sed -n '/"scripts"[[:space:]]*:/,/^[[:space:]]*}/p' "$pkg" 2>/dev/null \
    | grep -o '"[^"]*"[[:space:]]*:' \
    | sed 's/"//g; s/[[:space:]]*:$//' \
    | grep -v '^scripts$' \
    || true
}

package_scripts() {
  local pkg="$1"

  if command -v jq >/dev/null 2>&1; then
    jq -r '.scripts // {} | keys[]' "$pkg" 2>/dev/null || true
    return
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$pkg" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
for key in sorted((data.get("scripts") or {}).keys()):
    print(key)
PY
    return
  fi

  # Pure-bash fallback (no jq, no python3)
  package_scripts_bash "$pkg"
}

package_name_bash() {
  local pkg="$1"
  grep -m1 '"name"' "$pkg" 2>/dev/null \
    | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' \
    || true
}

package_name() {
  local pkg="$1"

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$pkg" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
name = data.get("name", "")
if name:
    print(name)
PY
    return
  fi

  # Pure-bash fallback (no python3)
  package_name_bash "$pkg"
}

relative_dir() {
  local manifest="$1"
  local dir

  dir="$(dirname "$manifest")"
  dir="${dir#./}"

  if [[ "$dir" == "." ]]; then
    printf ''
  else
    printf '%s' "$dir"
  fi
}

entries=()

# --- Go ---
if [[ -f "go.mod" ]] || [[ -f "go.work" ]] || find_manifests "go.mod" 4 | read -r _; then
  go_fmt="gofmt -w ."
  go_test="go test ./..."
  go_lint=""

  if command -v golangci-lint >/dev/null 2>&1; then
    go_lint="golangci-lint run"
  elif [[ -f ".golangci.yml" ]] || [[ -f ".golangci.yaml" ]] || [[ -f ".golangci.toml" ]]; then
    go_lint="golangci-lint run"
  fi

  entries+=("$(json_entry "go" "$go_fmt" "$go_test" "$go_lint")")
fi

# --- Node/TypeScript ---
node_packages=()
while IFS= read -r pkg; do
  [[ -n "$pkg" ]] || continue
  node_packages+=("$pkg")
done < <(find_manifests "package.json" 4)
if [[ ${#node_packages[@]} -gt 0 ]]; then
  pm="npm"
  if [[ -f "pnpm-lock.yaml" || -f "pnpm-workspace.yaml" ]]; then
    pm="pnpm"
  elif [[ -f "yarn.lock" ]]; then
    pm="yarn"
  elif [[ -f "bun.lockb" ]]; then
    pm="bun"
  fi

  node_fmt=""
  node_test=""
  node_lint=""

  for pkg in "${node_packages[@]}"; do
    scripts="$(package_scripts "$pkg")"
    pkg_name="$(package_name "$pkg")"
    pkg_dir="$(relative_dir "$pkg")"

    cmd_prefix="$pm run"
    if [[ "$pkg_dir" != "" ]]; then
      if [[ -n "$pkg_name" && "$pm" == "pnpm" ]]; then
        cmd_prefix="pnpm --filter $pkg_name run"
      elif [[ -n "$pkg_name" && "$pm" == "yarn" ]]; then
        cmd_prefix="yarn workspace $pkg_name run"
      else
        cmd_prefix="cd $pkg_dir && $pm run"
      fi
    fi

    if [[ -z "$node_fmt" ]]; then
      if echo "$scripts" | grep -qx "fmt"; then
        node_fmt="$cmd_prefix fmt"
      elif echo "$scripts" | grep -qx "format"; then
        node_fmt="$cmd_prefix format"
      fi
    fi

    if [[ -z "$node_test" ]]; then
      if echo "$scripts" | grep -qx "test"; then
        node_test="$cmd_prefix test"
      elif echo "$scripts" | grep -qx "test:unit"; then
        node_test="$cmd_prefix test:unit"
      fi
    fi

    if [[ -z "$node_lint" ]]; then
      if echo "$scripts" | grep -qx "lint"; then
        node_lint="$cmd_prefix lint"
      fi
    fi
  done

  if [[ -z "$node_fmt" ]]; then
    if command -v prettier >/dev/null 2>&1 || [[ -f ".prettierrc" ]] || [[ -f ".prettierrc.json" ]]; then
      node_fmt="npx prettier --write ."
    fi
  fi

  if [[ -z "$node_lint" ]]; then
    if [[ -f ".eslintrc.js" ]] || [[ -f ".eslintrc.json" ]] || [[ -f "eslint.config.js" ]] || [[ -f "eslint.config.mjs" ]]; then
      node_lint="npx eslint ."
    fi
  fi

  entries+=("$(json_entry "node" "$node_fmt" "$node_test" "$node_lint")")
fi

# --- Python ---
pyprojects=()
while IFS= read -r manifest; do
  [[ -n "$manifest" ]] || continue
  pyprojects+=("$manifest")
done < <(find_manifests "pyproject.toml" 4)

requirements=()
while IFS= read -r manifest; do
  [[ -n "$manifest" ]] || continue
  requirements+=("$manifest")
done < <(find_manifests "requirements.txt" 4)
if [[ ${#pyprojects[@]} -gt 0 || ${#requirements[@]} -gt 0 || -f "setup.py" || -f "Pipfile" ]]; then
  py_fmt=""
  py_test=""
  py_lint=""

  for manifest in "${pyprojects[@]}"; do
    if [[ -z "$py_fmt" || -z "$py_lint" ]]; then
      if grep -q '^\[tool\.ruff' "$manifest" 2>/dev/null || has_python_dev_package "$manifest" "ruff" >/dev/null 2>&1; then
        [[ -z "$py_fmt" ]] && py_fmt="ruff format ."
        [[ -z "$py_lint" ]] && py_lint="ruff check ."
      fi
    fi

    if [[ -z "$py_test" ]]; then
      if grep -q '^\[tool\.pytest' "$manifest" 2>/dev/null || has_python_dev_package "$manifest" "pytest" >/dev/null 2>&1; then
        py_test="pytest"
      fi
    fi
  done

  if [[ -z "$py_fmt" ]] && command -v black >/dev/null 2>&1; then
    py_fmt="black ."
  fi

  if [[ -z "$py_lint" ]] && command -v flake8 >/dev/null 2>&1; then
    py_lint="flake8 ."
  fi

  if [[ -z "$py_test" ]] && [[ -f "pytest.ini" || -d "tests" ]]; then
    py_test="pytest"
  fi

  entries+=("$(json_entry "python" "$py_fmt" "$py_test" "$py_lint")")
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

printf '{'
for i in "${!entries[@]}"; do
  if [[ "$i" -gt 0 ]]; then
    printf ','
  fi
  printf '%s' "${entries[$i]}"
done
printf '}\n'
