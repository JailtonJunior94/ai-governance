#!/usr/bin/env bash
# Verifica ou atualiza skills de governanca em um projeto alvo.
# Uso:
#   bash upgrade.sh [diretorio-alvo]            # atualiza (copia) skills desatualizadas
#   bash upgrade.sh --check [diretorio-alvo]     # apenas verifica, sem alterar arquivos
#
# Compara a versao no frontmatter de cada SKILL.md do repositorio fonte
# com a versao instalada no projeto alvo.

set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

CHECK_ONLY=0
if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=1
  shift
fi

PROJECT_DIR="${1:-.}"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERRO: diretorio alvo nao encontrado: $PROJECT_DIR"
  exit 1
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

if [[ "$SOURCE_DIR" == "$PROJECT_DIR" ]]; then
  echo "ERRO: o diretorio alvo nao pode ser o proprio repositorio de regras."
  exit 1
fi

if [[ ! -d "$PROJECT_DIR/.agents/skills" ]]; then
  echo "ERRO: governanca nao instalada em $PROJECT_DIR (pasta .agents/skills/ ausente)."
  echo "Execute install.sh primeiro."
  exit 1
fi

extract_version() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    printf ''
    return
  fi
  # Extrai campo version do frontmatter YAML
  local version
  version="$(awk '/^---$/{n++; next} n==1 && /^version:/{print $2; exit}' "$file")"
  printf '%s' "$version"
}

OUTDATED=0
UP_TO_DATE=0
MISSING=0

echo "Verificando skills em: $PROJECT_DIR"
echo "Fonte: $SOURCE_DIR"
echo ""

for source_skill in "$SOURCE_DIR/.agents/skills"/*/SKILL.md; do
  skill_name="$(basename "$(dirname "$source_skill")")"
  target_skill="$PROJECT_DIR/.agents/skills/$skill_name/SKILL.md"

  source_version="$(extract_version "$source_skill")"
  target_version="$(extract_version "$target_skill")"

  if [[ -z "$source_version" ]]; then
    continue
  fi

  if [[ ! -f "$target_skill" ]]; then
    echo "  AUSENTE   $skill_name (fonte: $source_version)"
    MISSING=$((MISSING + 1))
    continue
  fi

  if [[ -z "$target_version" ]]; then
    echo "  SEM VERSAO  $skill_name (fonte: $source_version, alvo: sem campo version)"
    OUTDATED=$((OUTDATED + 1))
  elif [[ "$source_version" != "$target_version" ]]; then
    echo "  DESATUALIZADA  $skill_name (fonte: $source_version, alvo: $target_version)"
    OUTDATED=$((OUTDATED + 1))
  else
    echo "  OK  $skill_name ($source_version)"
    UP_TO_DATE=$((UP_TO_DATE + 1))
    continue
  fi

  # Atualizar se nao estiver em modo check
  if [[ "$CHECK_ONLY" -eq 0 ]]; then
    # Verifica se e symlink — se for, nao precisa copiar
    if [[ -L "$PROJECT_DIR/.agents/skills/$skill_name" ]]; then
      echo "    -> symlink detectado, pulando copia (atualiza automaticamente)"
      continue
    fi
    cp -R "$SOURCE_DIR/.agents/skills/$skill_name/" "$PROJECT_DIR/.agents/skills/$skill_name/"
    echo "    -> atualizado"
  fi
done

echo ""
echo "Resumo: $UP_TO_DATE atualizadas, $OUTDATED desatualizadas, $MISSING ausentes"

if [[ "$CHECK_ONLY" -eq 1 && $((OUTDATED + MISSING)) -gt 0 ]]; then
  echo ""
  echo "Execute sem --check para atualizar: bash upgrade.sh $PROJECT_DIR"
  exit 1
fi
