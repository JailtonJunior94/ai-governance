# ai-governance

Governança reutilizável para agentes de IA em repositórios reais, com uma base canônica de skills em `.agents/skills/`, adaptadores por ferramenta e geração contextual de instruções para o projeto-alvo.

O repositório existe para evitar duplicação de processo entre Claude Code, Codex, Gemini CLI e GitHub Copilot, mantendo uma única fonte de verdade para regras operacionais, referências e fluxos de trabalho.

> Last reviewed: 2026-04-19

## Para quem é

Este README é voltado para quem quer:

- instalar governança de IA em outro repositório;
- entender o que `install.sh` e `upgrade.sh` realmente fazem;
- evoluir as skills e os adaptadores deste projeto sem quebrar o fluxo existente.

## O que o projeto entrega

### Base canônica

Toda a lógica procedural fica em `.agents/skills/`. Hoje o repositório contém:

- skills de processo: `agent-governance`, `analyze-project`, `bugfix`, `create-prd`, `create-technical-specification`, `create-tasks`, `execute-task`, `refactor`, `review`;
- skills de linguagem: `go-implementation`, `node-implementation`, `python-implementation`;
- skill adicional de design incremental para Go: `object-calisthenics-go`.

### Adaptadores por ferramenta

Os scripts do projeto geram ou instalam integrações para:

| Ferramenta | Arquivos gerados ou instalados |
|------------|--------------------------------|
| Claude Code | `CLAUDE.md`, `.claude/skills/`, `.claude/agents/`, `.claude/rules/`, `.claude/scripts/`, `.claude/hooks/` |
| Gemini CLI | `GEMINI.md`, `.gemini/commands/` |
| Codex | `.codex/config.toml` |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/skills/`, `.github/agents/` |

Os adaptadores não redefinem o processo. Eles apontam para `.agents/skills/`, que continua sendo a fonte de verdade.

### Geração contextual

Quando `GENERATE_CONTEXTUAL_GOVERNANCE=1`:

- `install.sh` chama `.agents/skills/analyze-project/scripts/generate-governance.sh`;
- o gerador tenta classificar a arquitetura do projeto-alvo;
- o gerador detecta stack principal, frameworks e sinais de toolchain;
- `AGENTS.md` e arquivos auxiliares passam a refletir o contexto do repositório instalado.

## Estrutura do repositório

| Caminho | Papel |
|--------|-------|
| `.agents/skills/` | skills canônicas, assets, references e scripts de suporte |
| `.claude/` | adaptadores e arquivos base para Claude Code |
| `.codex/` | configuração base do Codex para este repositório |
| `.gemini/` | comandos base para Gemini CLI |
| `.github/` | adaptadores e workflow de CI |
| `scripts/` | geração de adaptadores, utilitários e helpers compartilhados |
| `tests/` | testes end-to-end, validação de heurísticas e snapshots |
| `install.sh` | instalação da governança em projeto-alvo |
| `upgrade.sh` | verificação e atualização de skills instaladas em modo `copy` |
| `VERSION` | versão do pacote de governança |

## Instalação

### Pré-requisitos

Para instalar em outro projeto, o código exige:

- `bash`;
- diretório-alvo já existente;
- permissão de escrita no diretório-alvo.

Para rodar a suíte completa deste repositório, `python3` também é usado em scripts auxiliares e no CI.

### Fluxo básico

```bash
bash install.sh /caminho/do/projeto
```

No modo interativo, o script pergunta:

1. quais ferramentas instalar: `claude`, `gemini`, `codex`, `copilot` ou todas;
2. quais linguagens devem receber skills de implementação: `go`, `node`, `python` ou todas.

Se nenhuma linguagem for escolhida, apenas as skills processuais são instaladas.

### Modo não interativo

```bash
# Claude + Gemini com Go e Python
bash install.sh --tools claude,gemini --langs go,python /caminho/do/projeto

# todas as ferramentas e todas as linguagens
bash install.sh --tools all --langs all /caminho/do/projeto

# apenas Codex e Copilot, sem skills de linguagem
bash install.sh --tools codex,copilot /caminho/do/projeto
```

Valores aceitos:

- `--tools`: `claude`, `gemini`, `codex`, `copilot`, `all`
- `--langs`: `go`, `node`, `python`, `all`
- `--ref`: qualquer ref resolvível por `git rev-parse`, como tag, branch ou SHA

### Dry run

```bash
bash install.sh --dry-run /caminho/do/projeto
```

Esse modo mostra o que seria criado sem alterar arquivos.

### Fonte explícita por tag ou ref

Quando for importante fixar exatamente qual versão publicada está sendo consumida, use `--ref` ou `AI_GOVERNANCE_REF`.

```bash
# instalar a partir de um tag explícito
bash install.sh --ref v1.0.0 /caminho/do/projeto

# equivalente via ambiente
AI_GOVERNANCE_REF=v1.0.0 bash install.sh --tools codex --langs go /caminho/do/projeto
```

Contrato operacional:

- sem `--ref`, `install.sh` usa o checkout atual do repositório onde o script está sendo executado;
- com `--ref`, o script materializa um snapshot limpo daquela árvore Git e registra a ref escolhida nos logs;
- quando `--ref` é usado, `LINK_MODE=symlink` é ajustado automaticamente para `copy`, evitando symlinks para diretórios temporários;
- refs inválidas falham com erro explícito antes de qualquer escrita no projeto-alvo.

### Modos de instalação e variáveis

| Variável | Default | Efeito validado no código |
|----------|---------|---------------------------|
| `LINK_MODE` | `symlink` | usa symlinks para as skills canônicas; com `copy`, instala um snapshot local |
| `GENERATE_CONTEXTUAL_GOVERNANCE` | `1` | com `1`, gera governança contextual; com `0`, copia os arquivos base sem personalização |
| `CODEX_SKILL_PROFILE` | `full` | controla o conjunto de skills no `.codex/config.toml`; `full` inclui skills de planejamento; qualquer outro valor cai no perfil operacional enxuto |
| `DETECT_TOOLCHAIN_MAX_DEPTH` | `4` | profundidade máxima usada na busca de manifests para detecção de toolchain |
| `DETECT_TOOLCHAIN_FOCUS_PATHS` | vazio | prioriza paths afetados ao detectar o workspace ou package mais relevante |

Exemplos:

```bash
# instalação padrão com symlink
bash install.sh /caminho/do/projeto

