#!/usr/bin/env bash
# Seleciona a proxima task elegivel de um tasks.md.
#
# Uso:
#   bash scripts/lib/task-selector.sh <tasks.md>
#
# Saida (stdout, tab-separated):
#   <task_id>\t<task_file>\t<task_title>
#
# Retorno:
#   0 — task elegivel encontrada
#   1 — nenhuma task elegivel (todas done, bloqueadas por deps, ou sem task file)
#   2 — uso incorreto ou arquivo nao encontrado
#
# Compatibilidade: bash 3+ (sem associative arrays)

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <tasks.md>" >&2
  exit 2
fi

tasks_md="$1"

if [[ ! -f "$tasks_md" ]]; then
  echo "ERRO: arquivo nao encontrado: $tasks_md" >&2
  exit 2
fi

tasks_dir="$(dirname "$tasks_md")"

# Extrair linhas de task da tabela em arquivo temporario
# Formato: task_id|title|status|deps
tmp_tasks="$(mktemp)"
trap 'rm -f "$tmp_tasks"' EXIT

while IFS= read -r line; do
  if ! echo "$line" | grep -Eq '^\|[[:space:]]*[0-9]+\.[0-9]+'; then
    continue
  fi

  task_id="$(echo "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}')"
  title="$(echo "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3}')"
  status="$(echo "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4); print $4}')"
  deps_raw="$(echo "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $5); print $5}')"

  status="$(echo "$status" | tr '[:upper:]' '[:lower:]')"

  echo "${task_id}|${title}|${status}|${deps_raw}" >> "$tmp_tasks"
done < "$tasks_md"

if [[ ! -s "$tmp_tasks" ]]; then
  echo "ERRO: nenhuma task encontrada na tabela de $tasks_md" >&2
  exit 1
fi

# Funcao: buscar status de uma task por id
_get_status() {
  local search_id="$1"
  grep "^${search_id}|" "$tmp_tasks" | head -1 | cut -d'|' -f3
}

# Selecionar primeira task elegivel
while IFS='|' read -r task_id title status deps_raw; do
  [[ -z "$task_id" ]] && continue

  # Pular tasks finalizadas ou bloqueadas
  case "$status" in
    done|blocked|failed|skipped) continue ;;
  esac

  # Verificar dependencias
  deps_ok=true
  if [[ "$deps_raw" != "—" && "$deps_raw" != "-" && -n "$deps_raw" ]]; then
    # Separar por virgula
    old_ifs="$IFS"
    IFS=','
    set -- $deps_raw
    IFS="$old_ifs"
    for dep in "$@"; do
      dep="$(echo "$dep" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | sed 's/`//g')"
      [[ -z "$dep" ]] && continue

      dep_status="$(_get_status "$dep")"
      if [[ "$dep_status" != "done" ]]; then
        deps_ok=false
        break
      fi
    done
  fi

  if [[ "$deps_ok" != "true" ]]; then
    continue
  fi

  # Procurar arquivo de tarefa no diretorio
  task_file=""
  for candidate in "$tasks_dir"/${task_id}-*.md "$tasks_dir"/${task_id}_*.md; do
    if [[ -f "$candidate" ]]; then
      task_file="$(basename "$candidate")"
      break
    fi
  done

  if [[ -z "$task_file" ]]; then
    continue
  fi

  # Task elegivel encontrada
  printf '%s\t%s\t%s\n' "$task_id" "$task_file" "$title"
  exit 0
done < "$tmp_tasks"

# Nenhuma task elegivel
exit 1
