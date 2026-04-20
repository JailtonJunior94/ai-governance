#!/usr/bin/env bash
# Gera governanca contextual (AGENTS.md, CLAUDE.md, GEMINI.md, etc.) para um projeto alvo.
# Uso: bash generate-governance.sh [--dry-run] [diretorio-alvo]
# --dry-run: mostra o que seria gerado sem escrever arquivos.

set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"

while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    *) break ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$SKILL_DIR/../../.." && pwd)"

# shellcheck source=../../../../scripts/lib/codex-config.sh
source "$ROOT_DIR/scripts/lib/codex-config.sh"
# shellcheck source=../../../../scripts/lib/find-manifests.sh
source "$ROOT_DIR/scripts/lib/find-manifests.sh"

PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

INSTALL_CLAUDE="${INSTALL_CLAUDE:-0}"
INSTALL_GEMINI="${INSTALL_GEMINI:-0}"
INSTALL_CODEX="${INSTALL_CODEX:-0}"
INSTALL_COPILOT="${INSTALL_COPILOT:-0}"

# Flags de linguagem: quando nao definidas, detectar pela presenca de arquivos
INSTALL_GO="${INSTALL_GO:-auto}"
INSTALL_NODE="${INSTALL_NODE:-auto}"
INSTALL_PYTHON="${INSTALL_PYTHON:-auto}"

# Importar modulo de deteccao de arquitetura
DETECT_ARCH_SCRIPT="$ROOT_DIR/.agents/skills/agent-governance/scripts/detect-architecture.sh"
# shellcheck source=../../../agent-governance/scripts/detect-architecture.sh
source "$DETECT_ARCH_SCRIPT"

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

file_exists() {
  [[ -e "$PROJECT_DIR/$1" ]]
}

find_manifests() {
  lib_find_manifests "$PROJECT_DIR" "$1" "${2:-4}"
}

has_manifest() {
  find_manifests "$1" 4 | read -r _
}

has_any_files() {
  local dir="$1"
  [[ -d "$PROJECT_DIR/$dir" ]] || return 1
  find "$PROJECT_DIR/$dir" -mindepth 1 -maxdepth 1 | read -r _
}

# Verifica se uma linguagem deve ser incluida.
# Se a flag for "auto", detecta pela presenca de arquivos.
# Se for "1", inclui. Qualquer outro valor, exclui.
should_include_go() {
  if [[ "$INSTALL_GO" == "auto" ]]; then
    file_exists "go.mod" || file_exists "go.work" || has_manifest "go.mod"
  else
    [[ "$INSTALL_GO" == "1" ]]
  fi
}

should_include_node() {
  if [[ "$INSTALL_NODE" == "auto" ]]; then
    file_exists "package.json" || file_exists "tsconfig.json" || has_manifest "package.json" || has_manifest "tsconfig.json"
  else
    [[ "$INSTALL_NODE" == "1" ]]
  fi
}

should_include_python() {
  if [[ "$INSTALL_PYTHON" == "auto" ]]; then
    file_exists "pyproject.toml" || file_exists "requirements.txt" || file_exists "setup.py" || file_exists "Pipfile" || has_manifest "pyproject.toml" || has_manifest "requirements.txt"
  else
    [[ "$INSTALL_PYTHON" == "1" ]]
  fi
}