# instalação portável com cópia
LINK_MODE=copy bash install.sh /caminho/do/projeto

# sem geração contextual
GENERATE_CONTEXTUAL_GOVERNANCE=0 bash install.sh /caminho/do/projeto

# perfil operacional enxuto para Codex
CODEX_SKILL_PROFILE=lean bash install.sh --tools codex --langs all /caminho/do/projeto

# perfil completo para Codex
CODEX_SKILL_PROFILE=full bash install.sh --tools codex --langs all /caminho/do/projeto
```

## O que é instalado no projeto-alvo

Sempre:

- `AGENTS.md`
- `.agents/skills/` com as skills selecionadas

Quando a ferramenta correspondente é selecionada:

- Claude Code: `CLAUDE.md`, `.claude/skills/`, `.claude/agents/`, `.claude/rules/`, `.claude/scripts/`, `.claude/hooks/`
- Gemini CLI: `GEMINI.md`, `.gemini/commands/`
- Codex: `.codex/config.toml`
- GitHub Copilot: `.github/copilot-instructions.md`, `.github/skills/`, `.github/agents/`

Quando `LINK_MODE=copy`, as skills são copiadas para o projeto-alvo. Quando `LINK_MODE=symlink`, o projeto-alvo aponta para este repositório.

## Como o projeto funciona

### 1. Fonte única de verdade

As skills canônicas vivem em `.agents/skills/`. Adaptadores de ferramenta são somente wrappers finos.

### 2. Perfis do Codex

Para projetos-alvo instalados com `install.sh`, o default em `scripts/lib/codex-config.sh` é `full`, então o `.codex/config.toml` gerado inclui:

- `agent-governance`
- `analyze-project`
- `create-prd`
- `create-technical-specification`
- `create-tasks`
- `execute-task`
- `refactor`
- `review`
- `bugfix`

Quando `CODEX_SKILL_PROFILE` recebe qualquer valor diferente de `full`, o gerador cai no perfil operacional enxuto, que habilita:

- `agent-governance`
- `execute-task`
- `refactor`
- `review`
- `bugfix`

O arquivo deste próprio repositório em `.codex/config.toml` usa esse perfil enxuto para reduzir contexto local. Em projetos-alvo, as skills de planejamento entram por default com `full` ou podem ser retiradas definindo um perfil enxuto explicitamente.

### 3. Geração de adaptadores

Os scripts em `scripts/` geram adaptadores a partir das skills instaladas:

- `scripts/generate-adapters.sh` gera wrappers de Claude e GitHub e delega a geração do Gemini;
- `scripts/generate-gemini-commands.sh` cria `.gemini/commands/*.toml` a partir do frontmatter e dos assets de cada skill.

### 4. Geração contextual

O gerador contextual usa:

- `.agents/skills/agent-governance/scripts/detect-architecture.sh`
- `.agents/skills/agent-governance/scripts/detect-toolchain.sh`
- `scripts/lib/find-manifests.sh`

Hoje a detecção de arquitetura cobre:

- `monorepo`
- `monolito modular`
- `microservico`
- `monolito` como fallback conservador

Para stack principal, o gerador tenta inferir sinais de:

- Go
- Node.js
- Python
- Java/Kotlin
- Rust
- C#/.NET

Para frameworks, há detecção explícita para alguns casos em manifests encontrados:

- Go: `Gin`, `Echo`, `Fiber`, `gRPC`, `Connect`
- Node.js: `Express`, `NestJS`, `Fastify`, `Next.js`, `Hono`
- Python: `FastAPI`, `Django`, `Flask`

## Automação de release SemVer

O script `scripts/semver-next.sh` calcula a decisão de release a partir do último tag SemVer alcançável e do `VERSION` atual. O contrato de saída é estável em `key=value` para consumo por workflows e scripts.

```bash
bash scripts/semver-next.sh
```

Saída esperada:

- `action=bootstrap|release|no_release`
- `bootstrap_required=true|false`
- `release_required=true|false`
- `last_tag=<tag ou vazio>`
- `base_version=<semver sem prefixo v>`
- `bump=major|minor|patch|no_release`
- `target_version=<semver sem prefixo v>`
- `commit_range=<range analisado>`

Regras operacionais atuais:

- sem tags históricas, o script retorna `action=bootstrap` e preserva `target_version` igual ao baseline de `VERSION`;
- `feat` promove `minor`, `fix` promove `patch`, `!` ou `BREAKING CHANGE:` promovem `major`;
- commits não classificáveis por si sós resultam em `no_release`.

### Dry-run antes da ativação real

O workflow `.github/workflows/release-dry-run.yml` existe para validar a decisão de release sem criar commit, tag ou push.

Fluxo recomendado:

```bash
gh workflow run release-dry-run.yml --ref <branch-controlada>
```

Checklist mínimo antes de habilitar ou alterar o fluxo real:

- confirmar que o dry-run mostra `action`, `bump` e `target_version` coerentes;
- revisar o diff proposto para `VERSION` e `CHANGELOG.md`;
- validar que cenários `no_release` não materializam arquivos;
- registrar a aprovação desse dry-run na PR ou no relatório operacional da mudança.

### Workflow real em `main`

O workflow `.github/workflows/release.yml` roda somente em `push` para `main` e usa `concurrency` por ref para serializar execuções. O fluxo:

- faz checkout com histórico completo e revalida tags e `origin/main`;
- calcula a decisão com `scripts/semver-next.sh`;
- trata rerun com tag já existente como `no-op`;
- cria commit automatizado apenas para releases reais com mensagem `chore(release): vX.Y.Z [skip ci]`;
- cria tag anotada `vX.Y.Z`;
- falha explicitamente se encontrar divergência entre commit de release, `VERSION`, `CHANGELOG.md` e o tag esperado.

O marcador `[skip ci]` é intencional: ele evita loop do próprio workflow de release e também impede que o commit automatizado dispare novamente a matriz de testes.

### Bootstrap do primeiro tag

Este repositório parte do baseline materializado em `VERSION=1.0.0` e da seção `## [1.0.0] - 2025-05-01` em `CHANGELOG.md`. O bootstrap deve acontecer exatamente uma vez, criando apenas o tag anotado `v1.0.0`.

Procedimento operacional recomendado:

1. Executar o dry-run em uma branch controlada e registrar a evidência.
2. Confirmar que `VERSION` continua em `1.0.0` e que o `CHANGELOG.md` preserva a seção histórica `1.0.0`.
3. Publicar o workflow real.
4. Fazer um `push` controlado em `main` sem novos commits elegíveis de release.
5. Verificar que o workflow criou apenas `v1.0.0` e não criou commit automatizado.

Se o tag `v1.0.0` já existir, qualquer rerun deve terminar como `no-op`.

### Rerun e recuperação operacional

Rerun esperado:

- se o tag alvo já existir, o workflow encerra em `no-op`;
- se o intervalo contiver apenas `docs`, `chore`, `test`, `ci`, `build` ou `refactor` sem `!`, não há release;
- se o workflow encontrar um commit de release já publicado em `origin/main` sem o tag correspondente, ele falha explicitamente para evitar duplicidade silenciosa.

Rollback e recuperação:

1. Se o workflow falhar antes de qualquer `push`, corrigir a causa e rerodar.
2. Se houver commit de release em `main` sem o tag correspondente, não force novo release automático; recrie o tag faltante manualmente ou reverta o commit e só então rerode.
3. Se o tag tiver sido criado com versão incorreta, remover o tag remoto e local, restaurar `VERSION` e `CHANGELOG.md` para o estado consistente anterior e disparar um novo `push` controlado.
4. Após qualquer intervenção manual, executar novamente o dry-run antes de reabilitar o fluxo normal.

## Atualização de skills

Use `upgrade.sh` quando a instalação tiver sido feita em modo `copy`.

### Verificar sem alterar

```bash
bash upgrade.sh --check /caminho/do/projeto
```

### Atualizar

```bash
bash upgrade.sh /caminho/do/projeto
```

### Atualizar contra uma ref explícita

```bash
# verificar comparando contra um tag específico
bash upgrade.sh --check --ref v1.0.0 /caminho/do/projeto

# atualizar usando um SHA ou branch específicos
AI_GOVERNANCE_REF=v1.0.0 bash upgrade.sh /caminho/do/projeto
```

Sem `--ref`, o `upgrade.sh` compara contra o checkout atual do repositório fonte. Com `--ref`, a comparação e a cópia passam a usar exatamente o snapshot daquele tag, branch ou commit, e a fonte resolvida fica visível no output.

O script compara:

- `version` no frontmatter de cada `SKILL.md`;
- checksum do conteúdo do `SKILL.md`;
- checksum e diferenças do diretório `references/`, quando existir.

Se houver atualização real e o projeto não estiver usando symlink, o script também pode:

- re-gerar adaptadores de Claude, GitHub e Gemini;
- sincronizar `.claude/rules/` e `.claude/scripts/`;
- re-gerar `.codex/config.toml` com base nas skills instaladas;
- re-gerar a governança contextual quando `AGENTS.md` existir no projeto-alvo.

### Filtrar por linguagem

```bash
# verificar apenas skills de Go
bash upgrade.sh --check --langs go /caminho/do/projeto

# atualizar apenas skills de Node.js
bash upgrade.sh --langs node /caminho/do/projeto
```

Valores aceitos em `--langs`: `go`, `node`, `python`.

## Desenvolvimento

### Testes disponíveis

Os scripts de teste presentes no repositório hoje são:

```bash
bash tests/test-generate-governance.sh
bash tests/test-copilot.sh
bash tests/test-e2e.sh
bash tests/test-governance-lint.sh
bash tests/test-install.sh
bash tests/test-upgrade.sh
bash tests/test-scripts.sh
bash tests/test-context-metrics.sh
bash tests/test-adapter-parity.sh
bash tests/test-skill-references.sh
bash tests/test-detect-architecture.sh
bash tests/test-detect-toolchain.sh
bash tests/test-skill-frontmatter.sh
```

Para atualização intencional de snapshots do gerador contextual:

```bash
bash tests/test-generate-governance.sh --update
```

### CI

O workflow em `.github/workflows/test.yml` executa essas suítes em:

- `ubuntu-24.04`
- `macos-15`

### Fixtures e snapshots

Os testes usam fixtures em `tests/fixtures/` para validar diferentes cenários, incluindo:

- `go-microservice`
- `go-modular`
- `node-monorepo`
- `python-fastapi`
- `python-monorepo`
- `polyglot-monorepo`

Os snapshots esperados do gerador ficam em `tests/snapshots/`.

## Matriz de Enforcement por Ferramenta

| Capacidade | Claude Code | Gemini CLI | Codex | Copilot |
|---|---|---|---|---|
| Auto-load de instrucoes (`CLAUDE.md`, etc.) | Sim | Nao | Sim (`AGENTS.md`) | Sim |
| Hooks de pre/pos-edicao | Sim (`PreToolUse`, `PostToolUse`) | Nao | Nao | Nao |
| Agents delegadores | Sim (`.claude/agents/`) | Nao | Nao | Sim (`.github/agents/`) |
| Commands/Skills como slash commands | Sim (`.claude/skills/`) | Sim (`@commands`) | Parcial (`[[skills.config]]`) | Nao |
| Enforcement ativo de governanca | Sim (hooks bloqueantes) | Nao (procedural) | Nao (procedural) | Nao (procedural) |
| Validacao de bug schema inter-skill | Sim (`validate-bug-schema.sh`) | Manual | Manual | Manual |
| Compact profile para contexto menor | N/A | N/A | Sim (auto-detect) | N/A |

**Implicacoes praticas**:

- **Claude Code**: enforcement mais completo. Hooks alertam ou bloqueiam edicoes em arquivos de governanca e lembram o contrato de carga base antes de editar codigo. Skills e agents sao invocados automaticamente.
- **Gemini CLI**: compliance depende de o modelo seguir as instrucoes procedurais do `GEMINI.md` e dos commands TOML. Nao ha enforcement ativo. Recomenda-se usar `@<command>` para invocar skills e seguir as etapas manualmente.
- **Codex**: le `AGENTS.md` automaticamente como instrucao de sessao. Skills sao registradas em `config.toml` mas a invocacao depende do modelo. Sem hooks ou agents.
- **Copilot**: agents em `.github/agents/` sao reconhecidos nativamente. `copilot-instructions.md` e carregado automaticamente. Sem hooks de enforcement.

Para ferramentas sem enforcement ativo, a governanca funciona como guia procedural: o modelo e instruido a ler `AGENTS.md` e seguir as etapas, mas nao ha mecanismo que impeca desvios.

## Limitacoes e observacoes

- `install.sh` e `upgrade.sh` rejeitam o proprio repositorio `ai-governance` como alvo;
- o diretorio-alvo precisa existir antes da execucao;
- a geracao contextual depende exclusivamente dos sinais encontrados localmente;
- quando nao ha sinal forte suficiente, o gerador usa fallback conservador;
- nao ha arquivo `LICENSE` nem `CONTRIBUTING.md` neste repositorio no estado atual.

## Fluxo recomendado

```bash
# 1. instalar a governança
bash install.sh /caminho/do/projeto

# 2. revisar o que foi gerado
ls -la /caminho/do/projeto

# 3. em instalações por cópia, monitorar desatualização
bash upgrade.sh --check /caminho/do/projeto
```

## Como usar para desenvolver uma feature

Esta seção descreve o fluxo completo de uso da governança para levar uma feature do pedido inicial até a entrega com evidências. O objetivo não é inventar um processo paralelo, e sim operar exatamente em cima das skills e artefatos canônicos deste repositório.

### Quando usar este fluxo

Use este pipeline quando a mudança ainda não estiver suficientemente definida e você quiser rastreabilidade entre:

- objetivo de produto;
- desenho técnico;
- decomposição em tarefas;
- implementação;
- validação;
- revisão;
- evidências de execução.

Se a mudança for um bug isolado já bem reproduzido, o fluxo pode começar direto em `bugfix` em vez de passar por PRD e tech spec.

### Pré-requisitos no projeto-alvo

1. Instale a governança no repositório alvo.
2. Entre no diretório do projeto.
3. Confirme que `AGENTS.md` e `.agents/skills/` existem.
4. Se for usar Claude, Gemini, Codex ou Copilot, confirme também os adaptadores da ferramenta escolhida.

Exemplo:

```bash
bash install.sh --tools all --langs all /caminho/do/projeto
cd /caminho/do/projeto

ls -la
ls -la .agents/skills
ls -la .claude/agents
ls -la .gemini/commands
ls -la .github/agents
sed -n '1,220p' AGENTS.md
```

Estrutura mínima esperada após a instalação:

- `AGENTS.md`
- `.agents/skills/`
- `tasks/` será criado conforme as features forem sendo planejadas

### Visão geral do pipeline

Para uma feature nova, a sequência recomendada é:

1. gerar o PRD;
2. gerar a especificação técnica e ADRs;
3. propor o plano de tarefas;
4. aprovar o plano;
5. gerar `tasks.md` e os arquivos detalhados de tarefa;
6. executar uma tarefa elegível;
7. validar;
8. revisar;
9. corrigir bugs encontrados na revisão, quando necessário;
10. registrar evidências e concluir.

### Artefatos gerados ao longo do fluxo

Todos os artefatos da feature vivem em:

```text
tasks/prd-<slug-da-feature>/
```

Arquivos esperados:

- `prd.md`
- `techspec.md`
- `adr-001-<slug>.md`, `adr-002-<slug>.md`, quando houver decisões materiais
- `tasks.md`
- um arquivo por tarefa, por exemplo `1.0-<titulo>.md` ou outro nome estável adotado no projeto-alvo
- `[num]_execution_report.md` para cada tarefa executada
- `bugfix_report.md` quando houver remediação por `bugfix`

### Etapa 1: gerar o PRD

Objetivo: transformar a ideia da feature em um documento de produto claro, com objetivos, escopo, fora de escopo, restrições e requisitos funcionais numerados.

Saída esperada:

```text
tasks/prd-<slug-da-feature>/prd.md
```

O que a skill `create-prd` exige:

- foco em produto, não em implementação;
- no máximo duas rodadas de esclarecimento;
- retorno `done` quando o PRD estiver completo;
- retorno `needs_input` quando faltarem dados objetivos.

Exemplo de solicitação ao agente:

```text
Use create-prd para a feature "checkout com cupons por segmento". Gere ou atualize o PRD em tasks/prd-checkout-com-cupons-por-segmento/prd.md. Se faltar contexto, faça no máximo duas rodadas de perguntas e retorne needs_input.
```

Se quiser verificar o resultado no shell:

```bash
ls -la tasks
ls -la tasks/prd-checkout-com-cupons-por-segmento
sed -n '1,260p' tasks/prd-checkout-com-cupons-por-segmento/prd.md
```

### Etapa 2: gerar a especificação técnica

Objetivo: converter o PRD aprovado em um plano técnico implementável, com arquitetura, interfaces, riscos, testes e ADRs.

Saídas esperadas:

- `tasks/prd-<slug-da-feature>/techspec.md`
- `tasks/prd-<slug-da-feature>/adr-*.md`, quando houver decisões materiais

O que a skill `create-technical-specification` exige:

- PRD existente;
- exploração do codebase relevante antes de decidir;
- perguntas técnicas apenas quando houver bloqueio real;
- mapeamento de requisito para decisão e teste;
- documentação explícita de trade-offs e riscos.

Exemplo de solicitação ao agente:

```text
Use create-technical-specification para tasks/prd-checkout-com-cupons-por-segmento/prd.md. Explore apenas os caminhos de código relevantes, gere tasks/prd-checkout-com-cupons-por-segmento/techspec.md e crie ADRs separadas para decisões materiais.
```

Comandos úteis para inspeção:

```bash
sed -n '1,260p' tasks/prd-checkout-com-cupons-por-segmento/techspec.md
rg -n "^#|^##|^###" tasks/prd-checkout-com-cupons-por-segmento
ls -la tasks/prd-checkout-com-cupons-por-segmento
```

### Etapa 3: propor e aprovar o plano de tarefas

Objetivo: decompor a implementação em fatias verificáveis e ordenadas.

A skill `create-tasks` tem duas fases:

1. primeiro propõe um plano de alto nível com no máximo 10 tarefas;
2. só depois da aprovação gera `tasks.md` e os arquivos detalhados.

Isso é importante porque a própria skill foi desenhada para parar com `needs_input` se a aprovação ainda não estiver disponível.

Exemplo de solicitação ao agente:

```text
Use create-tasks para tasks/prd-checkout-com-cupons-por-segmento/prd.md e tasks/prd-checkout-com-cupons-por-segmento/techspec.md. Primeiro proponha apenas o plano de alto nível para aprovação. Não gere os arquivos finais ainda.
```

Depois de aprovar o plano:

```text
Plano aprovado. Gere tasks/prd-checkout-com-cupons-por-segmento/tasks.md e os arquivos detalhados de tarefa, com critérios de aceitação, testes e dependências explícitas.
```

Comandos úteis:

```bash
sed -n '1,260p' tasks/prd-checkout-com-cupons-por-segmento/tasks.md
find tasks/prd-checkout-com-cupons-por-segmento -maxdepth 1 -type f | sort
```

Estados canônicos que devem aparecer em `tasks.md`:

- `pending`
- `in_progress`
- `needs_input`
- `blocked`
- `failed`
- `done`

### Etapa 4: executar uma tarefa elegível

Objetivo: implementar uma tarefa aprovada com testes, validação, revisão e evidência.

Pré-condições da skill `execute-task`:

- `prd.md`, `techspec.md` e `tasks.md` presentes;
- arquivo de tarefa presente;
- dependências marcadas como `done`;
- contexto técnico da linguagem carregado sob demanda.

Exemplo de solicitação ao agente:

```text
Use execute-task para a primeira tarefa elegível em tasks/prd-checkout-com-cupons-por-segmento/. Leia prd.md, techspec.md, tasks.md e o arquivo da tarefa. Execute a implementação, rode validação proporcional, faça a revisão e retorne o caminho do relatório de execução com o estado final.
```

Se quiser apontar uma tarefa específica:

```text
Use execute-task para a tarefa 2.0 de tasks/prd-checkout-com-cupons-por-segmento/. Não escolha outra tarefa. Siga os critérios de aceitação e gere o relatório final.
```

Durante a execução, a skill deve:

- implementar código e testes juntos;
- usar `task test`, `task lint`, `task fmt` quando existirem;
- caso contrário, usar `make test`, `make lint`, `make fmt` ou o equivalente documentado no projeto;
- registrar comandos executados;
- registrar arquivos alterados;
- parar com `needs_input`, `blocked` ou `failed` quando o contexto não permitir uma conclusão segura.

### Etapa 5: validar e revisar

A validação final não termina só quando os testes passam. O fluxo canônico de `execute-task` exige também revisão.

Vereditos canônicos da skill `review`:

- `APPROVED`
- `APPROVED_WITH_REMARKS`
- `REJECTED`

Se a revisão reprovar:

1. `execute-task` deve acionar `bugfix` para corrigir os achados no escopo da tarefa;
2. as validações necessárias devem ser executadas novamente;
3. uma nova revisão deve ser rodada;
4. o fluxo deve parar se atingir o limite de profundidade de invocação definido em `agent-governance`.

### Etapa 6: fechar evidências

Toda tarefa concluída deve gerar relatório de execução.

Saída esperada:

```text
tasks/prd-<slug-da-feature>/[num]_execution_report.md
```

O relatório deve incluir pelo menos:

- identificação da tarefa;
- estado final;
- PRD e TechSpec consultados;
- comandos executados;
- arquivos alterados;
- resultado de testes;
- resultado de lint;
- veredito do revisor;
- suposições;
- riscos residuais;
- conflitos de regra, quando existirem.

Validação automática da evidência:

```bash
.claude/scripts/validate-task-evidence.sh tasks/prd-checkout-com-cupons-por-segmento/2_execution_report.md
```

Se houver bugfix, o fluxo também pode gerar:

```text
tasks/prd-<slug-da-feature>/bugfix_report.md
```

### Comandos shell mais úteis durante o fluxo

Os comandos abaixo não substituem as skills; eles servem para inspecionar artefatos e validar o que foi produzido.

```bash
# instalar a governança no projeto alvo
bash install.sh --tools all --langs all /caminho/do/projeto

# revisar a governança instalada
cd /caminho/do/projeto
sed -n '1,220p' AGENTS.md
find .agents/skills -maxdepth 2 -type f | sort | sed -n '1,200p'

# inspecionar artefatos da feature
find tasks/prd-<slug-da-feature> -maxdepth 1 -type f | sort
sed -n '1,220p' tasks/prd-<slug-da-feature>/prd.md
sed -n '1,260p' tasks/prd-<slug-da-feature>/techspec.md
sed -n '1,260p' tasks/prd-<slug-da-feature>/tasks.md

# revisar status e dependências
rg -n "pending|in_progress|needs_input|blocked|failed|done" tasks/prd-<slug-da-feature>

# validar evidência da tarefa executada
.claude/scripts/validate-task-evidence.sh tasks/prd-<slug-da-feature>/[num]_execution_report.md

# quando a instalação for por cópia, verificar atualização das skills
bash upgrade.sh --check /caminho/do/projeto
```

### Como acionar o fluxo em cada ferramenta

As skills canônicas são as mesmas para todas as ferramentas. O que muda é apenas o adaptador disponível no projeto-alvo.

#### Claude Code

Os subagentes gerados ficam em `.claude/agents/`:

- `prd-writer`
- `technical-specification-writer`
- `task-planner`
- `task-executor`

Use cada um para o estágio correspondente do pipeline e mantenha o pedido estreito ao escopo da etapa.

#### Gemini CLI

Os comandos gerados ficam em `.gemini/commands/`:

- `create-prd`
- `create-technical-specification`
- `create-tasks`
- `execute-task`

Cada comando encaminha a solicitação para a skill canônica correspondente.

#### GitHub Copilot

Os agentes gerados ficam em `.github/agents/`:

- `prd-writer.agent.md`
- `technical-specification-writer.agent.md`
- `task-planner.agent.md`
- `task-executor.agent.md`

O papel deles é orientar a execução do mesmo pipeline dentro do contexto do Copilot.

#### Codex

O perfil padrão deste repositório em `.codex/config.toml` é enxuto, então:

- `agent-governance`
- `execute-task`
- `refactor`
- `review`
- `bugfix`

ficam habilitadas por default.

Para projetos-alvo instalados via `install.sh`, o default do gerador é `full`, então as skills de planejamento entram automaticamente. Se quiser manter o mesmo perfil enxuto deste repositório, instale com:

```bash
CODEX_SKILL_PROFILE=lean bash install.sh --tools codex --langs all /caminho/do/projeto
```

Se quiser explicitar o perfil completo, use:

```bash
CODEX_SKILL_PROFILE=full bash install.sh --tools codex --langs all /caminho/do/projeto
```

ou quando o projeto-alvo optar por carregá-las sob demanda.

### Exemplo de fluxo completo

Exemplo resumido para a feature `checkout-com-cupons-por-segmento`:

1. instalar a governança:

```bash
bash install.sh --tools all --langs all /caminho/do/projeto
cd /caminho/do/projeto
```

2. pedir o PRD ao agente:

```text
Use create-prd para a feature "checkout com cupons por segmento" e salve em tasks/prd-checkout-com-cupons-por-segmento/prd.md.
```

3. pedir a tech spec:

```text
Use create-technical-specification para tasks/prd-checkout-com-cupons-por-segmento/prd.md e gere a spec e as ADRs.
```

4. pedir o plano de tarefas:

```text
Use create-tasks para o PRD e a tech spec da feature checkout-com-cupons-por-segmento. Primeiro me mostre apenas o plano de alto nível para aprovação.
```

5. aprovar e gerar tarefas:

```text
Plano aprovado. Gere tasks.md e os arquivos detalhados de tarefa.
```

6. executar uma tarefa:

```text
Use execute-task para a primeira tarefa elegível da feature checkout-com-cupons-por-segmento e retorne o caminho do relatório de execução com o estado final.
```

7. validar a evidência:

```bash
find tasks/prd-checkout-com-cupons-por-segmento -maxdepth 1 -type f | sort
.claude/scripts/validate-task-evidence.sh tasks/prd-checkout-com-cupons-por-segmento/1_execution_report.md
```

## Sessão simulada de ponta a ponta

Esta seção mostra uma sessão completa, com prompts realistas, para uma feature simples em Go: criar um endpoint HTTP para listar pagamentos.

O objetivo aqui não é congelar um único formato de resposta, e sim mostrar a ordem operacional correta entre as skills, os arquivos esperados e os pontos em que o fluxo pode parar com `needs_input`, `blocked` ou `REJECTED`.

### Cenário

Suponha um serviço Go já existente com API HTTP e persistência de pagamentos. A demanda de produto é:

- expor um endpoint `GET /payments`;
- permitir filtros básicos por `status` e `customer_id`;
- suportar paginação;
- retornar contrato estável para consumo por frontend e integrações internas.

Slug adotado no exemplo:

```text
tasks/prd-listar-pagamentos/
```

### Prompt inicial do usuário

Exemplo de pedido inicial ao agente:

```text
Precisamos de uma feature para listar pagamentos no serviço Go. Quero um endpoint GET /payments com paginação e filtros por status e customer_id. Use o fluxo canônico completo: PRD, tech spec, tasks, execução, revisão e evidências.
```

### Etapa 1: create-prd

Prompt recomendado:

```text
Use create-prd para a feature "listar pagamentos". Gere ou atualize tasks/prd-listar-pagamentos/prd.md. Contexto inicial: serviço Go existente, endpoint GET /payments, filtros por status e customer_id, paginação, resposta JSON para consumo de frontend e integrações internas. Se faltar contexto objetivo, faça no máximo duas rodadas de perguntas e retorne needs_input.
```

Saída esperada:

```text
tasks/prd-listar-pagamentos/prd.md
```

O PRD deveria deixar claros ao menos estes pontos:

- objetivo da feature;
- personas ou consumidores do endpoint;
- requisitos funcionais numerados;
- regras de paginação;
- comportamento esperado para filtros inválidos;
- itens fora de escopo, por exemplo ordenação avançada ou exportação CSV.

Verificação manual:

```bash
sed -n '1,260p' tasks/prd-listar-pagamentos/prd.md
```

### Etapa 2: create-technical-specification

Prompt recomendado:

```text
Use create-technical-specification para tasks/prd-listar-pagamentos/prd.md. Explore apenas o código relevante do serviço Go, especialmente rotas HTTP, handlers, camada de aplicação, repositórios, modelos de pagamento, paginação, observabilidade e testes. Gere tasks/prd-listar-pagamentos/techspec.md e crie ADRs separadas para decisões materiais.
```

Saídas esperadas:

```text
tasks/prd-listar-pagamentos/techspec.md
tasks/prd-listar-pagamentos/adr-001-<slug>.md
tasks/prd-listar-pagamentos/adr-002-<slug>.md
```

Decisões que tipicamente apareceriam nessa tech spec:

- contrato do endpoint `GET /payments`;
- formato dos query params `page`, `page_size`, `status`, `customer_id`;
- shape da resposta JSON;
- mapeamento entre handler, use case e repositório;
- estratégia para paginação estável;
- tratamento de erro para filtros inválidos;
- testes unitários e de integração a serem adicionados;
- logs, métricas e rastreabilidade mínima do endpoint.

Exemplos de ADRs plausíveis:

- `adr-001-paginacao-offset-limit.md`
- `adr-002-contrato-http-de-listagem-de-pagamentos.md`

Verificação manual:

```bash
sed -n '1,260p' tasks/prd-listar-pagamentos/techspec.md
find tasks/prd-listar-pagamentos -maxdepth 1 -type f | sort
```

### Etapa 3: create-tasks

Primeiro prompt, apenas para proposta do plano:

```text
Use create-tasks para tasks/prd-listar-pagamentos/prd.md e tasks/prd-listar-pagamentos/techspec.md. Primeiro proponha somente o plano de alto nível para aprovação. Não gere tasks.md nem os arquivos detalhados ainda.
```

Exemplo de plano de alto nível que seria razoável aprovar:

1. adicionar contrato HTTP, validação de query params e handler de listagem;
2. implementar caso de uso e acesso ao repositório com filtros e paginação;
3. adicionar testes unitários e de integração do endpoint;
4. revisar observabilidade, documentação e evidências finais.

Depois da aprovação:

```text
Plano aprovado. Gere tasks/prd-listar-pagamentos/tasks.md e os arquivos detalhados de tarefa, com dependências, critérios de aceitação e testes explícitos.
```

Saídas esperadas:

```text
tasks/prd-listar-pagamentos/tasks.md
tasks/prd-listar-pagamentos/1.0-contrato-http-e-handler.md
tasks/prd-listar-pagamentos/2.0-use-case-e-repositorio.md
tasks/prd-listar-pagamentos/3.0-testes-da-listagem.md
tasks/prd-listar-pagamentos/4.0-observabilidade-e-documentacao.md
```

Verificação manual:

```bash
sed -n '1,260p' tasks/prd-listar-pagamentos/tasks.md
find tasks/prd-listar-pagamentos -maxdepth 1 -type f | sort
```

### Etapa 4: execute-task

Agora o fluxo sai do planejamento e entra em implementação real.

Prompt recomendado para a primeira tarefa elegível:

```text
Use execute-task para a primeira tarefa elegível em tasks/prd-listar-pagamentos/. Leia prd.md, techspec.md, tasks.md e o arquivo da tarefa. Como esta feature altera código Go, carregue o contexto de Go sob demanda. Implemente, adicione testes, rode validação proporcional, faça a revisão e retorne o caminho do relatório de execução com o estado final.
```

O que normalmente aconteceria nessa execução:

- leitura de `AGENTS.md` e `agent-governance`;
- carga de `go-implementation`;
- implementação do handler e validação de query params;
- atualização do caso de uso ou service;
- adição de testes;
- execução de `go test` ou do comando equivalente detectado no projeto;
- geração de relatório de execução.

Saída esperada:

```text
tasks/prd-listar-pagamentos/1_execution_report.md
```

Verificação manual:

```bash
sed -n '1,260p' tasks/prd-listar-pagamentos/1_execution_report.md
```

### Etapa 5: review

Mesmo quando `execute-task` já conduz a revisão dentro do fluxo, é útil mostrar o prompt explícito, porque muitos times preferem rodar `review` de forma deliberada ao final de uma fatia maior.

Prompt recomendado:

```text
Use review para revisar o diff da implementação da feature listar pagamentos no serviço Go. Priorize bugs, regressões, riscos de contrato HTTP, paginação, tratamento de erro, observabilidade e testes faltantes. Retorne primeiro os achados com severidade e depois o veredito canônico.
```

Saída esperada:

- findings ordenados por severidade;
- veredito `APPROVED`, `APPROVED_WITH_REMARKS` ou `REJECTED`.

Exemplo de achados plausíveis nessa feature:

- paginação sem limite máximo, permitindo `page_size` excessivo;
- filtro `status` aceitando valor inválido e vazando erro de banco;
- ausência de teste cobrindo resposta vazia com metadados de paginação;
- contrato JSON sem campo `next_page` documentado na tech spec.

### Etapa 6: bugfix se a review reprovar

Se a revisão voltar com `REJECTED`, o fluxo continua com remediação antes do encerramento.

Prompt recomendado:

```text
Use bugfix para corrigir os achados da revisão da feature listar pagamentos, mantendo o escopo da tarefa atual. Atualize testes de regressão, rode novamente as validações necessárias e gere o relatório de correção.
```

Saída esperada:

```text
tasks/prd-listar-pagamentos/bugfix_report.md
```

Depois disso, uma nova revisão deve ser rodada:

```text
Use review novamente para revisar apenas o diff residual da remediação da feature listar pagamentos e retorne o veredito canônico.
```

### Etapa 7: fechamento e evidências

Ao final de uma execução saudável, o diretório da feature tende a ficar assim:

```text
tasks/prd-listar-pagamentos/
├── prd.md
├── techspec.md
├── adr-001-paginacao-offset-limit.md
├── adr-002-contrato-http-de-listagem-de-pagamentos.md
├── tasks.md
├── 1.0-contrato-http-e-handler.md
├── 2.0-use-case-e-repositorio.md
├── 3.0-testes-da-listagem.md
├── 4.0-observabilidade-e-documentacao.md
├── 1_execution_report.md
└── bugfix_report.md
```

`bugfix_report.md` só existe quando houve remediação após findings.

Verificações finais úteis:

```bash
find tasks/prd-listar-pagamentos -maxdepth 1 -type f | sort
sed -n '1,220p' tasks/prd-listar-pagamentos/prd.md
sed -n '1,260p' tasks/prd-listar-pagamentos/techspec.md
sed -n '1,260p' tasks/prd-listar-pagamentos/tasks.md
sed -n '1,260p' tasks/prd-listar-pagamentos/1_execution_report.md
.claude/scripts/validate-task-evidence.sh tasks/prd-listar-pagamentos/1_execution_report.md
```

### Versão curta dos prompts em sequência

Se você quiser uma sequência direta, quase pronta para copiar em uma sessão real, ela fica assim:

```text
1. Use create-prd para a feature "listar pagamentos" e gere tasks/prd-listar-pagamentos/prd.md.

2. Use create-technical-specification para tasks/prd-listar-pagamentos/prd.md. Explore apenas o código Go relevante e gere techspec.md e ADRs.

3. Use create-tasks para o PRD e a tech spec da feature listar pagamentos. Primeiro proponha apenas o plano de alto nível para aprovação.

4. Plano aprovado. Gere tasks/prd-listar-pagamentos/tasks.md e os arquivos detalhados de tarefa.

5. Use execute-task para a primeira tarefa elegível em tasks/prd-listar-pagamentos/ e retorne o caminho do relatório de execução com o estado final.

6. Use review para revisar o diff da implementação da feature listar pagamentos e retorne findings e veredito canônico.

7. Se o veredito for REJECTED, use bugfix para corrigir os achados, rodar regressão e gerar bugfix_report.md.

8. Use review novamente para validar a remediação e retornar o veredito final.
```

### Exemplos de prompts prontos

Os exemplos abaixo servem quando você quer falar com o agente de forma mais natural, sem depender só do nome da skill. Eles também ajudam a padronizar o nível de detalhe esperado na resposta.

#### Prompt completo de abertura

```text
Quero implementar uma feature nova no serviço Go: um endpoint GET /payments para listar pagamentos. O endpoint precisa aceitar paginação e filtros por status e customer_id. Siga o fluxo canônico completo deste repositório: gere o PRD, depois a especificação técnica com ADRs se necessário, depois proponha o plano de tarefas, espere aprovação, gere as tarefas detalhadas, execute a primeira tarefa elegível, rode validação proporcional, faça review e registre as evidências.
```

#### Prompt para create-prd com mais contexto

```text
Use create-prd para a feature "listar pagamentos". Considere que o consumidor principal será o frontend administrativo, mas o contrato também pode ser usado por integrações internas. O endpoint deve retornar lista paginada, aceitar filtros por status e customer_id, e deixar fora de escopo ordenação avançada, exportação e filtros compostos mais sofisticados. Gere tasks/prd-listar-pagamentos/prd.md. Se faltar contexto crítico, faça no máximo duas rodadas de perguntas.
```

#### Prompt para create-prd quando você quer objetividade máxima

```text
Use create-prd para "listar pagamentos". Não entre em detalhes de implementação. Foque em objetivo, requisitos funcionais numerados, restrições, fora de escopo, critérios de sucesso e ambiguidades que precisem de esclarecimento. Salve em tasks/prd-listar-pagamentos/prd.md.
```

#### Prompt para create-technical-specification com foco arquitetural

```text
Use create-technical-specification para tasks/prd-listar-pagamentos/prd.md. Explore apenas as partes do serviço Go relevantes para rotas HTTP, handlers, camada de aplicação, modelos de pagamento, paginação, observabilidade, tratamento de erro e testes. Gere tasks/prd-listar-pagamentos/techspec.md, mapeie requisito -> decisão -> teste e crie ADRs separadas para decisões materiais.
```

#### Prompt para create-technical-specification com foco em contrato HTTP

```text
Use create-technical-specification para a feature listar pagamentos e seja concreto no contrato do endpoint. Quero ver método, path, query params, formato da resposta JSON, comportamento para filtros inválidos, paginação, erros esperados e estratégia de testes. Gere techspec.md e ADRs no diretório tasks/prd-listar-pagamentos/.
```

#### Prompt para create-tasks em modo aprovação

```text
Use create-tasks para tasks/prd-listar-pagamentos/prd.md e tasks/prd-listar-pagamentos/techspec.md. Primeiro me mostre apenas um plano de alto nível com poucas tarefas, dependências e riscos. Não gere tasks.md ainda. Quero aprovar a decomposição antes.
```

#### Prompt para create-tasks após aprovação

```text
Plano aprovado. Agora use create-tasks para gerar tasks/prd-listar-pagamentos/tasks.md e os arquivos detalhados de cada tarefa. Inclua critérios de aceitação, dependências, testes esperados e sinais claros de done.
```

#### Prompt para execute-task com foco em implementação real

```text
Use execute-task para a primeira tarefa elegível em tasks/prd-listar-pagamentos/. Leia prd.md, techspec.md, tasks.md e o arquivo da tarefa antes de editar qualquer código. Como a tarefa altera código Go, carregue a skill de Go sob demanda. Faça a menor mudança segura, adicione testes de regressão, rode validação proporcional e retorne o caminho do relatório de execução com o estado final.
```

#### Prompt para execute-task em uma tarefa específica

```text
Use execute-task para a tarefa 2.0 em tasks/prd-listar-pagamentos/. Não escolha outra tarefa. Siga os critérios de aceitação exatamente como estão definidos, preserve o comportamento público fora do escopo e gere o relatório final da execução.
```

#### Prompt para review com viés de dono do código

```text
Use review para revisar o diff da feature listar pagamentos no serviço Go. Quero uma revisão rigorosa no estilo code owner: priorize bugs, regressões comportamentais, riscos de paginação, contrato HTTP, tratamento de erro, observabilidade e testes faltantes. Liste primeiro os findings com severidade e referência de arquivo quando aplicável, depois dê o veredito canônico.
```

#### Prompt para review depois de bugfix

```text
Use review novamente para revisar apenas o diff residual após a remediação da feature listar pagamentos. Verifique se os achados anteriores foram realmente corrigidos, se não surgiram regressões e retorne o veredito canônico.
```

#### Prompt para bugfix após review rejeitada

```text
Use bugfix para corrigir os findings da review da feature listar pagamentos. Mantenha o escopo limitado aos problemas apontados, atualize os testes necessários, rode regressão proporcional e gere tasks/prd-listar-pagamentos/bugfix_report.md com as evidências da correção.
```

#### Prompt para retomar uma sessão interrompida

```text
Retome a feature listar pagamentos a partir dos artefatos já existentes em tasks/prd-listar-pagamentos/. Primeiro leia prd.md, techspec.md, tasks.md e o status atual das tarefas. Depois continue apenas da próxima etapa elegível do fluxo, sem recriar artefatos que já estejam prontos.
```

#### Prompt para exigir disciplina de saída

```text
Ao executar esta etapa, não me entregue só um resumo. Quero os caminhos dos arquivos gerados ou atualizados, o estado final canônico da etapa, os bloqueios ou suposições e os comandos de validação executados.
```

### Sinais de que o fluxo está saudável

- o PRD está em `tasks/prd-<slug>/prd.md`;
- a tech spec está em `tasks/prd-<slug>/techspec.md`;
- ADRs existem para decisões materiais;
- `tasks.md` usa apenas estados canônicos;
- nenhuma tarefa é executada antes de suas dependências estarem em `done`;
- cada tarefa executada gera relatório;
- o relatório passa em `.claude/scripts/validate-task-evidence.sh`;
- a revisão final fecha em `APPROVED` ou `APPROVED_WITH_REMARKS`.

## Contribuindo

Se você for evoluir o projeto:

1. altere primeiro a skill canônica em `.agents/skills/`;
2. evite mover lógica para adaptadores quando a fonte correta for a skill;
3. atualize testes, snapshots ou fixtures quando a saída esperada mudar;
4. revise o `README.md` quando o comportamento operacional mudar.

## Resumo

`ai-governance` centraliza skills canônicas para agentes de IA, gera adaptadores leves para múltiplas ferramentas e contextualiza a governança no projeto-alvo. O foco do repositório é manter consistência operacional com a menor duplicação possível.
