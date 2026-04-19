#!/usr/bin/env bash
# Verifica ou atualiza skills de governanca em um projeto alvo.
# Uso:
#   bash upgrade.sh [--ref <tag|branch|sha>] [diretorio-alvo]                         # atualiza todas as skills desatualizadas
#   bash upgrade.sh --check [--ref <tag|branch|sha>] [diretorio-alvo]                 # apenas verifica, sem alterar arquivos
#   bash upgrade.sh --langs go,node [--ref <tag|branch|sha>] [diretorio-alvo]         # atualiza apenas skills das linguagens indicadas
#   bash upgrade.sh --check --langs python [--ref <tag|branch|sha>] [diretorio-alvo]  # verifica apenas skills de Python
#
# Compara a versao no frontmatter de cada SKILL.md do repositorio fonte
# com a versao instalada no projeto alvo.
# Aceita AI_GOVERNANCE_REF ou --ref para fixar a fonte da comparacao.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GOVERNANCE_REF="${AI_GOVERNANCE_REF:-}"
SOURCE_LABEL=""

# shellcheck source=scripts/lib/source-ref.sh
source "$SCRIPT_DIR/scripts/lib/source-ref.sh"

CHECK_ONLY=0
LANGS_FILTER=""
BASE_SKILLS=(
  agent-governance
  analyze-project
  bugfix
  create-prd
  create-tasks
  create-technical-specification
  execute-task
  refactor
  review
)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      CHECK_ONLY=1
      shift
      ;;
    --langs)
      LANGS_FILTER="$2"
      shift 2
      ;;
    --ref)
      GOVERNANCE_REF="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

resolve_governance_source "$SCRIPT_DIR" "$GOVERNANCE_REF" SOURCE_DIR SOURCE_LABEL
trap '[[ -n "${AI_GOVERNANCE_SOURCE_TMPDIR:-}" ]] && rm -rf "$AI_GOVERNANCE_SOURCE_TMPDIR"' EXIT

# shellcheck source=scripts/lib/install-common.sh
source "$SOURCE_DIR/scripts/lib/install-common.sh"
# shellcheck source=scripts/lib/codex-config.sh
source "$SOURCE_DIR/scripts/lib/codex-config.sh"

# Mapeia --langs para lista de skills filtradas
LANG_SKILL_NAMES=()
if [[ -n "$LANGS_FILTER" ]]; then
  IFS=',' read -ra lang_items <<< "$LANGS_FILTER"
  for lang in "${lang_items[@]}"; do
    case "$lang" in
      go)     LANG_SKILL_NAMES+=(go-implementation object-calisthenics-go) ;;
      node)   LANG_SKILL_NAMES+=(node-implementation) ;;
      python) LANG_SKILL_NAMES+=(python-implementation) ;;
      *) echo "AVISO: linguagem '$lang' ignorada (invalida)." ;;
    esac
  done
fi

should_process_skill() {
  local skill_name="$1"
  # Se nenhum filtro, processar todas
  if [[ -z "$LANGS_FILTER" ]]; then
    return 0
  fi
  # Skills de linguagem: apenas as filtradas
  case "$skill_name" in
    go-implementation|object-calisthenics-go|node-implementation|python-implementation)
      for allowed in "${LANG_SKILL_NAMES[@]}"; do
        [[ "$skill_name" == "$allowed" ]] && return 0
      done
      return 1
      ;;
  esac
  # Skills processuais: sempre incluir
  return 0
}

add_expected_skill() {
  local skill_name="$1"
  local existing
  [[ -n "$skill_name" ]] || return 0
  [[ -d "$SOURCE_DIR/.agents/skills/$skill_name" ]] || return 0
  for existing in "${EXPECTED_SKILLS[@]-}"; do
    [[ "$existing" == "$skill_name" ]] && return 0
  done
  EXPECTED_SKILLS+=("$skill_name")
}

