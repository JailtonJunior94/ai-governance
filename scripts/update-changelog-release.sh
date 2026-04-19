#!/usr/bin/env bash
# Promove a secao Unreleased do CHANGELOG.md para uma release versionada.

set -euo pipefail

usage() {
  cat <<'EOF'
Uso: bash scripts/update-changelog-release.sh --version <MAJOR.MINOR.PATCH> [--date <YYYY-MM-DD>] [--changelog-file <path>]
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

is_iso_date() {
  [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

count_matches() {
  local text="$1"
  local pattern="$2"
  printf '%s\n' "$text" | grep -Ec "$pattern" || true
}

CHANGELOG_FILE="CHANGELOG.md"
TARGET_VERSION=""
RELEASE_DATE="$(date +%F)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      TARGET_VERSION="${2:-}"
      shift 2
      ;;
    --date)
      RELEASE_DATE="${2:-}"
      shift 2
      ;;
    --changelog-file)
      CHANGELOG_FILE="${2:-}"
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

if ! is_iso_date "$RELEASE_DATE"; then
  echo "ERRO: data da release fora do formato YYYY-MM-DD: $RELEASE_DATE" >&2
  exit 1
fi

if [[ ! -f "$CHANGELOG_FILE" ]]; then
  echo "ERRO: arquivo CHANGELOG.md nao encontrado: $CHANGELOG_FILE" >&2
  exit 1
fi

content="$(cat "$CHANGELOG_FILE")"

if [[ "$(count_matches "$content" '^## \[Unreleased\]$')" != "1" ]]; then
  echo "ERRO: CHANGELOG.md deve conter exatamente uma secao '## [Unreleased]'" >&2
  exit 1
fi

version_heading_regex="^## \\[$TARGET_VERSION\\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$"
existing_version_headings="$(count_matches "$content" "$version_heading_regex")"
if [[ "$existing_version_headings" -gt 1 ]]; then
  echo "ERRO: CHANGELOG.md contem multiplas secoes para a versao $TARGET_VERSION" >&2
  exit 1
fi

python3 - "$CHANGELOG_FILE" "$TARGET_VERSION" "$RELEASE_DATE" <<'PY'
import pathlib
import re
import sys

changelog_path = pathlib.Path(sys.argv[1])
target_version = sys.argv[2]
release_date = sys.argv[3]

content = changelog_path.read_text(encoding="utf-8")
lines = content.splitlines()

unreleased_index = None
for index, line in enumerate(lines):
    if line == "## [Unreleased]":
        unreleased_index = index
        break

if unreleased_index is None:
    raise SystemExit("ERRO: secao Unreleased nao encontrada")

for index, line in enumerate(lines):
    if index == unreleased_index:
        continue
    if line.startswith("## ") and not re.match(r"^## \[[^]]+\] - \d{4}-\d{2}-\d{2}$", line):
        raise SystemExit(
            f"ERRO: heading de changelog fora do formato esperado na linha {index + 1}: {line}"
        )

next_heading_index = len(lines)
for index in range(unreleased_index + 1, len(lines)):
    if re.match(r"^## \[[^]]+\] - \d{4}-\d{2}-\d{2}$", lines[index]):
        next_heading_index = index
        break

release_heading = f"## [{target_version}] - {release_date}"

existing_release_index = None
for index, line in enumerate(lines):
    if re.match(rf"^## \[{re.escape(target_version)}\] - \d{{4}}-\d{{2}}-\d{{2}}$", line):
        existing_release_index = index
        break

unreleased_body = lines[unreleased_index + 1:next_heading_index]
unreleased_has_content = any(line.strip() for line in unreleased_body)

if existing_release_index is not None:
    if unreleased_has_content:
        raise SystemExit(
            f"ERRO: release {target_version} ja existe e a secao Unreleased ainda contem entradas"
        )
    existing_release_line = lines[existing_release_index]
    if existing_release_line != release_heading:
        raise SystemExit(
            f"ERRO: release {target_version} ja existe com data diferente: {existing_release_line}"
        )
    sys.exit(0)

before_unreleased = lines[:unreleased_index]
after_unreleased = lines[next_heading_index:]

new_lines = list(before_unreleased)
new_lines.append("## [Unreleased]")
new_lines.append("")
new_lines.append(release_heading)
new_lines.extend(unreleased_body)

if after_unreleased and (not new_lines or new_lines[-1] != ""):
    new_lines.append("")

new_lines.extend(after_unreleased)

new_content = "\n".join(new_lines).rstrip("\n") + "\n"
changelog_path.write_text(new_content, encoding="utf-8")
PY
