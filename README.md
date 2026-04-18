# ai-governance

Base de regras compartilhadas para uso com agentes de IA em diferentes CLIs.

O instalador gera `AGENTS.md` e adaptadores de forma contextual a partir da estrutura real do projeto alvo. Cada skill e versionada, carrega referencias sob demanda e pode ser verificada e atualizada em projetos ja instalados.

## Estrutura

```
.agents/skills/                          <- fonte canonica de toda habilidade
  create-prd/                            <- PRD de produto
  create-technical-specification/        <- especificacao tecnica e ADRs
  create-tasks/                          <- decomposicao em tarefas
  execute-task/                          <- implementacao com evidencias
  refactor/                              <- refatoracao segura
  review/                                <- revisao de codigo
  bugfix/                                <- correcao de bugs com remediacao e teste de regressao
  agent-governance/                      <- regras transversais (DDD, seguranca, erros, testes)
  go-implementation/                     <- regras e referencias para Go
  object-calisthenics-go/                <- heuristicas de object calisthenics adaptadas para Go
  analyze-project/                       <- deteccao de arquitetura e geracao de governanca

AGENTS.md                                <- regra canonica compartilhada
CLAUDE.md                                <- adaptador para Claude Code
GEMINI.md                                <- adaptador para Gemini CLI
.github/copilot-instructions.md          <- adaptador para GitHub Copilot CLI
.codex/config.toml                       <- ativacao de skills no Codex

.claude/skills/                          <- symlinks -> .agents/skills/
.claude/agents/                          <- wrappers leves (subagentes)
.claude/rules/                           <- governanca transversal

.gemini/commands/                        <- wrappers leves para Gemini CLI
.github/agents/                          <- wrappers leves para Copilot CLI

tests/                                   <- testes de snapshot para geracao de governanca
upgrade.sh                               <- verificacao e atualizacao de skills em projetos
```

## Contrato de Portabilidade

- **Fonte de verdade procedural**: `.agents/skills/`
- **Regras canonicas**: `AGENTS.md`
- **Adaptadores por plataforma**: wrappers leves que referenciam a habilidade canonica
  - Claude Code: `.claude/skills/` (symlinks), `.claude/agents/`
  - Codex: `.codex/config.toml`
  - Copilot CLI: `.github/copilot-instructions.md`, `.github/agents/`
  - Gemini CLI: `GEMINI.md`, `.gemini/commands/`

## Principio

O processo detalhado mora na habilidade canonica em `.agents/skills/`. Comandos, agentes e adaptadores por plataforma apenas roteiam para a habilidade adequada — nunca duplicam o conteudo.

---

## Instalacao

```bash
bash install.sh /caminho/do/projeto
```

O instalador pergunta quais ferramentas instalar (Claude, Gemini, Codex, Copilot) e gera governanca contextualizada a partir da deteccao automatica de arquitetura e stack.

### Opcoes

| Variavel | Default | Descricao |
|----------|---------|-----------|
| `LINK_MODE` | `symlink` | `symlink` mantem fonte unica; `copy` e mais portavel |
| `GENERATE_CONTEXTUAL_GOVERNANCE` | `1` | `1` detecta e gera; `0` copia sem personalizar |

### Exemplos

Instalacao com symlinks (padrao):

```bash
bash install.sh /caminho/do/projeto
```

Instalacao portavel com copia:

```bash
LINK_MODE=copy bash install.sh /caminho/do/projeto
```

### Simulacao com --dry-run

Para ver o que seria criado ou sobrescrito sem alterar nenhum arquivo:

```bash
bash install.sh --dry-run /caminho/do/projeto
```

O output lista cada operacao que seria executada, prefixada com `[dry-run]`:

```text
Selecione as ferramentas que deseja instalar:

  1) claude
  2) gemini
  3) codex
  4) copilot
  A) Todas

Digite os numeros separados por espaco (exemplo: 1 3) ou A para todas: A

Ferramentas selecionadas: claude gemini codex copilot

-> Instalando Claude Code...
  [dry-run] ln -sfn /fonte/.agents/skills/create-prd -> /alvo/.claude/skills/create-prd
  [dry-run] ln -sfn /fonte/.agents/skills/review -> /alvo/.claude/skills/review
  [dry-run] cp /fonte/.claude/rules/governance.md -> /alvo/.claude/rules/governance.md
  ...
-> Instalando Gemini CLI...
  [dry-run] cp /fonte/.gemini/commands/review.toml -> /alvo/.gemini/commands/review.toml
  ...

-> [dry-run] Geracao de governanca contextual seria executada aqui.

[dry-run] Nenhum arquivo foi alterado.
```

