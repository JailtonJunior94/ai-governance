#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$SKILL_DIR/../../.." && pwd)"

PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

INSTALL_CLAUDE="${INSTALL_CLAUDE:-0}"
INSTALL_GEMINI="${INSTALL_GEMINI:-0}"
INSTALL_COPILOT="${INSTALL_COPILOT:-0}"

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

file_exists() {
  [[ -e "$PROJECT_DIR/$1" ]]
}

has_any_files() {
  local dir="$1"
  [[ -d "$PROJECT_DIR/$dir" ]] || return 1
  find "$PROJECT_DIR/$dir" -mindepth 1 -maxdepth 1 | read -r _
}

detect_architecture_type() {
  if file_exists "go.work" || has_any_files "services" || has_any_files "apps" || has_any_files "packages"; then
    printf 'monorepo'
    return
  fi

  if has_any_files "internal" || has_any_files "modules" || has_any_files "domains"; then
    printf 'monolito modular'
    return
  fi

  if file_exists "Dockerfile" || file_exists "docker-compose.yml" || file_exists "docker-compose.yaml" || has_any_files "deployments" || has_any_files "k8s"; then
    printf 'microservico'
    return
  fi

  printf 'monolito'
}

detect_architectural_pattern() {
  if has_any_files "domain" || has_any_files "application" || has_any_files "infrastructure" || has_any_files "ports" || has_any_files "adapters"; then
    printf 'Predominio de Clean Architecture / Hexagonal com fronteiras explicitas entre dominio, aplicacao e infraestrutura.'
    return
  fi

  if has_any_files "controllers" || has_any_files "services" || has_any_files "repositories" || has_any_files "models"; then
    printf 'Predominio de arquitetura em camadas, com separacao entre transporte, servicos, persistencia e modelos.'
    return
  fi

  if has_any_files "features" || has_any_files "feature"; then
    printf 'Predominio de organizacao por funcionalidade / fatiamento vertical, agrupando fluxo e dependencias por capacidade de negocio.'
    return
  fi

  if has_any_files "internal"; then
    printf 'Predominio de packages internos coesos, com estrutura orientada por dominio ou componente.'
    return
  fi

  printf 'Padrao arquitetural nao inferido com alta confianca; assumir composicao simples e dependencias explicitas.'
}

