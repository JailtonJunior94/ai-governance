#!/usr/bin/env bash
# Gera o scaffold de uma nova skill de linguagem.
# Uso: bash scripts/scaffold-lang-skill.sh <nome-linguagem>
# Exemplo: bash scripts/scaffold-lang-skill.sh rust
#
# Cria:
#   .agents/skills/<nome>-implementation/SKILL.md
#   .agents/skills/<nome>-implementation/references/ (stubs)
#   .gemini/commands/<nome>-implementation.toml
#   Instrucoes para atualizar manualmente: test-adapter-parity.sh, codex config, install.sh

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <nome-linguagem>"
  echo "Exemplo: $0 rust"
  exit 1
fi

LANG="$1"
SKILL_NAME="${LANG}-implementation"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$ROOT_DIR/.agents/skills/$SKILL_NAME"

if [[ -d "$SKILL_DIR" ]]; then
  echo "ERRO: skill '$SKILL_NAME' ja existe em $SKILL_DIR"
  exit 1
fi

echo "Criando scaffold para skill: $SKILL_NAME"

# --- SKILL.md ---
mkdir -p "$SKILL_DIR/references"

cat > "$SKILL_DIR/SKILL.md" << 'SKILL_EOF'
---
name: __SKILL_NAME__
version: 1.0.0
description: Implementa alteracoes em codigo __LANG_UPPER__ usando governanca base, convencoes de projeto e validacao proporcional. Use quando a tarefa exigir adicionar, corrigir, refatorar ou validar codigo __LANG_UPPER__. Nao use para tarefas sem codigo __LANG_UPPER__.
---

# Implementacao __LANG_UPPER__

## Procedimentos

**Etapa 1: Carregar base obrigatoria**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Identificar arquivo de configuracao do projeto (TODO: adaptar ao ecossistema).
3. Executar `bash .agents/skills/agent-governance/scripts/detect-toolchain.sh` para descobrir comandos de fmt, test e lint.

**Etapa 2: Selecionar apenas o contexto necessario**
1. Ler `references/conventions.md` quando a tarefa envolver estrutura de projeto, organizacao de modulos ou padroes de importacao.
2. Ler `references/architecture.md` quando a tarefa envolver layout de diretorios, injecao de dependencias ou fronteiras entre camadas.
3. Ler `references/testing.md` quando a tarefa envolver estrategia de testes, fixtures ou cobertura.
4. Ler `references/error-handling.md` quando a tarefa criar, propagar, encapsular ou apresentar erros.
5. Ler `references/api.md` quando a tarefa envolver handlers HTTP, middlewares, DTOs, validacao de request ou serializacao.
6. Ler `references/patterns.md` quando a tarefa envolver dependency injection, repository, factory, strategy ou organizacao de modulos.
7. Ler `references/observability.md` quando a tarefa envolver logging, tracing, metricas ou health checks.
8. Ler `references/concurrency.md` quando a tarefa envolver controle de concorrencia, paralelismo ou sincronizacao.
9. Ler `references/resilience.md` quando a tarefa envolver retries, circuit breakers, timeouts em chamadas externas, fallbacks ou health checks.
10. Ler `references/persistence.md` quando a tarefa envolver repositories, transactions, migrations, queries ou connection management.
11. Ler `references/security.md` quando a tarefa envolver autenticacao, autorizacao, validacao de input, rate limiting, CORS ou tratamento de segredos.
12. Ler `references/build.md` quando a tarefa envolver Dockerfile, pipeline de CI, packaging, gerenciamento de dependencias ou distribuicao.
13. Ler `references/examples-domain-flow.md` quando a tarefa precisar de esqueleto concreto de fluxo end-to-end (entidade, use case, handler, teste).

**Economia de contexto**
Se mais de 4 referencias forem necessarias para a mesma tarefa, priorizar as 3 mais criticas para o escopo da mudanca e registrar as demais como contexto nao carregado. Carregar referencias adicionais apenas se a implementacao revelar necessidade concreta.

**Etapa 3: Modelar a alteracao**
1. Identificar o menor conjunto seguro de mudancas que satisfaz a solicitacao.
2. Mapear o comportamento afetado, as dependencias envolvidas e o risco de regressao.
3. Respeitar o estilo existente do projeto.

**Etapa 4: Implementar**
1. Editar o codigo seguindo as convencoes do contexto analisado.
2. Atualizar ou adicionar testes para toda mudanca de comportamento.
3. Adaptar exemplos ao contexto real em vez de replica-los literalmente.

**Etapa 5: Validar**
1. Seguir Etapa 4 de `.agents/skills/agent-governance/SKILL.md`.
2. Usar os comandos de fmt, test e lint detectados pelo toolchain.

## Tratamento de Erros
* Se nenhum arquivo de configuracao do projeto for encontrado, parar antes de assumir versao ou dependencias.
* Se o projeto usar monorepo, validar apenas os packages afetados pela mudanca.
* Se houver conflito entre esta skill e a governanca base, seguir a restricao mais segura e registrar a suposicao.
SKILL_EOF

# Substituir placeholders
LANG_UPPER="$(echo "$LANG" | tr '[:lower:]' '[:upper:]')"
sed -i '' "s/__SKILL_NAME__/$SKILL_NAME/g" "$SKILL_DIR/SKILL.md"
sed -i '' "s/__LANG_UPPER__/$LANG_UPPER/g" "$SKILL_DIR/SKILL.md"

# --- Reference stubs ---
REFS=(conventions architecture testing error-handling api patterns observability concurrency resilience persistence security build examples-domain-flow)

for ref in "${REFS[@]}"; do
  cat > "$SKILL_DIR/references/${ref}.md" << REF_EOF
> **Carregar quando:** TODO — **Escopo:** TODO

# $(echo "$ref" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

## Objetivo
TODO: descrever objetivo desta referencia para $LANG_UPPER.

## Diretrizes
- TODO

## Proibido
- TODO
REF_EOF
done

# --- Gemini command ---
GEMINI_CMD="$ROOT_DIR/.gemini/commands/${SKILL_NAME}.toml"
cat > "$GEMINI_CMD" << TOML_EOF
description = "Implementa alteracoes em codigo $LANG_UPPER usando a habilidade canonica $SKILL_NAME."
prompt = """
Use \`.agents/skills/$SKILL_NAME/SKILL.md\` como fluxo canonico desta tarefa.
Leia os assets e references sob demanda conforme descrito no SKILL.md.
Nao invente um processo paralelo neste comando.

Aplicar a habilidade a esta solicitacao:
{{args}}
"""
TOML_EOF

echo ""
echo "Scaffold criado com sucesso:"
echo "  Skill:   $SKILL_DIR/SKILL.md"
echo "  Refs:    $SKILL_DIR/references/ (${#REFS[@]} stubs)"
echo "  Gemini:  $GEMINI_CMD"
echo ""
echo "Passos manuais restantes:"
echo "  1. Preencher os stubs em references/ com conteudo real."
echo "  2. Adicionar entrada em tests/test-adapter-parity.sh (secao Gemini commands)."
echo "  3. Adicionar entrada em .codex/config.toml:"
echo "     [[skills.config]]"
echo "     path = \".agents/skills/$SKILL_NAME\""
echo "     enabled = true"
echo "  4. Adicionar bloco de linguagem em install.sh (parse_langs + LANG_SKILLS)."
echo "  5. Adicionar secao em AGENTS.md (Regras por Linguagem)."
echo "  6. Atualizar generate-governance.sh (should_include, build_language_rules, etc.)."