detect_frameworks() {
  local frameworks=()

  # --- Go ---
  while IFS= read -r go_mod; do
    [[ -n "$go_mod" ]] || continue
    if grep -q 'github.com/gin-gonic/gin' "$go_mod"; then
      frameworks+=("Gin")
    fi
    if grep -q 'github.com/labstack/echo' "$go_mod"; then
      frameworks+=("Echo")
    fi
    if grep -q 'github.com/gofiber/fiber' "$go_mod"; then
      frameworks+=("Fiber")
    fi
    if grep -q 'google.golang.org/grpc' "$go_mod"; then
      frameworks+=("gRPC")
    fi
    if grep -q 'connectrpc.com/connect' "$go_mod"; then
      frameworks+=("Connect")
    fi
  done < <(find_manifests "go.mod" 4)

  # --- Node/TypeScript ---
  while IFS= read -r pkg; do
    [[ -n "$pkg" ]] || continue
    if grep -q '"express"' "$pkg"; then
      frameworks+=("Express")
    fi
    if grep -q '"@nestjs/core"' "$pkg"; then
      frameworks+=("NestJS")
    fi
    if grep -q '"fastify"' "$pkg"; then
      frameworks+=("Fastify")
    fi
    if grep -q '"next"' "$pkg"; then
      frameworks+=("Next.js")
    fi
    if grep -q '"hono"' "$pkg"; then
      frameworks+=("Hono")
    fi
  done < <(find_manifests "package.json" 4)

  # --- Python ---
  while IFS= read -r pyp; do
    [[ -n "$pyp" ]] || continue
    if grep -q 'fastapi' "$pyp"; then
      frameworks+=("FastAPI")
    fi
    if grep -q 'django' "$pyp"; then
      frameworks+=("Django")
    fi
    if grep -q 'flask' "$pyp"; then
      frameworks+=("Flask")
    fi
  done < <(find_manifests "pyproject.toml" 4)

  while IFS= read -r req; do
    [[ -n "$req" ]] || continue
    if grep -qi 'fastapi' "$req"; then
      frameworks+=("FastAPI")
    fi
    if grep -qi 'django' "$req"; then
      frameworks+=("Django")
    fi
    if grep -qi 'flask' "$req"; then
      frameworks+=("Flask")
    fi
  done < <(find_manifests "requirements.txt" 4)

  if [[ ${#frameworks[@]} -eq 0 ]]; then
    printf 'nenhum framework dominante identificado'
    return
  fi

  # Deduplica e junta com ", " usando apenas awk (sem dependencia de python3)
  local joined
  joined="$(printf '%s\n' "${frameworks[@]}" | awk '!seen[$0]++ { lines[++n]=$0 } END { for(i=1;i<=n;i++) { if(i>1) printf ", "; printf "%s", lines[i] } }')"
  printf '%s' "$joined"
}

detect_primary_stack() {
  local parts=()

  if should_include_go; then
    parts+=("Go")
  fi
  if should_include_node; then
    parts+=("Node.js")
  fi
  if should_include_python; then
    parts+=("Python")
  fi
  if file_exists "pom.xml" || file_exists "build.gradle" || file_exists "build.gradle.kts"; then
    parts+=("Java/Kotlin")
  fi
  if file_exists "Cargo.toml"; then
    parts+=("Rust")
  fi
  if ls "$PROJECT_DIR"/*.csproj >/dev/null 2>&1 || ls "$PROJECT_DIR"/*.sln >/dev/null 2>&1; then
    parts+=("C#/.NET")
  fi

  if [[ ${#parts[@]} -eq 0 ]]; then
    printf 'stack principal nao detectada automaticamente'
    return
  fi

  local joined
  joined="$(IFS=', '; printf '%s' "${parts[*]}")"
  printf '%s' "$joined"
}

build_directory_tree() {
  local tree
  if git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    tree="$(
      git -C "$PROJECT_DIR" ls-files | python3 -c '
import sys
from pathlib import PurePosixPath

excluded = {".agents", ".claude", ".codex", ".gemini", "node_modules", "vendor", "dist", "build", "bin", "target", "__pycache__"}
entries = set()

for raw in sys.stdin:
    path = raw.strip()
    if not path:
        continue
    pure = PurePosixPath(path)
    if any(part in excluded for part in pure.parts):
        continue
    if pure.name == ".gitkeep" or pure.suffix == ".pyc":
        continue

    current = PurePosixPath()
    for part in pure.parts[:-1]:
        current = current / part
        entries.add(str(current))
    entries.add(path)

for entry in sorted(entries)[:80]:
    print(entry)
'
    )"
  else
    tree="$(cd "$PROJECT_DIR" && find . \
      \( -path './.git' -o -path './.agents' -o -path './.claude' -o -path './.codex' -o -path './.gemini' -o -path './node_modules' -o -path './vendor' -o -path './dist' -o -path './build' -o -path './bin' -o -path './target' \) -prune \
      -o \( -type d -name '__pycache__' -prune \) \
      -o \( -name '.gitkeep' -o -name '*.pyc' \) -prune \
      -o -print | sed 's#^\./##' | LC_ALL=C sort | awk 'NR <= 80 { print }')"
  fi

  if [[ -z "$tree" ]]; then
    printf '.\n'
    return
  fi

  printf '%s\n' "$tree"
}

build_architecture_description() {
  local architecture_type="$1"
  local stack="$2"
  local frameworks="$3"

  case "$architecture_type" in
    monorepo)
      cat <<EOF
O projeto aparenta ser um monorepo, com multiplos componentes ou workspaces sob a mesma raiz. A governanca deve preservar fronteiras entre pacotes e validar apenas os workspaces afetados.

Stack detectada: $stack.
Frameworks detectados: $frameworks.
EOF
      ;;
    "monolito modular")
      cat <<EOF
O projeto aparenta ser um monolito modular, com separacao relevante por modulos, dominios ou componentes internos. A governanca deve proteger essas fronteiras e evitar dependencias circulares.

Stack detectada: $stack.
Frameworks detectados: $frameworks.
EOF
      ;;
    microservico)
      cat <<EOF
O projeto aparenta ser um microservico independente, com foco em contrato de API, inicializacao, dependencias externas e seguranca operacional. A governanca deve preservar o escopo do servico e o seu deploy independente.

Stack detectada: $stack.
Frameworks detectados: $frameworks.
EOF
      ;;
    *)
      cat <<EOF
O projeto aparenta ser um monolito unico. A governanca deve privilegiar coesao local, limites de pacote claros e crescimento incremental da estrutura.

Stack detectada: $stack.
Frameworks detectados: $frameworks.
EOF
      ;;
  esac
}

build_dependency_flow() {
  local active_languages=0
  should_include_go && active_languages=$((active_languages + 1))
  should_include_node && active_languages=$((active_languages + 1))
  should_include_python && active_languages=$((active_languages + 1))

  if [[ "$active_languages" -gt 1 ]]; then
    cat <<'EOF'
- Cada stack deve expor contratos por fronteiras estaveis (HTTP/gRPC/eventos/arquivos), sem assumir detalhes internos de runtime de outra linguagem.
- Mudancas em contratos compartilhados devem atualizar produtores e consumidores da stack afetada e validar cada runtime com seu proprio toolchain.
- Compartilhar schemas, payloads e semantica operacional e aceitavel; compartilhar convencoes de framework, helpers de runtime ou acoplamento de deploy entre linguagens nao e.
EOF
    return
  fi

  if should_include_go; then
    cat <<'EOF'
- Transporte e adapters devem depender de casos de uso ou servicos explicitos, nao do contrario.
- Dominio nao deve conhecer detalhes de HTTP, banco, filas, serializacao ou drivers.
- Infraestrutura pode implementar contratos consumidos pela aplicacao, preservando dependencia para dentro.
EOF
    return
  fi

  if should_include_node; then
    cat <<'EOF'
- Controllers e routers devem depender de services ou use cases, nao do contrario.
- Dominio nao deve importar detalhes de framework (Express, Fastify, NestJS), ORM ou drivers.
- Infraestrutura implementa interfaces consumidas pela camada de aplicacao, preservando dependencia para dentro.
EOF
    return
  fi

  if should_include_python; then
    cat <<'EOF'
- Routers e handlers devem depender de services ou use cases, nao do contrario.
- Dominio nao deve importar detalhes de framework (FastAPI, Django, Flask), ORM ou drivers.
- Infraestrutura implementa contratos consumidos pela camada de aplicacao, preservando dependencia para dentro.
EOF
    return
  fi

  cat <<'EOF'
- Dependencias devem apontar de bordas externas para o nucleo do negocio.
- Detalhes de framework, IO e persistencia nao devem vazar para o centro do sistema.
EOF
}

build_architecture_rules() {
  local architecture_type="$1"

  case "$architecture_type" in
    monorepo)
      cat <<'EOF'
## Regras por Arquitetura

1. Limitar mudancas ao workspace, pacote ou servico afetado.
2. Nao criar dependencias internas cruzadas sem contrato explicito.
3. Validar primeiro apenas os workspaces impactados antes de ampliar o escopo.
EOF
      ;;
    "monolito modular")
      cat <<'EOF'
## Regras por Arquitetura

1. Respeitar fronteiras entre modulos e bounded contexts.
2. Evitar dependencia circular entre packages internos.
3. Nao extrair shared helpers sem demanda comprovada de mais de um modulo.
EOF
      ;;
    microservico)
      cat <<'EOF'
## Regras por Arquitetura

1. Preservar contratos publicados e compatibilidade de integracao.
2. Manter inicializacao, observabilidade e shutdown como parte do comportamento do servico.
3. Nao acoplar o servico a convencoes de outros servicos sem contrato explicito.
EOF
      ;;
    *)
      cat <<'EOF'
## Regras por Arquitetura

1. Preservar coesao local e dependencia unidirecional entre packages.
2. Evitar helpers transversais que escondam regra de negocio ou IO.
3. Crescer a estrutura apenas quando o codigo atual ja nao comportar a mudanca com clareza.
EOF
      ;;
  esac
}

build_language_rules() {
  local output=""

  if should_include_go; then
    output+="Para tarefas que alteram codigo Go, carregar tambem:\n\n- \`.agents/skills/go-implementation/SKILL.md\`\n"
    output+="\nPara tarefas de revisao ou refatoracao incremental de design em Go guiadas por heuristicas de object calisthenics, carregar tambem:\n\n- \`.agents/skills/object-calisthenics-go/SKILL.md\`\n"
  fi

  if should_include_node; then
    output+="\nPara tarefas que alteram codigo Node/TypeScript, carregar tambem:\n\n- \`.agents/skills/node-implementation/SKILL.md\`\n"
  fi

  if should_include_python; then
    output+="\nPara tarefas que alteram codigo Python, carregar tambem:\n\n- \`.agents/skills/python-implementation/SKILL.md\`\n"
  fi

  printf '%b' "$output"
}

build_language_references() {
  # Referencias nao sao mais listadas individualmente no AGENTS.md.
  # Cada skill lista suas proprias referencias em SKILL.md.
  printf ''
}

build_validation_commands() {
  local lines=()
  local toolchain_script="$ROOT_DIR/.agents/skills/agent-governance/scripts/detect-toolchain.sh"
  local toolchain_json=""

  lines+=("Seguir Etapa 4 de \`.agents/skills/agent-governance/SKILL.md\` como base canonica.")
  lines+=("")

  if [[ -x "$toolchain_script" || -f "$toolchain_script" ]]; then
    toolchain_json="$(bash "$toolchain_script" "$PROJECT_DIR" 2>/dev/null || true)"
  fi

  if [[ -n "$toolchain_json" ]]; then
    local detected_lines=()

    # Parse toolchain JSON using python3 when available, otherwise pure bash.
    _parse_toolchain_python() {
      TOOLCHAIN_JSON="$toolchain_json" python3 - <<'PY'
import json, os
payload = json.loads(os.environ["TOOLCHAIN_JSON"])
labels = {"go": "Go", "node": "Node", "python": "Python"}
for key in ["go", "node", "python"]:
    data = payload.get(key)
    if not isinstance(data, dict):
        continue
    cmds = []
    if data.get("fmt"):   cmds.append(f"fmt: `{data['fmt']}`")
    if data.get("test"):  cmds.append(f"test: `{data['test']}`")
    if data.get("lint"):  cmds.append(f"lint: `{data['lint']}`")
    if cmds:
        print(f"Comandos detectados no projeto ({labels[key]}):")
        for i, cmd in enumerate(cmds, 1): print(f"{i}. Rodar {cmd}.")
PY
    }

    # Pure-bash fallback: extract values from simple JSON like {"go":{"fmt":"...","test":"...","lint":"..."}}
    _parse_toolchain_bash() {
      local lang label fmt_val test_val lint_val
      for lang in go node python; do
        case "$lang" in
          go) label="Go" ;; node) label="Node" ;; python) label="Python" ;;
        esac
        # Check if language key exists in JSON
        echo "$toolchain_json" | grep -q "\"$lang\"" || continue
        # Extract block for this language (simple single-level parsing)
        local block
        block="$(printf '%s' "$toolchain_json" | sed "s/.*\"$lang\":{//" | sed 's/}.*//')"
        [[ -n "$block" ]] || continue
        # Extract individual values (handles both "value" and null)
        fmt_val="$(printf '%s' "$block" | grep -o '"fmt":"[^"]*"' | sed 's/"fmt":"//;s/"//' || true)"
        test_val="$(printf '%s' "$block" | grep -o '"test":"[^"]*"' | sed 's/"test":"//;s/"//' || true)"
        lint_val="$(printf '%s' "$block" | grep -o '"lint":"[^"]*"' | sed 's/"lint":"//;s/"//' || true)"
        local cmds=() idx=1
        [[ -n "$fmt_val" ]]  && cmds+=("$idx. Rodar fmt: \`$fmt_val\`.") && idx=$((idx + 1))
        [[ -n "$test_val" ]] && cmds+=("$idx. Rodar test: \`$test_val\`.") && idx=$((idx + 1))
        [[ -n "$lint_val" ]] && cmds+=("$idx. Rodar lint: \`$lint_val\`.")
        if [[ ${#cmds[@]} -gt 0 ]]; then
          printf 'Comandos detectados no projeto (%s):\n' "$label"
          printf '%s\n' "${cmds[@]}"
        fi
      done
    }

    local detected_output=""
    if command -v python3 >/dev/null 2>&1; then
      detected_output="$(_parse_toolchain_python 2>/dev/null || _parse_toolchain_bash)"
    else
      detected_output="$(_parse_toolchain_bash)"
    fi

    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      detected_lines+=("$line")
    done <<< "$detected_output"
    if [[ ${#detected_lines[@]} -gt 0 ]]; then
      lines+=("${detected_lines[@]}")
      printf '%s\n' "${lines[@]}"
      return
    fi
  fi

  if should_include_go; then
    lines+=("Comandos especificos do projeto (Go):")
    lines+=("1. Rodar \`gofmt\` nos arquivos Go alterados.")
    if file_exists ".golangci.yml" || file_exists ".golangci.yaml" || file_exists ".golangci.toml"; then
      lines+=("2. Rodar \`golangci-lint run\` como passo de lint.")
    fi
    lines+=("3. Rodar primeiro testes direcionados e depois \`go test ./...\` quando o custo for proporcional.")
    lines+=("4. Rodar \`go vet ./...\` quando esse passo fizer parte do gate do projeto.")
  fi

  if should_include_node; then
    lines+=("Comandos especificos do projeto (Node):")
    lines+=("1. Rodar formatter dos arquivos alterados quando o projeto oferecer esse passo.")
    lines+=("2. Rodar o comando de teste detectado no workspace afetado.")
    lines+=("3. Rodar o comando de lint detectado no workspace afetado quando esse passo existir.")
  fi

  if should_include_python; then
    lines+=("Comandos especificos do projeto (Python):")
    lines+=("1. Rodar formatter do projeto quando houver comando detectado.")
    lines+=("2. Rodar o comando de teste detectado no package afetado.")
    lines+=("3. Rodar o lint detectado no package afetado quando disponivel.")
  fi

  printf '%s\n' "${lines[@]}"
}

build_architecture_restrictions() {
  local architecture_type="$1"

  case "$architecture_type" in
    monorepo)
      cat <<'EOF'
5. Nao alterar contratos entre workspaces sem deixar o impacto explicito.
EOF
      ;;
    microservico)
      cat <<'EOF'
5. Nao alterar contratos externos, readiness, observabilidade ou semantica operacional sem explicitar a mudanca.
EOF
      ;;
    *)
      printf ''
      ;;
  esac
}

build_stack_section() {
  local lines=()
  local has_stack=0

  if should_include_go && file_exists "go.mod"; then
    lines+=("- Projeto com contexto Go detectado: carregar \`.agents/skills/go-implementation/SKILL.md\` ao alterar codigo Go.")
    lines+=("- Validar a versao declarada em \`go.mod\` antes de introduzir APIs da linguagem ou novas dependencias.")
    has_stack=1
  fi

  if should_include_node && (file_exists "package.json" || file_exists "tsconfig.json"); then
    lines+=("- Projeto com contexto Node/TypeScript detectado: carregar \`.agents/skills/node-implementation/SKILL.md\` ao alterar codigo Node/TS.")
    lines+=("- Validar versao de Node em \`engines\` ou \`.nvmrc\` antes de usar APIs recentes.")
    has_stack=1
  fi

  if should_include_python && (file_exists "pyproject.toml" || file_exists "requirements.txt" || file_exists "setup.py" || file_exists "Pipfile"); then
    lines+=("- Projeto com contexto Python detectado: carregar \`.agents/skills/python-implementation/SKILL.md\` ao alterar codigo Python.")
    lines+=("- Validar versao de Python em \`pyproject.toml\` ou \`.python-version\` antes de usar APIs recentes.")
    has_stack=1
  fi

  if [[ "$has_stack" -eq 0 ]]; then
    printf ''
    return
  fi

  printf '## Stack\n\n'
  printf '%s\n' "${lines[@]}"
}

render_template() {
  local template_path="$1"
  shift

  # Coleta todos os pares key=value em variaveis de ambiente indexadas
  # e aplica todas as substituicoes em uma unica passagem de awk.
  local env_args=()
  local pair_count=0
  while [[ $# -gt 1 ]]; do
    env_args+=("RENDER_K_${pair_count}={{$1}}" "RENDER_V_${pair_count}=$2")
    pair_count=$((pair_count + 1))
    shift 2
  done

  # Captura em variavel para preservar comportamento de trim de trailing newlines.
  # Usa index/substr para substituicao literal (sem regex, sem tratamento de & ou \).
  local content
  content="$(env "${env_args[@]}" RENDER_COUNT="$pair_count" awk '
    BEGIN {
      n = ENVIRON["RENDER_COUNT"] + 0
      for (i = 0; i < n; i++) {
        keys[i] = ENVIRON["RENDER_K_" i]
        vals[i] = ENVIRON["RENDER_V_" i]
      }
    }
    {
      for (i = 0; i < n; i++) {
        result = ""
        rest = $0
        while ((pos = index(rest, keys[i])) > 0) {
          result = result substr(rest, 1, pos - 1) vals[i]
          rest = substr(rest, pos + length(keys[i]))
        }
        $0 = result rest
      }
      print
    }
  ' "$template_path")"

  printf '%s\n' "$content"
}

ARCHITECTURE_TYPE="$(detect_architecture_type)"
ARCHITECTURAL_PATTERN="$(detect_architectural_pattern)"
FRAMEWORKS="$(detect_frameworks)"
PRIMARY_STACK="$(detect_primary_stack)"
DIRECTORY_TREE="$(build_directory_tree)"
ARCHITECTURE_DESCRIPTION="$(build_architecture_description "$ARCHITECTURE_TYPE" "$PRIMARY_STACK" "$FRAMEWORKS")"
DEPENDENCY_FLOW="$(build_dependency_flow)"
ARCHITECTURE_RULES="$(build_architecture_rules "$ARCHITECTURE_TYPE")"
LANGUAGE_RULES="$(build_language_rules)"
LANGUAGE_REFERENCES="$(build_language_references)"
VALIDATION_COMMANDS="$(build_validation_commands)"
ARCHITECTURE_RESTRICTIONS="$(build_architecture_restrictions "$ARCHITECTURE_TYPE")"
STACK_SECTION="$(build_stack_section)"

# GOVERNANCE_PROFILE: compact strips verbose sections for smaller context windows (Haiku, Codex).
# Default: standard (full output). Auto-detect compact when only Codex is installed.
if [[ -z "${GOVERNANCE_PROFILE:-}" ]]; then
  if [[ "${INSTALL_CODEX:-0}" == "1" && "${INSTALL_CLAUDE:-0}" == "0" && "${INSTALL_GEMINI:-0}" == "0" && "${INSTALL_COPILOT:-0}" == "0" ]]; then
    GOVERNANCE_PROFILE="compact"
  else
    GOVERNANCE_PROFILE="standard"
  fi
fi

GOVERNANCE_SCHEMA_VERSION="1.1.0"

_agents_content="$(render_template \
  "$SKILL_DIR/assets/agents-template.md" \
  "GOVERNANCE_SCHEMA_VERSION" "$GOVERNANCE_SCHEMA_VERSION" \
  "TIPO_ARQUITETURA" "$ARCHITECTURE_TYPE" \
  "DESCRICAO_ARQUITETURA" "$ARCHITECTURE_DESCRIPTION" \
  "ARVORE_DIRETORIOS" "$DIRECTORY_TREE" \
  "PADRAO_ARQUITETURAL" "$ARCHITECTURAL_PATTERN" \
  "FLUXO_DEPENDENCIAS" "$DEPENDENCY_FLOW" \
  "REGRAS_ARQUITETURA" "$ARCHITECTURE_RULES" \
  "REGRAS_LINGUAGEM" "$LANGUAGE_RULES" \
  "REFERENCIAS_LINGUAGEM" "$LANGUAGE_REFERENCES" \
  "COMANDOS_VALIDACAO" "$VALIDATION_COMMANDS" \
  "RESTRICOES_ARQUITETURA" "$ARCHITECTURE_RESTRICTIONS")"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] Geraria AGENTS.md (schema $GOVERNANCE_SCHEMA_VERSION, profile $GOVERNANCE_PROFILE)"
  [[ "$INSTALL_CLAUDE" == "1" ]]  && echo "[dry-run] Geraria CLAUDE.md"
  [[ "$INSTALL_GEMINI" == "1" ]]  && echo "[dry-run] Geraria GEMINI.md"
  [[ "$INSTALL_CODEX" == "1" ]]   && echo "[dry-run] Geraria .codex/config.toml"
  [[ "$INSTALL_COPILOT" == "1" ]] && echo "[dry-run] Geraria .github/copilot-instructions.md"
else
  printf '%s\n' "$_agents_content" > "$PROJECT_DIR/AGENTS.md"

  if [[ "$GOVERNANCE_PROFILE" == "compact" ]]; then
    awk '
      BEGIN { skip=0 }
      /^## Diretrizes de Estrutura$/ { skip=1; next }
      /^### Composicao Multi-Linguagem$/ { skip=1; next }
      /^## / && skip { skip=0 }
      skip { next }
      { print }
    ' "$PROJECT_DIR/AGENTS.md" > "$PROJECT_DIR/AGENTS.md.tmp" && \
    mv "$PROJECT_DIR/AGENTS.md.tmp" "$PROJECT_DIR/AGENTS.md"
  fi

  # Append local extensions if present (never overwritten by upgrade)
  if [[ -f "$PROJECT_DIR/AGENTS.local.md" ]]; then
    printf '\n' >> "$PROJECT_DIR/AGENTS.md"
    cat "$PROJECT_DIR/AGENTS.local.md" >> "$PROJECT_DIR/AGENTS.md"
  fi

  AI_TOOL_TEMPLATE="$SKILL_DIR/assets/ai-tool-template.md"

  if [[ "$INSTALL_CLAUDE" == "1" ]]; then
    render_template "$AI_TOOL_TEMPLATE" \
      "TOOL_NAME" "Claude Code" \
      "TOOL_INSTRUCTION" "fonte canonica das regras" \
      "CONFIG_LINE_2" "\`.claude/skills/\` sao symlinks para \`.agents/skills/\` — a fonte de verdade e sempre \`.agents/skills/\`." \
      "CONFIG_LINE_3" "\`.claude/agents/\` sao wrappers leves que delegam para a habilidade canonica." \
      "SECAO_STACK" "$STACK_SECTION" \
      > "$PROJECT_DIR/CLAUDE.md"
  fi

  if [[ "$INSTALL_GEMINI" == "1" ]]; then
    render_template "$AI_TOOL_TEMPLATE" \
      "TOOL_NAME" "Gemini CLI" \
      "TOOL_INSTRUCTION" "fonte canonica das regras" \
      "CONFIG_LINE_2" "\`.agents/skills/\` e a fonte de verdade dos fluxos procedurais." \
      "CONFIG_LINE_3" "\`.gemini/commands/\` sao adaptadores finos que apontam para a habilidade correta." \
      "SECAO_STACK" "$STACK_SECTION" \
      > "$PROJECT_DIR/GEMINI.md"
    # Append Gemini-specific guidance (no hooks/agents support)
    cat >> "$PROJECT_DIR/GEMINI.md" <<'GEMINI_EXTRA'

## Orientacoes Especificas para Gemini

O Gemini CLI nao suporta hooks, agents ou rules nativos. Para modelar o fluxo de governanca:

1. Ao iniciar uma tarefa, ler `AGENTS.md` e `.agents/skills/agent-governance/SKILL.md` como contexto base antes de editar codigo.
2. Usar `@<command>` para invocar o comando TOML correspondente a skill desejada.
3. Seguir as etapas procedurais do SKILL.md carregado pelo comando como se fossem instrucoes sequenciais.
4. Ao final da tarefa, executar os comandos de validacao descritos na secao Validacao do `AGENTS.md`.
5. Nao confiar em enforcement automatico — a compliance depende de seguir as instrucoes procedurais manualmente.
GEMINI_EXTRA
  fi

  if [[ "$INSTALL_CODEX" == "1" ]]; then
    mkdir -p "$PROJECT_DIR/.codex"
    _codex_go=0; _codex_node=0; _codex_python=0
    should_include_go && _codex_go=1
    should_include_node && _codex_node=1
    should_include_python && _codex_python=1
    build_codex_config "$_codex_go" "$_codex_node" "$_codex_python" > "$PROJECT_DIR/.codex/config.toml"
  fi

  if [[ "$INSTALL_COPILOT" == "1" ]]; then
    render_template "$AI_TOOL_TEMPLATE" \
      "TOOL_NAME" "GitHub Copilot CLI" \
      "TOOL_INSTRUCTION" "instrucao principal" \
      "CONFIG_LINE_2" "\`.agents/skills/\` e a fonte de verdade dos fluxos procedurais." \
      "CONFIG_LINE_3" "\`.github/agents/\` sao wrappers leves que apontam para a habilidade correta." \
      "SECAO_STACK" "$STACK_SECTION" \
      > "$PROJECT_DIR/.github/copilot-instructions.md"
    # Append Copilot-specific guidance
    cat >> "$PROJECT_DIR/.github/copilot-instructions.md" <<'COPILOT_EXTRA'

## Orientacoes Especificas para Copilot

O GitHub Copilot suporta agents em `.github/agents/` e carrega `copilot-instructions.md` automaticamente, mas nao suporta hooks de enforcement. Para manter compliance:

1. Usar agents disponíveis em `.github/agents/` para delegar tarefas processuais (review, bugfix, execute-task, etc.).
2. Cada agent aponta para a skill canonica em `.agents/skills/` — seguir as etapas procedurais do SKILL.md referenciado.
3. Ao iniciar uma tarefa, confirmar que `AGENTS.md` e `agent-governance/SKILL.md` foram lidos.
4. Ao final da tarefa, executar os comandos de validacao descritos na secao Validacao acima.
5. Enforcement depende do modelo seguir as instrucoes — nao ha bloqueio automatico.
COPILOT_EXTRA
  fi
fi

printf 'Arquitetura detectada: %s\n' "$ARCHITECTURE_TYPE"
printf 'Stack detectada: %s\n' "$PRIMARY_STACK"
printf 'Frameworks detectados: %s\n' "$FRAMEWORKS"