load_expected_skills() {
  local skill path

  for skill in "${BASE_SKILLS[@]}"; do
    add_expected_skill "$skill"
  done

  if [[ -f "$PROJECT_DIR/AGENTS.md" ]]; then
    while IFS= read -r path; do
      skill="${path#.agents/skills/}"
      skill="${skill%/SKILL.md}"
      add_expected_skill "$skill"
    done < <(grep -oE '\.agents/skills/[^`[:space:]]+/SKILL\.md' "$PROJECT_DIR/AGENTS.md" | LC_ALL=C sort -u || true)
  fi

  if [[ -f "$PROJECT_DIR/.codex/config.toml" ]]; then
    while IFS= read -r path; do
      skill="${path#.agents/skills/}"
      add_expected_skill "$skill"
    done < <(sed -n 's/^[[:space:]]*path[[:space:]]*=[[:space:]]*"\.agents\/skills\/\([^"]*\)".*/\1/p' "$PROJECT_DIR/.codex/config.toml" | LC_ALL=C sort -u || true)
  fi

  if [[ -d "$PROJECT_DIR/.agents/skills" ]]; then
    while IFS= read -r skill; do
      add_expected_skill "$skill"
    done < <(find "$PROJECT_DIR/.agents/skills" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) -exec basename {} \; | LC_ALL=C sort -u)
  fi
}

PROJECT_DIR="${1:-.}"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERRO: diretorio alvo nao encontrado: $PROJECT_DIR"
  exit 1
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

if [[ "$SCRIPT_DIR" == "$PROJECT_DIR" || "$SOURCE_DIR" == "$PROJECT_DIR" ]]; then
  echo "ERRO: o diretorio alvo nao pode ser o proprio repositorio de regras."
  exit 1
fi

if [[ ! -d "$PROJECT_DIR/.agents/skills" ]]; then
  echo "ERRO: governanca nao instalada em $PROJECT_DIR (pasta .agents/skills/ ausente)."
  echo "Execute install.sh primeiro."
  exit 1
fi

EXPECTED_SKILLS=()
load_expected_skills

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

# Compara duas versoes semver (MAJOR.MINOR.PATCH).
# Retorna 0 se $1 > $2 (source mais nova), 1 caso contrario.
semver_gt() {
  local source="$1"
  local target="$2"

  if [[ "$source" == "$target" ]]; then
    return 1
  fi

  local IFS='.'
  read -ra s_parts <<< "$source"
  read -ra t_parts <<< "$target"

  local s_major="${s_parts[0]:-0}" s_minor="${s_parts[1]:-0}" s_patch="${s_parts[2]:-0}"
  local t_major="${t_parts[0]:-0}" t_minor="${t_parts[1]:-0}" t_patch="${t_parts[2]:-0}"

  # Remover sufixos pre-release para comparacao numerica limpa
  s_patch="${s_patch%%-*}"
  t_patch="${t_patch%%-*}"

  if [[ "$s_major" -gt "$t_major" ]]; then return 0; fi
  if [[ "$s_major" -lt "$t_major" ]]; then return 1; fi
  if [[ "$s_minor" -gt "$t_minor" ]]; then return 0; fi
  if [[ "$s_minor" -lt "$t_minor" ]]; then return 1; fi
  if [[ "$s_patch" -gt "$t_patch" ]]; then return 0; fi
  return 1
}

OUTDATED=0
UP_TO_DATE=0
MISSING=0
REFS_DIVERGENT=0

# Computa hash agregado de todos os arquivos em references/ de uma skill.
# Usa apenas nomes relativos + conteudo para ser independente de caminho absoluto/symlinks.
# Retorna string vazia se o diretorio nao existir.
refs_hash() {
  local refs_dir="$1"
  if [[ ! -d "$refs_dir" ]]; then
    printf ''
    return
  fi
  (cd "$refs_dir" && find . -type f | LC_ALL=C sort | xargs shasum -a 256 2>/dev/null | shasum -a 256 | awk '{print $1}')
}

# Lista arquivos de references/ que diferem entre fonte e alvo.
refs_changed_files() {
  local source_refs="$1"
  local target_refs="$2"
  [[ -d "$source_refs" ]] || return
  [[ -d "$target_refs" ]] || return

  # Arquivos que existem na fonte
  local source_files target_files
  source_files="$(cd "$source_refs" && find . -type f | LC_ALL=C sort)"
  target_files="$(cd "$target_refs" && find . -type f | LC_ALL=C sort)"

  # Novos ou modificados na fonte
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    if [[ ! -f "$target_refs/$f" ]]; then
      printf '    + %s (novo)\n' "${f#./}"
    elif ! diff -q "$source_refs/$f" "$target_refs/$f" > /dev/null 2>&1; then
      printf '    ~ %s (modificado)\n' "${f#./}"
    fi
  done <<< "$source_files"

  # Removidos da fonte
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    if [[ ! -f "$source_refs/$f" ]]; then
      printf '    - %s (removido)\n' "${f#./}"
    fi
  done <<< "$target_files"
}