**Motivador**: para um script que escreve e sobrescreve arquivos em projetos alvo, a ausencia de simulacao era um risco operacional. `--dry-run` permite auditoria antes de qualquer efeito colateral.

---

## Atualizacao de Skills com upgrade.sh

Quando o `install.sh` e executado com `LINK_MODE=copy`, o projeto alvo fica com um snapshot congelado das skills. Para verificar se estao desatualizadas e atualiza-las:

### Verificar sem alterar

```bash
bash upgrade.sh --check /caminho/do/projeto
```

Output exemplo:

```text
Verificando skills em: /caminho/do/projeto
Fonte: /caminho/do/ai-governance

  OK  agent-governance (1.0.0)
  OK  go-implementation (1.0.0)
  DESATUALIZADA  review (fonte: 1.1.0, alvo: 1.0.0)
  AUSENTE  bugfix (fonte: 1.0.0)

Resumo: 2 atualizadas, 1 desatualizadas, 1 ausentes

Execute sem --check para atualizar: bash upgrade.sh /caminho/do/projeto
```

### Atualizar

```bash
bash upgrade.sh /caminho/do/projeto
```

Se o projeto usar symlinks, o script detecta e pula a copia (a atualizacao e automatica).

**Motivador**: sem versionamento, nao havia como saber se um projeto copiado estava defasado. O campo `version` no frontmatter de cada `SKILL.md` permite comparacao automatica, e o `upgrade.sh` fecha o ciclo de atualizacao.

---

## Versionamento de Skills

Toda skill carrega um campo `version` no frontmatter YAML:

```yaml
---
name: review
version: 1.0.0
description: Revisa um diff quanto a correcao, seguranca...
---
```

O `upgrade.sh` compara a versao fonte com a versao instalada para cada skill. Skills com `LINK_MODE=symlink` nao precisam de atualizacao manual — refletem automaticamente a versao mais recente.

---

## Deteccao de Arquitetura

O `generate-governance.sh` detecta automaticamente o tipo de projeto para gerar governanca personalizada. A deteccao combina multiplos sinais para evitar falsos positivos:

| Tipo | Sinais combinados |
|------|-------------------|
| **Monorepo** | `go.work`, `pnpm-workspace.yaml`, `nx.json`, `turbo.json`, `lerna.json`; ou `apps/` + `packages/`; ou `services/` + `packages/` |
| **Monolito modular** | `modules/` ou `domains/`; ou `internal/` com >= 3 subdiretorios |
| **Microservico** | `Dockerfile` + pelo menos um sinal de deploy isolado (`k8s/`, `deployments/`, `helm/`, `skaffold.yaml`, `kustomization.yaml`) |
| **Monolito** | Fallback quando nenhum padrao forte e detectado |

**Motivador**: a deteccao anterior usava sinais isolados. `Dockerfile` sozinho classificava como microservico (mas muitos monolitos tem Dockerfile). `internal/` sozinho classificava como monolito modular (mas e padrao Go sem implicar modularidade). A heuristica refinada reduz classificacoes incorretas.

### Testes de Snapshot

Para garantir que mudancas no `generate-governance.sh` nao introduzam regressoes, ha testes de snapshot com 3 fixtures:

```
tests/
  fixtures/
    go-microservice/       <- Go + Dockerfile + k8s/ + Echo + gRPC
    go-modular/            <- Go + internal/ com 4 subdirs + Gin + golangci-lint
    node-monorepo/         <- Node + pnpm-workspace.yaml + apps/ + packages/
  snapshots/
    go-microservice.agents.md
    go-modular.agents.md
    node-monorepo.agents.md
  test-generate-governance.sh
```

Executar os testes:

```bash
# Verificar se o output atual bate com o snapshot salvo
bash tests/test-generate-governance.sh

# Atualizar snapshots apos mudanca intencional no gerador
bash tests/test-generate-governance.sh --update
```

Output:

```text
Arquitetura detectada: microservico
Stack detectada: Go
Frameworks detectados: Echo,gRPC
PASS  go-microservice

Arquitetura detectada: monolito modular
Stack detectada: Go
Frameworks detectados: Gin
PASS  go-modular

Arquitetura detectada: monorepo
Stack detectada: Node.js
Frameworks detectados: nenhum framework dominante identificado
PASS  node-monorepo

Resultado: 3 passed, 0 failed
```

