#!/usr/bin/env bash
# Calcula a proxima decisao de release SemVer a partir do ultimo tag alcancavel.
# Saida padrao em linhas key=value, estavel para consumo por workflows e scripts.

set -euo pipefail

usage() {
  cat <<'EOF'
Uso: bash scripts/semver-next.sh [--repo <path>] [--version-file <path>]

Saida:
  action=bootstrap|release|no_release
  bootstrap_required=true|false
  release_required=true|false
  last_tag=<tag ou vazio>
  base_version=<semver sem prefixo v>
  bump=major|minor|patch|no_release
  target_version=<semver sem prefixo v>
  commit_range=<range git usado na analise>
  commit_count=<total de commits inspecionados>
  eligible_commit_count=<commits feat/fix/breaking>
EOF
}

REPO_DIR="."
VERSION_FILE="VERSION"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO_DIR="$2"
      shift 2
      ;;
    --version-file)
      VERSION_FILE="$2"
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

if [[ ! -d "$REPO_DIR" ]]; then
  echo "ERRO: repositorio nao encontrado: $REPO_DIR" >&2
  exit 1
fi

REPO_DIR="$(cd "$REPO_DIR" && pwd)"

if ! git -C "$REPO_DIR" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "ERRO: diretorio nao e um repositorio Git: $REPO_DIR" >&2
  exit 1
fi

if [[ "$VERSION_FILE" != /* ]]; then
  VERSION_FILE="$REPO_DIR/$VERSION_FILE"
fi

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "ERRO: arquivo VERSION nao encontrado: $VERSION_FILE" >&2
  exit 1
fi

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

is_semver() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

increment_semver() {
  local version="$1"
  local bump="$2"
  local major minor patch

  IFS='.' read -r major minor patch <<< "$version"

  case "$bump" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch)
      patch=$((patch + 1))
      ;;
    no_release)
      ;;
    *)
      echo "ERRO: bump desconhecido: $bump" >&2
      exit 1
      ;;
  esac

  printf '%s.%s.%s' "$major" "$minor" "$patch"
}

bump_priority() {
  case "$1" in
    no_release) printf '0' ;;
    patch) printf '1' ;;
    minor) printf '2' ;;
    major) printf '3' ;;
    *)
      echo "ERRO: prioridade desconhecida para bump: $1" >&2
      exit 1
      ;;
  esac
}

classify_commit() {
  local subject="$1"
  local body="$2"
  local breaking_subject_pattern='^[[:alpha:]][[:alnum:]_-]*(\([^)]+\))?!:'
  local feat_pattern='^feat(\([^)]+\))?:'
  local fix_pattern='^fix(\([^)]+\))?:'

  if [[ "$subject" =~ $breaking_subject_pattern ]]; then
    printf 'major'
    return
  fi

  if grep -Eq '(^|[[:space:]])BREAKING CHANGE:' <<< "$body"; then
    printf 'major'
    return
  fi

  if [[ "$subject" =~ $feat_pattern ]]; then
    printf 'minor'
    return
  fi

  if [[ "$subject" =~ $fix_pattern ]]; then
    printf 'patch'
    return
  fi

  printf 'no_release'
}

version_value="$(trim "$(cat "$VERSION_FILE")")"
if ! is_semver "$version_value"; then
  echo "ERRO: VERSION nao contem semver valido: $version_value" >&2
  exit 1
fi

last_tag="$(git -C "$REPO_DIR" describe --tags --abbrev=0 --match 'v[0-9]*.[0-9]*.[0-9]*' 2>/dev/null || true)"
bootstrap_required=false
commit_range=""
base_version=""

if [[ -n "$last_tag" ]]; then
  base_version="${last_tag#v}"
  if ! is_semver "$base_version"; then
    echo "ERRO: ultimo tag encontrado nao segue semver esperado: $last_tag" >&2
    exit 1
  fi
  commit_range="${last_tag}..HEAD"
else
  bootstrap_required=true
  base_version="$version_value"
  commit_range="HEAD"
fi

log_args=(log --format='%s%x1f%b%x1e')
if [[ -n "$last_tag" ]]; then
  log_args+=("${last_tag}..HEAD")
else
  log_args+=(HEAD)
fi

log_output="$(git -C "$REPO_DIR" "${log_args[@]}" 2>/dev/null || true)"

highest_bump="no_release"
commit_count=0
eligible_commit_count=0

if [[ -n "$log_output" ]]; then
  while IFS= read -r -d $'\x1e' record; do
    [[ -n "$record" ]] || continue

    commit_count=$((commit_count + 1))

    subject="${record%%$'\x1f'*}"
    body="${record#*$'\x1f'}"
    if [[ "$record" == "$subject" ]]; then
      body=""
    fi

    classification="$(classify_commit "$subject" "$body")"
    if [[ "$classification" != "no_release" ]]; then
      eligible_commit_count=$((eligible_commit_count + 1))
    fi

    if [[ "$(bump_priority "$classification")" -gt "$(bump_priority "$highest_bump")" ]]; then
      highest_bump="$classification"
    fi
  done < <(printf '%s' "$log_output")
fi

action="no_release"
release_required=false
target_version="$base_version"

if [[ "$bootstrap_required" == "true" ]]; then
  action="bootstrap"
elif [[ "$highest_bump" != "no_release" ]]; then
  action="release"
  release_required=true
  target_version="$(increment_semver "$base_version" "$highest_bump")"
fi

cat <<EOF
action=$action
bootstrap_required=$bootstrap_required
release_required=$release_required
last_tag=$last_tag
base_version=$base_version
bump=$highest_bump
target_version=$target_version
commit_range=$commit_range
commit_count=$commit_count
eligible_commit_count=$eligible_commit_count
EOF
