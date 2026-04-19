#!/usr/bin/env bash
# Atualiza o arquivo VERSION com um SemVer sem prefixo "v".

set -euo pipefail

usage() {
  cat <<'EOF'
Uso: bash scripts/update-version.sh --version <MAJOR.MINOR.PATCH> [--version-file <path>]
EOF
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

is_semver() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

VERSION_FILE="VERSION"
TARGET_VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      TARGET_VERSION="${2:-}"
      shift 2
      ;;
    --version-file)
      VERSION_FILE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERRO: argumento desconhecido: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$TARGET_VERSION" ]]; then
  echo "ERRO: --version e obrigatorio" >&2
  usage >&2
  exit 1
fi

if ! is_semver "$TARGET_VERSION"; then
  echo "ERRO: versao alvo fora do formato SemVer esperado: $TARGET_VERSION" >&2
  exit 1
fi

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "ERRO: arquivo VERSION nao encontrado: $VERSION_FILE" >&2
  exit 1
fi

current_version="$(trim "$(cat "$VERSION_FILE")")"
if ! is_semver "$current_version"; then
  echo "ERRO: VERSION atual fora do formato SemVer esperado: $current_version" >&2
  exit 1
fi

if [[ "$current_version" == "$TARGET_VERSION" ]]; then
  exit 0
fi

printf '%s\n' "$TARGET_VERSION" > "$VERSION_FILE"