**Motivador**: o `generate-governance.sh` tem ~430 linhas de logica de deteccao e geracao. Sem testes, uma regressao afeta todos os projetos instalados. Os fixtures cobrem os tres cenarios principais e validam output completo.

---

## Economia de Tokens

O projeto usa carregamento condicional de referencias para minimizar consumo de contexto. Cada `SKILL.md` lista exatamente quais referencias carregar e em que condicao.

### Referencias fracionadas

As duas maiores referencias Go foram divididas em arquivos menores com gatilhos mais estreitos:

| Antes | Depois | Gatilho |
|-------|--------|---------|
| `design-patterns.md` (304L) | `patterns-creational.md` | Factory functions, functional options, builders |
| | `patterns-structural.md` | Adapters, decorators/middleware, facades |
| | `patterns-behavioral.md` | Strategy, chain of responsibility, observer, state machine |
| `implementation-examples.md` (344L) | `examples-domain-flow.md` | Fluxo end-to-end (dominio, service, handler, teste) |
| | `examples-testing.md` | Fuzz test, table-driven test, construtor com invariantes |
| | `examples-infrastructure.md` | Graceful shutdown, paginacao cursor-based, versionamento de API |

**Motivador**: os dois arquivos antigos representavam 38% do corpus de referencias Go (~2.600 tokens). Com gatilhos genericos ("quando um esqueleto destravar a implementacao"), eram carregados por falso positivo. A divisao permite carregar apenas o fragmento necessario.

**Estimativa de economia**: em uma tarefa de CRUD simples, o agente carrega `patterns-creational.md` (~75L) em vez do `design-patterns.md` inteiro (304L) — reducao de ~75% em tokens para esse tipo de referencia.

### Delegacao de referencias no AGENTS.md

Em vez de listar individualmente cada referencia (~30 linhas duplicadas entre `AGENTS.md` e cada `SKILL.md`), o `AGENTS.md` agora delega:

```
Cada skill lista suas proprias referencias em references/ com gatilhos de carregamento
no respectivo SKILL.md. Consultar o SKILL.md da skill ativa para saber quais
referencias carregar e em que condicao.
```

**Motivador**: elimina manutencao duplicada (adicionar/remover referencia exigia editar 2+ arquivos) e reduz ~30 linhas injetadas no contexto.

### Modo review-lite no OC skill

Quando o `object-calisthenics-go` opera em modo `review` (sem edicao), a cadeia de carregamento e reduzida:

| Modo | O que carrega | Linhas estimadas |
|------|---------------|-----------------|
| `review` | `AGENTS.md` + `rules.md` + `evaluation-guide.md` | ~215 |
| `execution` | `AGENTS.md` + `agent-governance/SKILL.md` + `go-implementation/SKILL.md` + refs | ~415 |

**Motivador**: carregar `agent-governance` + `go-implementation` inteiros para uma avaliacao sem edicao desperdicava ~600-800 tokens. O modo review-lite carrega apenas o que e necessario para emitir um parecer.

---

## Exemplos de Prompts

O fluxo completo de desenvolvimento segue a ordem: **PRD > Especificacao Tecnica > Tarefas > Execucao > Revisao**.

### Criar PRD

**Claude Code**

```
/create-prd Implementar sistema de notificacoes push para o app mobile
```

ou via subagente:

```
@prd-writer Criar PRD para sistema de notificacoes push com suporte a iOS e Android
```

**GitHub Copilot CLI**

```
@prd-writer Criar PRD para sistema de notificacoes push com suporte a iOS e Android
```

**Gemini CLI**

```
/create-prd Implementar sistema de notificacoes push para o app mobile
```

**Codex CLI**

```
Leia .agents/skills/create-prd/SKILL.md e gere um PRD para sistema de notificacoes push
```

---

### Criar Especificacao Tecnica

**Claude Code**

```
/create-technical-specification Gerar techspec baseado no PRD docs/prd-notificacoes.md
```

ou via subagente:

```
@technical-specification-writer Criar techspec para o PRD docs/prd-notificacoes.md
```

**GitHub Copilot CLI**

```
@technical-specification-writer Criar techspec para o PRD docs/prd-notificacoes.md
```

**Gemini CLI**

```
/create-technical-specification Gerar techspec baseado no PRD docs/prd-notificacoes.md
```

**Codex CLI**

```
Leia .agents/skills/create-technical-specification/SKILL.md e gere a techspec para docs/prd-notificacoes.md
```

---

### Criar Tarefas

**Claude Code**

