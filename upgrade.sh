#!/usr/bin/env bash
# Verifica ou atualiza skills de governanca em um projeto alvo.
# Uso:
#   bash upgrade.sh [diretorio-alvo]                        # atualiza todas as skills desatualizadas
#   bash upgrade.sh --check [diretorio-alvo]                 # apenas verifica, sem alterar arquivos
#   bash upgrade.sh --langs go,node [diretorio-alvo]         # atualiza apenas skills das linguagens indicadas
#   bash upgrade.sh --check --langs python [diretorio-alvo]  # verifica apenas skills de Python
#
# Compara a versao no frontmatter de cada SKILL.md do repositorio fonte
# com a versao instalada no projeto alvo.

set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=scripts/lib/install-common.sh
source "$SOURCE_DIR/scripts/lib/install-common.sh"
# shellcheck source=scripts/lib/codex-config.sh
source "$SOURCE_DIR/scripts/lib/codex-config.sh"

CHECK_ONLY=0
LANGS_FILTER=""

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
    *)
      break
      ;;
  esac
done

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

echo "Verificando skills em: $PROJECT_DIR"
echo "Fonte: $SOURCE_DIR"
echo ""

for source_skill in "$SOURCE_DIR/.agents/skills"/*/SKILL.md; do
  skill_name="$(basename "$(dirname "$source_skill")")"

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
    cp -R "$SOURCE_DIR/.agents/skills/$skill_name/" "$PROJECT_DIR/.agents/skills/$skill_name/"
    echo "    -> atualizado"
  fi
done

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

# Re-gerar governanca contextual se AGENTS.md existir e houve atualizacoes
GOVERNANCE_GENERATOR="$SOURCE_DIR/.agents/skills/analyze-project/scripts/generate-governance.sh"

if [[ "$CHECK_ONLY" -eq 0 && "$OUTDATED" -gt 0 && -f "$PROJECT_DIR/AGENTS.md" && -f "$GOVERNANCE_GENERATOR" ]]; then
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