SOURCE_VERSION="$(cat "$SOURCE_DIR/VERSION" 2>/dev/null || echo 'unknown')"
echo "ai-governance $SOURCE_VERSION"
echo "Verificando skills em: $PROJECT_DIR"
echo "Fonte: $SOURCE_LABEL"
echo ""

while IFS= read -r skill_name; do
  source_skill="$SOURCE_DIR/.agents/skills/$skill_name/SKILL.md"

  # Aplicar filtro de linguagem quando --langs foi informado
  if ! should_process_skill "$skill_name"; then
    continue
  fi

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
  elif semver_gt "$source_version" "$target_version"; then
    echo "  DESATUALIZADA  $skill_name (fonte: $source_version, alvo: $target_version)"
    OUTDATED=$((OUTDATED + 1))
  else
    # Versoes iguais — verificar checksum para detectar edicoes sem bump
    source_hash="$(shasum -a 256 "$source_skill" | awk '{print $1}')"
    target_hash="$(shasum -a 256 "$target_skill" | awk '{print $1}')"
    if [[ "$source_hash" != "$target_hash" ]]; then
      echo "  CONTEUDO DIVERGENTE  $skill_name ($target_version, checksum diferente)"
      OUTDATED=$((OUTDATED + 1))
    else
      # SKILL.md identico — verificar tambem references/
      source_refs_hash="$(refs_hash "$SOURCE_DIR/.agents/skills/$skill_name/references")"
      target_refs_hash="$(refs_hash "$PROJECT_DIR/.agents/skills/$skill_name/references")"
      if [[ -n "$source_refs_hash" && "$source_refs_hash" != "$target_refs_hash" ]]; then
        echo "  REFS DIVERGENTES  $skill_name ($target_version, references/ checksum diferente)"
        refs_changed_files "$SOURCE_DIR/.agents/skills/$skill_name/references" "$PROJECT_DIR/.agents/skills/$skill_name/references"
        REFS_DIVERGENT=$((REFS_DIVERGENT + 1))
        OUTDATED=$((OUTDATED + 1))
      else
        echo "  OK  $skill_name ($target_version)"
        UP_TO_DATE=$((UP_TO_DATE + 1))
        continue
      fi
    fi
  fi

  # Atualizar se nao estiver em modo check
  if [[ "$CHECK_ONLY" -eq 0 ]]; then
    # Verifica se e symlink — se for, nao precisa copiar
    if [[ -L "$PROJECT_DIR/.agents/skills/$skill_name" ]]; then
      echo "    -> symlink detectado, pulando copia (atualiza automaticamente)"
      continue
    fi
    rm -rf "$PROJECT_DIR/.agents/skills/$skill_name"
    mkdir -p "$(dirname "$PROJECT_DIR/.agents/skills/$skill_name")"
    cp -R "$SOURCE_DIR/.agents/skills/$skill_name" "$PROJECT_DIR/.agents/skills/$skill_name"
    echo "    -> atualizado"
  fi
done < <(printf '%s\n' "${EXPECTED_SKILLS[@]-}" | sed '/^$/d' | LC_ALL=C sort -u)

echo ""
echo "Resumo: $UP_TO_DATE atualizadas, $OUTDATED desatualizadas ($REFS_DIVERGENT refs divergentes), $MISSING ausentes"

if [[ "$CHECK_ONLY" -eq 1 && $((OUTDATED + MISSING)) -gt 0 ]]; then
  echo ""
  echo "Execute sem --check para atualizar: bash upgrade.sh $PROJECT_DIR"
  exit 1
fi