detect_frameworks() {
  local frameworks=()

  if file_exists "go.mod"; then
    if grep -q 'github.com/gin-gonic/gin' "$PROJECT_DIR/go.mod"; then
      frameworks+=("Gin")
    fi
    if grep -q 'github.com/labstack/echo' "$PROJECT_DIR/go.mod"; then
      frameworks+=("Echo")
    fi
    if grep -q 'github.com/gofiber/fiber' "$PROJECT_DIR/go.mod"; then
      frameworks+=("Fiber")
    fi
    if grep -q 'google.golang.org/grpc' "$PROJECT_DIR/go.mod"; then
      frameworks+=("gRPC")
    fi
    if grep -q 'connectrpc.com/connect' "$PROJECT_DIR/go.mod"; then
      frameworks+=("Connect")
    fi
  fi

  if [[ ${#frameworks[@]} -eq 0 ]]; then
    printf 'nenhum framework dominante identificado'
    return
  fi

  local joined
  joined="$(IFS=', '; printf '%s' "${frameworks[*]}")"
  printf '%s' "$joined"
}

detect_primary_stack() {
  local parts=()

  if file_exists "go.mod"; then
    parts+=("Go")
  fi
  if file_exists "package.json"; then
    parts+=("Node.js")
  fi
  if file_exists "pyproject.toml" || file_exists "requirements.txt"; then
    parts+=("Python")
  fi
  if file_exists "pom.xml" || file_exists "build.gradle" || file_exists "build.gradle.kts"; then
    parts+=("Java/Kotlin")
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
  tree="$(cd "$PROJECT_DIR" && find . \
    \( -path './.git' -o -path './.agents' -o -path './.claude' -o -path './.codex' -o -path './.gemini' -o -path './node_modules' -o -path './vendor' -o -path './dist' -o -path './build' -o -path './bin' -o -path './target' -o -path './__pycache__' \) -prune \
    -o -print | sed 's#^\./##' | awk 'NR <= 80 { print }')"

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
  if file_exists "go.mod"; then
    cat <<'EOF'
- Transporte e adapters devem depender de casos de uso ou servicos explicitos, nao do contrario.
- Dominio nao deve conhecer detalhes de HTTP, banco, filas, serializacao ou drivers.
- Infraestrutura pode implementar contratos consumidos pela aplicacao, preservando dependencia para dentro.
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

  if file_exists "go.mod"; then
    output+="Para tarefas que alteram codigo Go, carregar tambem:\n\n- \`.agents/skills/go-implementation/SKILL.md\`\n"
  fi

  printf '%b' "$output"
}

build_language_references() {
  local output=""

  if file_exists "go.mod"; then
    output+="## Referencias da Skill Go\n\nLer conforme necessidade:\n\n"
    output+="- \`.agents/skills/go-implementation/references/governance.md\`\n"
    output+="- \`.agents/skills/go-implementation/references/architecture.md\`\n"
    output+="- \`.agents/skills/go-implementation/references/go-standards.md\`\n"
    output+="- \`.agents/skills/go-implementation/references/interfaces.md\`\n"
    output+="- \`.agents/skills/go-implementation/references/generics.md\`\n"
    output+="- \`.agents/skills/go-implementation/references/concurrency.md\`\n"
    output+="- \`.agents/skills/go-implementation/references/design-patterns.md\`\n"
    output+="- \`.agents/skills/go-implementation/references/observability.md\`\n"
    output+="- \`.agents/skills/go-implementation/references/api.md\`\n"
    output+="- \`.agents/skills/go-implementation/references/persistence.md\`\n"
    output+="- \`.agents/skills/go-implementation/references/configuration.md\`\n"
    output+="- \`.agents/skills/go-implementation/references/implementation-examples.md\`\n"
  fi

  printf '%b' "$output"
}

build_validation_commands() {
  local lines=()

  if file_exists "go.mod"; then
    lines+=("1. Rodar \`gofmt\` nos arquivos Go alterados.")
    if file_exists ".golangci.yml" || file_exists ".golangci.yaml" || file_exists ".golangci.toml"; then
      lines+=("2. Rodar \`golangci-lint run\` quando o contexto local oferecer esse passo.")
      lines+=("3. Rodar primeiro testes direcionados e depois \`go test ./...\` quando o custo for proporcional.")
      lines+=("4. Rodar \`go vet ./...\` quando esse passo fizer parte do gate do projeto.")
      lines+=("5. Informar falhas com o comando exato e um diagnostico curto.")
    else
      lines+=("2. Rodar primeiro testes direcionados e depois \`go test ./...\` quando o custo for proporcional.")
      lines+=("3. Rodar \`go vet ./...\` quando esse passo fizer parte do gate do projeto.")
      lines+=("4. Rodar lint se o contexto oferecer esse passo.")
      lines+=("5. Informar falhas com o comando exato e um diagnostico curto.")
    fi
  elif file_exists "package.json"; then
    lines+=("1. Rodar formatter dos arquivos alterados quando o projeto oferecer esse passo.")
    lines+=("2. Rodar \`npm test\` ou o comando equivalente do contexto.")
    lines+=("3. Rodar \`npm run lint\` quando esse passo existir.")
    lines+=("4. Informar falhas com o comando exato e um diagnostico curto.")
  else
    lines+=("1. Rodar formatter dos arquivos alterados.")
    lines+=("2. Rodar primeiro testes direcionados.")
    lines+=("3. Rodar testes mais amplos quando o custo for proporcional.")
    lines+=("4. Rodar lint se o contexto oferecer esse passo.")
    lines+=("5. Informar falhas com o comando exato e um diagnostico curto.")
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

  if file_exists "go.mod"; then
    lines+=("## Stack")
    lines+=("")
    lines+=("- Projeto com contexto Go detectado: carregar \`.agents/skills/go-implementation/SKILL.md\` ao alterar codigo Go.")
    lines+=("- Validar a versao declarada em \`go.mod\` antes de introduzir APIs da linguagem ou novas dependencias.")
  fi

  printf '%s\n' "${lines[@]}"
}

render_template() {
  local template_path="$1"
  shift

  local content
  content="$(cat "$template_path")"

  while [[ $# -gt 1 ]]; do
    local key="$1"
    local value="$2"
    shift 2
    content="${content//\{\{$key\}\}/$value}"
  done

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

render_template \
  "$SKILL_DIR/assets/agents-template.md" \
  "TIPO_ARQUITETURA" "$ARCHITECTURE_TYPE" \
  "DESCRICAO_ARQUITETURA" "$ARCHITECTURE_DESCRIPTION" \
  "ARVORE_DIRETORIOS" "$DIRECTORY_TREE" \
  "PADRAO_ARQUITETURAL" "$ARCHITECTURAL_PATTERN" \
  "FLUXO_DEPENDENCIAS" "$DEPENDENCY_FLOW" \
  "REGRAS_ARQUITETURA" "$ARCHITECTURE_RULES" \
  "REGRAS_LINGUAGEM" "$LANGUAGE_RULES" \
  "REFERENCIAS_LINGUAGEM" "$LANGUAGE_REFERENCES" \
  "COMANDOS_VALIDACAO" "$VALIDATION_COMMANDS" \
  "RESTRICOES_ARQUITETURA" "$ARCHITECTURE_RESTRICTIONS" \
  > "$PROJECT_DIR/AGENTS.md"

if [[ "$INSTALL_CLAUDE" == "1" ]]; then
  render_template "$SKILL_DIR/assets/claude-template.md" "SECAO_STACK" "$STACK_SECTION" > "$PROJECT_DIR/CLAUDE.md"
fi

if [[ "$INSTALL_GEMINI" == "1" ]]; then
  render_template "$SKILL_DIR/assets/gemini-template.md" "SECAO_STACK" "$STACK_SECTION" > "$PROJECT_DIR/GEMINI.md"
fi

if [[ "$INSTALL_COPILOT" == "1" ]]; then
  render_template "$SKILL_DIR/assets/copilot-template.md" "SECAO_STACK" "$STACK_SECTION" > "$PROJECT_DIR/.github/copilot-instructions.md"
fi

printf 'Arquitetura detectada: %s\n' "$ARCHITECTURE_TYPE"
printf 'Stack detectada: %s\n' "$PRIMARY_STACK"
printf 'Frameworks detectados: %s\n' "$FRAMEWORKS"
