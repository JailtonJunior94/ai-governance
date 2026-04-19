#!/usr/bin/env bash
# Verifica pre-condicoes antes de invocar uma skill.
#
# Uso:
#   bash scripts/check-skill-prerequisites.sh <skill-name> [project-dir]
#
# Retorna:
#   0 — pre-condicoes satisfeitas
#   1 — pre-condicoes faltando
#   2 — uso incorreto
#
# Exemplo:
#   bash scripts/check-skill-prerequisites.sh create-tasks tasks/prd-my-feature
#   bash scripts/check-skill-prerequisites.sh go-implementation .

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 <skill-name> [project-dir]" >&2
  exit 2
fi

skill_name="$1"
project_dir="${2:-.}"

missing=0

require_file() {
  local path="$1"
  local label="$2"

  if [[ ! -f "$path" ]]; then
    echo "PRE-REQUISITO FALTANDO: $label ($path)" >&2
    missing=1
  fi
}

require_dir() {
  local path="$1"
  local label="$2"

  if [[ ! -d "$path" ]]; then
    echo "PRE-REQUISITO FALTANDO: $label ($path)" >&2
    missing=1
  fi
}

require_glob() {
  local pattern="$1"
  local label="$2"

  # shellcheck disable=SC2086
  if ! compgen -G $pattern > /dev/null 2>&1; then
    echo "PRE-REQUISITO FALTANDO: $label ($pattern)" >&2
    missing=1
  fi
}

# Pre-condicoes universais
require_file "AGENTS.md" "contrato base AGENTS.md"
require_dir ".agents/skills/agent-governance" "skill agent-governance"

# Pre-condicoes por skill
case "$skill_name" in
  go-implementation)
    require_glob "${project_dir}/go.mod ${project_dir}/*/go.mod" "go.mod no projeto"
    # Fallback: tentar encontrar go.mod em qualquer lugar
    if [[ "$missing" -eq 1 ]] && find "$project_dir" -maxdepth 3 -name "go.mod" -print -quit 2>/dev/null | grep -q .; then
      missing=0
    fi
    ;;
  node-implementation)
    if [[ ! -f "${project_dir}/package.json" ]] && ! find "$project_dir" -maxdepth 3 -name "package.json" -print -quit 2>/dev/null | grep -q .; then
      echo "PRE-REQUISITO FALTANDO: package.json no projeto" >&2
      missing=1
    fi
    ;;
  python-implementation)
    if [[ ! -f "${project_dir}/pyproject.toml" ]] && [[ ! -f "${project_dir}/setup.py" ]] && [[ ! -f "${project_dir}/setup.cfg" ]]; then
      if ! find "$project_dir" -maxdepth 3 \( -name "pyproject.toml" -o -name "setup.py" \) -print -quit 2>/dev/null | grep -q .; then
        echo "PRE-REQUISITO FALTANDO: pyproject.toml ou setup.py no projeto" >&2
        missing=1
      fi
    fi
    ;;
  create-tasks)
    # Precisa de PRD e TechSpec
    if [[ -d "$project_dir" ]]; then
      require_file "${project_dir}/prd.md" "PRD (prd.md)"
      require_file "${project_dir}/techspec.md" "especificacao tecnica (techspec.md)"
    else
      echo "PRE-REQUISITO FALTANDO: diretorio de tasks ($project_dir)" >&2
      missing=1
    fi
    ;;
  create-technical-specification)
    # Precisa de PRD
    if [[ -d "$project_dir" ]]; then
      require_file "${project_dir}/prd.md" "PRD (prd.md)"
    else
      echo "PRE-REQUISITO FALTANDO: diretorio de tasks ($project_dir)" >&2
      missing=1
    fi
    ;;
  execute-task)
    # Precisa do tasks.md no diretorio
    if [[ -d "$project_dir" ]]; then
      require_file "${project_dir}/tasks.md" "indice de tarefas (tasks.md)"
    fi
    ;;
  bugfix)
    # Precisa de report de review ou bugs.md
    # Sem pre-requisito rigido — bugs podem vir de qualquer fonte
    ;;
  review|refactor|create-prd|analyze-project|agent-governance)
    # Sem pre-requisitos adicionais
    ;;
  *)
    # Skill desconhecida — verificar se existe
    if [[ ! -f ".agents/skills/${skill_name}/SKILL.md" ]]; then
      echo "PRE-REQUISITO FALTANDO: SKILL.md para skill '${skill_name}'" >&2
      missing=1
    fi
    ;;
esac

if [[ "$missing" -ne 0 ]]; then
  echo ""
  echo "Pre-condicoes nao satisfeitas para skill '${skill_name}'."
  echo "Corrija os pre-requisitos antes de invocar a skill."
  exit 1
fi

echo "OK: pre-condicoes satisfeitas para skill '${skill_name}'"
exit 0