# Atualizar adaptadores quando houve atualizacoes de skills
if [[ "$CHECK_ONLY" -eq 0 && "$OUTDATED" -gt 0 ]]; then
  ADAPTERS_UPDATED=0

  # Re-gerar adaptadores via script unificado (Claude, GitHub, Gemini)
  ADAPTERS_GENERATOR="$SOURCE_DIR/scripts/generate-adapters.sh"
  if [[ -f "$ADAPTERS_GENERATOR" ]]; then
    bash "$ADAPTERS_GENERATOR" "$PROJECT_DIR" 2>/dev/null && \
      ADAPTERS_UPDATED=$((ADAPTERS_UPDATED + 1)) || true
  fi

  # Claude rules
  _rules_updated="$(sync_adapter_dir "$SOURCE_DIR/.claude/rules" "$PROJECT_DIR/.claude/rules" "*.md")"
  ADAPTERS_UPDATED=$((ADAPTERS_UPDATED + _rules_updated))

  # Claude scripts
  _scripts_updated="$(sync_adapter_dir "$SOURCE_DIR/.claude/scripts" "$PROJECT_DIR/.claude/scripts" "*")"
  ADAPTERS_UPDATED=$((ADAPTERS_UPDATED + _scripts_updated))

  # Codex config — re-gerar a partir das skills instaladas
  if [[ -f "$PROJECT_DIR/.codex/config.toml" ]]; then
    _codex_go=0; _codex_node=0; _codex_python=0
    [[ -e "$PROJECT_DIR/.agents/skills/go-implementation/SKILL.md" ]] && _codex_go=1
    [[ -e "$PROJECT_DIR/.agents/skills/node-implementation/SKILL.md" ]] && _codex_node=1
    [[ -e "$PROJECT_DIR/.agents/skills/python-implementation/SKILL.md" ]] && _codex_python=1
    new_codex="$(build_codex_config "$_codex_go" "$_codex_node" "$_codex_python")"
    if [[ "$(printf '%b' "$new_codex")" != "$(cat "$PROJECT_DIR/.codex/config.toml")" ]]; then
      printf '%b' "$new_codex" > "$PROJECT_DIR/.codex/config.toml"
      ADAPTERS_UPDATED=$((ADAPTERS_UPDATED + 1))
    fi
  fi

  if [[ "$ADAPTERS_UPDATED" -gt 0 ]]; then
    echo "Adaptadores atualizados: $ADAPTERS_UPDATED arquivo(s)"
  fi
fi

# Re-gerar governanca contextual se AGENTS.md existir e houve atualizacoes ou schema divergente
GOVERNANCE_GENERATOR="$SOURCE_DIR/.agents/skills/analyze-project/scripts/generate-governance.sh"

# Verificar se schema version do AGENTS.md mudou (indica necessidade de re-geracao)
SCHEMA_NEEDS_REGEN=0
if [[ -f "$PROJECT_DIR/AGENTS.md" && -f "$SOURCE_DIR/.agents/skills/analyze-project/assets/agents-template.md" ]]; then
  _target_schema="$(grep -o 'governance-schema: [0-9.]*' "$PROJECT_DIR/AGENTS.md" 2>/dev/null | awk '{print $2}' || true)"
  _source_schema="$(grep -o 'GOVERNANCE_SCHEMA_VERSION="[^"]*"' "$SOURCE_DIR/.agents/skills/analyze-project/scripts/generate-governance.sh" 2>/dev/null | head -1 | sed 's/.*="//;s/"//' || true)"
  # Se a versao de schema da fonte difere da instalada, re-gerar
  if [[ -n "$_source_schema" && "$_source_schema" != "$_target_schema" ]]; then
    echo "  SCHEMA DIVERGENTE  AGENTS.md (fonte: ${_source_schema:-ausente}, alvo: ${_target_schema:-ausente})"
    SCHEMA_NEEDS_REGEN=1
  fi
fi

if [[ "$CHECK_ONLY" -eq 0 && ( "$OUTDATED" -gt 0 || "$SCHEMA_NEEDS_REGEN" -gt 0 ) && -f "$PROJECT_DIR/AGENTS.md" && -f "$GOVERNANCE_GENERATOR" ]]; then
  echo ""
  echo "-> Re-gerando governanca contextual apos atualizacao de skills..."

  # Detectar quais ferramentas estao instaladas no projeto alvo
  INSTALL_CLAUDE=0; INSTALL_GEMINI=0; INSTALL_CODEX=0; INSTALL_COPILOT=0
  [[ -f "$PROJECT_DIR/CLAUDE.md" ]] && INSTALL_CLAUDE=1
  [[ -f "$PROJECT_DIR/GEMINI.md" ]] && INSTALL_GEMINI=1
  [[ -f "$PROJECT_DIR/.codex/config.toml" ]] && INSTALL_CODEX=1
  [[ -f "$PROJECT_DIR/.github/copilot-instructions.md" ]] && INSTALL_COPILOT=1

  INSTALL_CLAUDE="$INSTALL_CLAUDE" \
  INSTALL_GEMINI="$INSTALL_GEMINI" \
  INSTALL_CODEX="$INSTALL_CODEX" \
  INSTALL_COPILOT="$INSTALL_COPILOT" \
  bash "$GOVERNANCE_GENERATOR" "$PROJECT_DIR" 2>/dev/null && \
    echo "   Governanca contextual re-gerada com sucesso." || \
    echo "   AVISO: falha ao re-gerar governanca contextual."
fi
