# rules

Base minima de regras compartilhadas para uso com agentes de IA em diferentes CLIs.

O instalador agora gera `AGENTS.md` e os adaptadores de forma contextual a partir da estrutura real do projeto alvo, em vez de apenas copiar arquivos estaticos.

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

## Instalacao

Uso padrao:

```bash
bash install.sh /caminho/do/projeto
```

Exemplo em projeto novo:

```bash
mkdir -p /caminho/projetos/meu-servico
cd /caminho/projetos/meu-servico

bash /Users/jailtonjunior/Git/rules/install.sh .
```

Quando o instalador perguntar pelas ferramentas, voce pode selecionar, por exemplo:

```text
Digite os numeros separados por espaco (exemplo: 1 3) ou A para todas: A
```

Esse fluxo e util para preparar um repositorio novo antes de iniciar PRD, tech spec, tarefas e execucao.

Exemplo em projeto existente:

```bash
cd /caminho/projetos/sistema-legado

bash /Users/jailtonjunior/Git/rules/install.sh .
```

Se quiser instalar apenas para Codex e Claude Code no projeto atual:

```text
Digite os numeros separados por espaco (exemplo: 1 3) ou A para todas: 1 3
```

Esse fluxo preserva o projeto existente e adiciona apenas os arquivos e adaptadores de governanca para as ferramentas selecionadas.

Opcoes uteis:

- `LINK_MODE=symlink`: modo padrao, mais economico para manter uma unica fonte de verdade.
- `LINK_MODE=copy`: modo mais portavel para ambientes com restricao a symlink.
- `GENERATE_CONTEXTUAL_GOVERNANCE=1`: modo padrao; detecta arquitetura, stack e comandos de validacao para gerar `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` e `.github/copilot-instructions.md`.
- `GENERATE_CONTEXTUAL_GOVERNANCE=0`: fallback para copiar os arquivos canonicos sem personalizacao.

Exemplo portavel:

```bash
LINK_MODE=copy bash install.sh /caminho/do/projeto
```

Exemplo portavel em um projeto existente:

```bash
cd /caminho/projetos/api-existente

LINK_MODE=copy bash /Users/jailtonjunior/Git/rules/install.sh .
```

---

## Exemplos de Prompts

Abaixo estao exemplos de como invocar cada habilidade nas diferentes plataformas. O fluxo completo de desenvolvimento segue a ordem: **PRD > Especificacao Tecnica > Tarefas > Execucao > Revisao**.

---

### Criar PRD

Gera um documento de requisitos de produto a partir de uma descricao de funcionalidade.

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

Gera especificacao tecnica e ADRs a partir de um PRD aprovado.

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

Decompoe PRD e techspec aprovados em tarefas ordenadas de implementacao.

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

Implementa uma tarefa aprovada com codificacao, testes e captura de evidencias.

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

Aplica heuristicas de object calisthenics de forma incremental e idiomatica em codigo Go, com foco em revisao e refatoracao segura.

**Codex CLI**

```
Leia .agents/skills/object-calisthenics-go/SKILL.md e revise internal/payment/service.go propondo a menor refatoracao segura
```

```
Leia .agents/skills/object-calisthenics-go/SKILL.md e refatore pkg/order/order.go para reduzir branching e melhorar encapsulamento sem quebrar contratos
```

---

### Refatorar

Planeja ou executa refatoracoes seguras preservando comportamento.

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

Revisa um diff quanto a correcao, seguranca, regressoes e testes faltantes.

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