```
/create-tasks Gerar tarefas a partir de docs/prd-notificacoes.md e docs/techspec-notificacoes.md
```

ou via subagente:

```
@task-planner Decompor em tarefas o PRD docs/prd-notificacoes.md com techspec docs/techspec-notificacoes.md
```

**GitHub Copilot CLI**

```
@task-planner Decompor em tarefas o PRD docs/prd-notificacoes.md com techspec docs/techspec-notificacoes.md
```

**Gemini CLI**

```
/create-tasks Gerar tarefas a partir de docs/prd-notificacoes.md e docs/techspec-notificacoes.md
```

**Codex CLI**

```
Leia .agents/skills/create-tasks/SKILL.md e gere tarefas para docs/prd-notificacoes.md e docs/techspec-notificacoes.md
```

---

### Executar Tarefa

**Claude Code**

```
/execute-task Implementar a tarefa docs/tasks/task-001.md
```

ou via subagente:

```
@task-executor Executar docs/tasks/task-001.md
```

**GitHub Copilot CLI**

```
@task-executor Executar docs/tasks/task-001.md
```

**Gemini CLI**

```
/execute-task Implementar a tarefa docs/tasks/task-001.md
```

**Codex CLI**

```
Leia .agents/skills/execute-task/SKILL.md e implemente docs/tasks/task-001.md
```

---

### Object Calisthenics Go

**Codex CLI**

```
Leia .agents/skills/object-calisthenics-go/SKILL.md e revise internal/payment/service.go propondo a menor refatoracao segura
```

```
Leia .agents/skills/object-calisthenics-go/SKILL.md e refatore pkg/order/order.go para reduzir branching e melhorar encapsulamento sem quebrar contratos
```

---

### Refatorar

**Claude Code**

```
/refactor Extrair duplicacao do handler de pagamentos em internal/payment/handler.go
```

ou via subagente:

```
@refactorer Refatorar internal/payment/handler.go extraindo duplicacao
```

**GitHub Copilot CLI**

```
@refactorer Refatorar internal/payment/handler.go extraindo duplicacao
```

**Gemini CLI**

```
/refactor Extrair duplicacao do handler de pagamentos em internal/payment/handler.go
```

**Codex CLI**

```
Leia .agents/skills/refactor/SKILL.md e refatore internal/payment/handler.go extraindo duplicacao
```

---

### Revisar

**Claude Code**

```
/review Revisar as mudancas da branch feat/notificacoes
```

ou via subagente:

```
@reviewer Revisar diff da branch feat/notificacoes contra main
```

**GitHub Copilot CLI**

```
@reviewer Revisar diff da branch feat/notificacoes contra main
```

**Gemini CLI**

```
/review Revisar as mudancas da branch feat/notificacoes
```

**Codex CLI**

```
Leia .agents/skills/review/SKILL.md e revise o diff da branch feat/notificacoes contra main
```

---

### Corrigir Bugs

**Claude Code**

```
/bugfix Corrigir os bugs listados em tasks/prd-cache-catalogo/bugs.md
```

**Gemini CLI**

```
/bugfix Corrigir os bugs listados em tasks/prd-cache-catalogo/bugs.md
```

**Codex CLI**

```
Leia .agents/skills/bugfix/SKILL.md e corrija os bugs de tasks/prd-cache-catalogo/bugs.md
```

---

### Fluxo Completo de Desenvolvimento

Exemplo end-to-end usando Claude Code:

```bash
# 1. Criar o PRD
/create-prd Implementar cache distribuido com Redis para o servico de catalogo

# 2. Gerar a especificacao tecnica
/create-technical-specification Gerar techspec baseado no PRD docs/prd-cache-catalogo.md

# 3. Decompor em tarefas
/create-tasks Gerar tarefas a partir de docs/prd-cache-catalogo.md e docs/techspec-cache-catalogo.md

# 4. Executar cada tarefa
/execute-task Implementar docs/tasks/task-001.md
/execute-task Implementar docs/tasks/task-002.md

# 5. Revisar antes do merge
/review Revisar as mudancas da branch feat/cache-catalogo
```

O mesmo fluxo no Gemini CLI segue a mesma sequencia com os comandos `/create-prd`, `/create-technical-specification`, `/create-tasks`, `/execute-task` e `/review`.

No Copilot CLI, use os agentes `@prd-writer`, `@technical-specification-writer`, `@task-planner`, `@task-executor` e `@reviewer`.

No Codex CLI, prefixe cada passo com a leitura da SKILL.md correspondente em `.agents/skills/`.
