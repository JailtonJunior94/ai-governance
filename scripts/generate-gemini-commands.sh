#!/usr/bin/env bash
# Gera arquivos .gemini/commands/*.toml a partir das skills instaladas.
# Uso: bash generate-gemini-commands.sh [diretorio-alvo]
# Se nenhum diretorio for informado, usa o diretorio atual.

set -euo pipefail

PROJECT_DIR="${1:-.}"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERRO: diretorio alvo nao encontrado: $PROJECT_DIR" >&2
  exit 1
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
SKILLS_DIR="$PROJECT_DIR/.agents/skills"
COMMANDS_DIR="$PROJECT_DIR/.gemini/commands"

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "ERRO: nenhuma skill encontrada em $SKILLS_DIR" >&2
  exit 1
fi

mkdir -p "$COMMANDS_DIR"

extract_description() {
  local skill_file="$1"
  awk '/^---$/{n++; next} n==1 && /^description:/{sub(/^description:[[:space:]]*/, ""); print; exit}' "$skill_file"
}

list_assets() {
  local skill_dir="$1"
  local assets_dir="$skill_dir/assets"
  if [[ ! -d "$assets_dir" ]]; then
    return
  fi
  find "$assets_dir" -maxdepth 1 -type f -name '*.md' -print0 | LC_ALL=C sort -z | tr '\0' '\n'
}

# Skills que invocam review como parte do fluxo
uses_review() {
  local skill_name="$1"
  case "$skill_name" in
    execute-task|refactor) return 0 ;;
    *) return 1 ;;
  esac
}

generated=0

for skill_dir in "$SKILLS_DIR"/*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  skill_file="$skill_dir/SKILL.md"

  [[ -f "$skill_file" ]] || continue

  # agent-governance e carga interna, nao um comando de usuario
  [[ "$skill_name" == "agent-governance" ]] && continue

  description="$(extract_description "$skill_file")"
  if [[ -z "$description" ]]; then
    continue
  fi

  # Truncar descricao para caber no campo description do toml (uma linha curta)
  # Usar apenas a primeira frase ate o primeiro ponto
  short_desc="$(printf '%s' "$description" | sed 's/\. .*/\./' | head -c 120)"

  # Construir linhas do prompt
  prompt_lines="Use \`.agents/skills/$skill_name/SKILL.md\` como fluxo canonico desta tarefa."

  # Detectar assets
  assets=()
  while IFS= read -r asset; do
    [[ -n "$asset" ]] || continue
    asset_rel=".agents/skills/$skill_name/assets/$(basename "$asset")"
    assets+=("$asset_rel")
  done < <(list_assets "$skill_dir")

  if [[ ${#assets[@]} -eq 1 ]]; then
    prompt_lines="$prompt_lines
Leia os assets referenciados sob demanda, especialmente \`${assets[0]}\`."
  elif [[ ${#assets[@]} -gt 1 ]]; then
    prompt_lines="$prompt_lines
Leia os assets referenciados sob demanda, especialmente:"
    for asset in "${assets[@]}"; do
      prompt_lines="$prompt_lines
- \`$asset\`"
    done
  elif [[ -d "$skill_dir/references" ]]; then
    prompt_lines="$prompt_lines
Leia os assets e references sob demanda conforme descrito no SKILL.md."
  fi

  if uses_review "$skill_name"; then
    prompt_lines="$prompt_lines
Se revisao for necessaria, use \`.agents/skills/review/SKILL.md\` como processo de revisao."
  fi

  prompt_lines="$prompt_lines
Nao invente um processo paralelo neste comando.

Contrato de carga obrigatorio (executar antes de editar codigo):
1. Ler \`AGENTS.md\` para contexto de arquitetura e regras.
2. Ler \`.agents/skills/agent-governance/SKILL.md\` para governanca base.
3. Carregar a skill de linguagem apropriada quando a tarefa alterar codigo (Go, Node ou Python).

Validacao obrigatoria ao final:
1. Rodar formatter nos arquivos alterados.
2. Rodar testes direcionados aos modulos afetados.
3. Rodar lint quando disponivel e proporcional ao risco.
4. Registrar comandos executados, arquivos alterados e riscos residuais.

Aplicar a habilidade a esta solicitacao:
{{args}}"

  # Escrever o arquivo toml
  cat > "$COMMANDS_DIR/$skill_name.toml" <<TOML
description = "$short_desc"
prompt = """
$prompt_lines
"""
TOML

  generated=$((generated + 1))
done

echo "Gemini commands gerados: $generated arquivo(s) em $COMMANDS_DIR"
