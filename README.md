# ai-governance

Governanca reutilizavel para agentes de IA em repositórios reais, com uma base canônica de skills em `.agents/skills/`, adaptadores por ferramenta e geração contextual de instruções para o projeto-alvo.

O objetivo do projeto é evitar duplicação de processo entre Claude Code, Codex, Gemini CLI e GitHub Copilot, mantendo uma única fonte de verdade para regras operacionais, referências e fluxos de trabalho.

> Last reviewed: 2026-04-20

## Para quem é

Este README é voltado para quem quer:

- instalar governança de IA em outro repositório;
- entender o que `install.sh`, `upgrade.sh`, `uninstall.sh` e os scripts auxiliares realmente fazem;
- usar o fluxo spec-driven completo: PRD -> Tech Spec -> Tasks -> Execução -> Review -> Bugfix;
- rodar todas as tasks aprovadas em sequência com `execute-task-all` ou `scripts/loop-execute-tasks.sh`;
- evoluir as skills e adaptadores deste repositório sem quebrar o contrato existente.

## O que o projeto entrega

### Fonte única de verdade

Toda a lógica procedural fica em `.agents/skills/`. Hoje o repositório contém 25 skills canônicas, cobrindo:

- governança e análise: `agent-governance`, `analyze-project`;
- planejamento: `create-prd`, `create-technical-specification`, `create-tasks`, `us-to-prd`;
- execução e qualidade: `execute-task`, `execute-task-all`, `review`, `bugfix`, `refactor`, `semantic-commit`;
- linguagem: `go-implementation`, `node-implementation`, `python-implementation`, `object-calisthenics-go`;
- publicação e operação: `pull-request`, `jira-tasks`, `github-pr-comment-triage`, `github-diff-changelog-publisher`, `github-release-publication-flow`, `confluence-changelog-publisher`, `otel-grafana-dashboards`, `postman-collection-generator`, `prompt-enricher`.

### Adaptadores por ferramenta

Os scripts do projeto geram ou instalam integrações para:

| Ferramenta | Artefatos instalados |
|------------|----------------------|
| Claude Code | `CLAUDE.md`, `.claude/skills/`, `.claude/agents/`, `.claude/rules/`, `.claude/scripts/`, `.claude/hooks/` |
| Gemini CLI | `GEMINI.md`, `.gemini/commands/` |
| Codex | `.codex/config.toml` |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/skills/`, `.github/agents/` |

Os adaptadores não redefinem o processo. Eles apontam para `.agents/skills/`, que continua sendo a fonte de verdade.

### Automação e utilitários operacionais

Além das skills, o repositório já inclui:

- `install.sh`: instala a governança em outro projeto;
- `upgrade.sh`: verifica e atualiza instalações em modo `copy`;
- `uninstall.sh`: remove artefatos instalados sem apagar extensões locais do usuário;
- `scripts/semver-next.sh`: calcula bootstrap, release ou no-release a partir de commits e tags;
- `scripts/check-rf-coverage.sh`: valida se `tasks.md` cobre todos os RF/REQ/RNF do PRD;
- `scripts/check-spec-drift.sh`: detecta drift entre `prd.md`, `techspec.md` e `tasks.md`;
- `scripts/check-task-completion.sh`: bloqueia tasks marcadas como `done` sem execution report válido;
- `scripts/check-budget-regression.sh`: compara o budget atual de contexto contra `.budget-baseline.json`;
- `scripts/lib/validator-patterns.sh`: centraliza padrões dos validadores com override por locale em `i18n/<lang>/validator-patterns.sh`;
- `scripts/loop-execute-tasks.sh`: executa todas as tasks elegíveis de uma feature em loop, com contexto limpo por iteração.

### Geração contextual

Quando `GENERATE_CONTEXTUAL_GOVERNANCE=1`:

- `install.sh` chama `.agents/skills/analyze-project/scripts/generate-governance.sh`;
- o gerador tenta classificar a arquitetura do projeto-alvo;
- o gerador detecta stack principal, frameworks e sinais de toolchain;
- `AGENTS.md` e arquivos auxiliares passam a refletir o contexto real do repositório instalado.

## Estrutura do repositório

| Caminho | Papel |
|--------|-------|
| `.agents/skills/` | skills canônicas, assets, references e scripts de suporte |
| `.claude/` | adaptadores e regras base para Claude Code |
| `.codex/` | configuração local do Codex neste repositório |
| `.gemini/` | comandos base para Gemini CLI |
| `.github/` | adaptadores para Copilot e workflows de CI/release |
| `i18n/en/` | traduções em inglês de arquivos centrais de governança |
| `scripts/` | geração de adaptadores, validações e utilitários compartilhados |
| `tasks/` | exemplos reais de PRD, tech spec, tasks e relatórios de execução |
| `tests/` | testes end-to-end, fixtures e validações de regressão |
| `install.sh` | instalação da governança em projeto-alvo |
| `upgrade.sh` | verificação e atualização de skills instaladas |
| `uninstall.sh` | remoção dos artefatos instalados |
| `VERSION` | versão do pacote de governança |

## Instalação

### Pré-requisitos

Para instalar em outro projeto, o código exige:

- `bash`;
- diretório-alvo já existente;
- permissão de escrita no diretório-alvo.

Para rodar testes, CI e alguns scripts auxiliares, `python3` também é usado no repositório.

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
- `--dry-run`: mostra o que seria criado sem alterar arquivos

### Instalação a partir de tag ou ref explícita

```bash
# instalar a partir de um tag explícito
bash install.sh --ref v1.1.0 /caminho/do/projeto

# equivalente via ambiente
AI_GOVERNANCE_REF=v1.1.0 bash install.sh --tools codex --langs go /caminho/do/projeto
```

Contrato operacional:

- sem `--ref`, `install.sh` usa o checkout atual do repositório onde o script está sendo executado;
- com `--ref`, o script materializa um snapshot limpo daquela árvore Git e registra a ref escolhida nos logs;
- quando `--ref` é usado, `LINK_MODE=symlink` é ajustado automaticamente para `copy`, evitando symlinks para diretórios temporários;
- refs inválidas falham com erro explícito antes de qualquer escrita no projeto-alvo.

### Variáveis de ambiente relevantes

| Variável | Default | Efeito |
|----------|---------|--------|
| `LINK_MODE` | `symlink` | usa symlinks para as skills canônicas; com `copy`, instala um snapshot local |
| `GENERATE_CONTEXTUAL_GOVERNANCE` | `1` | com `1`, gera `AGENTS.md` contextual; com `0`, copia os arquivos base sem personalização |
| `CODEX_SKILL_PROFILE` | `full` | controla o conjunto de skills no `.codex/config.toml` gerado para projetos-alvo |
| `DETECT_TOOLCHAIN_MAX_DEPTH` | `4` | profundidade máxima usada na detecção de manifests |
| `DETECT_TOOLCHAIN_FOCUS_PATHS` | vazio | prioriza paths afetados ao detectar o workspace ou package mais relevante |

Exemplos:

```bash
# instalação padrão com symlink
bash install.sh /caminho/do/projeto

# instalação portável com cópia
LINK_MODE=copy bash install.sh /caminho/do/projeto

# sem geração contextual
GENERATE_CONTEXTUAL_GOVERNANCE=0 bash install.sh /caminho/do/projeto

# perfil enxuto para Codex
CODEX_SKILL_PROFILE=lean bash install.sh --tools codex --langs all /caminho/do/projeto

# perfil completo para Codex
CODEX_SKILL_PROFILE=full bash install.sh --tools codex --langs all /caminho/do/projeto
```

## Upgrade e remoção

Use `upgrade.sh` quando a instalação tiver sido feita em modo `copy`.

```bash
# apenas verificar
bash upgrade.sh --check /caminho/do/projeto

# atualizar skills desatualizadas
bash upgrade.sh /caminho/do/projeto

# comparar contra uma tag específica
bash upgrade.sh --check --ref v1.1.0 /caminho/do/projeto

# filtrar por linguagem
bash upgrade.sh --langs go /caminho/do/projeto
```

Sem `--ref`, o `upgrade.sh` compara contra o checkout atual do repositório fonte. Com `--ref`, a comparação e a cópia passam a usar exatamente o snapshot daquele tag, branch ou commit.

Para remover uma instalação:

```bash
# simular remoção
bash uninstall.sh --dry-run /caminho/do/projeto

# remover artefatos instalados
bash uninstall.sh /caminho/do/projeto
```

O `uninstall.sh` remove os artefatos gerados pelo `install.sh`, preservando extensões locais como `AGENTS.local.md`.

## Perfis do Codex

Para projetos-alvo instalados com `install.sh`, o default em `scripts/lib/codex-config.sh` é `full`. Isso inclui skills de planejamento e execução.

Quando `CODEX_SKILL_PROFILE=full`, o `.codex/config.toml` gerado habilita o fluxo completo de planejamento, incluindo:

- `agent-governance`
- `analyze-project`
- `create-prd`
- `create-technical-specification`
- `create-tasks`
- `execute-task`
- `refactor`
- `review`
- `bugfix`

Quando `CODEX_SKILL_PROFILE` recebe qualquer valor diferente de `full`, o gerador cai no perfil operacional enxuto, focado em execução:

- `agent-governance`
- `execute-task`
- `refactor`
- `review`
- `bugfix`

O arquivo deste próprio repositório em `.codex/config.toml` usa esse perfil enxuto para reduzir contexto local.

Observação importante:

- `execute-task-all` existe como skill canônica neste repositório, mas o `install.sh` e o perfil `full` atual do Codex ainda não a habilitam por padrão em projetos-alvo;
- para instalações padrão, o caminho disponível e documentado para executar todas as tasks é `scripts/loop-execute-tasks.sh`;
- neste repositório fonte você pode usar tanto a skill `execute-task-all` quanto o looper externo, dependendo do nível de isolamento de contexto que quiser.

## Release SemVer

O script `scripts/semver-next.sh` calcula a decisão de release a partir do último tag SemVer alcançável e do `VERSION` atual. O contrato de saída é estável em `key=value` para consumo por workflows e scripts.

```bash
bash scripts/semver-next.sh
```

Campos principais:

- `action=bootstrap|release|no_release`
- `bootstrap_required=true|false`
- `release_required=true|false`
- `last_tag=...`
- `base_version=...`
- `bump=major|minor|patch|no_release`
- `target_version=...`

Esse fluxo já está integrado em `.github/workflows/release-dry-run.yml` e `.github/workflows/release.yml`.

## Gates de governança

Além dos testes E2E, o repositório agora possui gates explícitos para custo de contexto e fechamento consistente de execução.

### Budget de contexto

```bash
# gate simples de budget
bash scripts/check-token-budget.sh --max 15000 AGENTS.md .agents/skills/agent-governance/SKILL.md

# regressão contra baseline commitado
bash scripts/check-budget-regression.sh

# threshold customizado
bash scripts/check-budget-regression.sh --threshold 10
```

Contrato:

- `.budget-baseline.json` registra o baseline commitado por stack;
- pequenas oscilações são toleradas pelo `threshold_pct`, mas aumentos maiores exigem atualizar o baseline explicitamente;
- esse gate já aparece em `.github/workflows/governance-check.yml` e na suíte de testes.

### Fechamento de task

```bash
bash scripts/check-task-completion.sh tasks/prd-listar-pagamentos
```

Contrato:

- toda task marcada como `done` em `tasks.md` precisa ter `[num]_execution_report.md`;
- o report precisa passar em `scripts/validators/validate-task-evidence.sh`;
- `execute-task` passou a depender desse gate antes de encerrar uma task como concluída.

### Workflow reutilizável para projetos consumidores

O workflow `.github/workflows/governance-check.yml` expõe inputs para:

- `langs`;
- `token-budget`;
- `budget-regression-threshold`;
- `check-budget-regression`;
- `validate-evidence`;
- `check-spec-drift`;
- `check-rf-coverage`;
- `check-task-completion`.

## Uso completo

Esta é a sequência recomendada para trabalhar uma feature do zero até a execução de todas as tasks aprovadas.

### 1. Instalar a governança no projeto-alvo

```bash
bash install.sh --tools claude,codex,gemini,copilot --langs go,node,python /caminho/do/projeto
```

Se você quiser uma instalação portável, prefira:

```bash
LINK_MODE=copy bash install.sh --tools codex --langs go /caminho/do/projeto
```

### 2. Criar o PRD com `create-prd`

O que a skill exige:

- objetivo e problema da feature;
- ator principal;
- escopo incluído e excluído;
- restrições;
- critérios de sucesso mensuráveis.

Prompt de exemplo:

```text
Use create-prd para a feature "listar pagamentos".
Gere ou atualize tasks/prd-listar-pagamentos/prd.md.

Contexto inicial:
- serviço Go existente;
- endpoint GET /payments;
- filtros por status e customer_id;
- paginação;
- resposta JSON para consumo do frontend administrativo e integrações internas.

Restrições:
- não incluir exportação;
- não incluir ordenação avançada;
- manter compatibilidade com autenticação e observabilidade atuais.

Se faltar contexto crítico, faça no máximo duas rodadas de perguntas e retorne needs_input.
```

Saída esperada:

- `tasks/prd-listar-pagamentos/prd.md`

Uso recomendado:

- mantenha o prompt no nível de produto e evite detalhes de implementação;
- se a feature estiver difusa, peça explicitamente que a skill faça até duas rodadas de esclarecimento e retorne `needs_input` se ainda faltar definição objetiva;
- reuse um `prd.md` existente quando estiver evoluindo uma feature já aberta em vez de criar outra pasta concorrente.

### 3. Criar a tech spec com `create-technical-specification`

Essa skill parte do PRD aprovado e, pelo contrato dela, carrega governança e referências sob demanda para arquitetura, DDD, erros, segurança e testes quando o contexto exigir.

Prompt de exemplo:

```text
Use create-technical-specification para tasks/prd-listar-pagamentos/prd.md.

Explore apenas o código relevante do serviço Go, especialmente:
- rotas HTTP;
- handlers;
- camada de aplicação;
- repositórios;
- modelos de pagamento;
- paginação;
- observabilidade;
- testes existentes.

Se houver decisões materiais de domínio, arquitetura ou contratos, carregue o que for necessário de DDD, error-handling, security e testing via agent-governance.

Gere tasks/prd-listar-pagamentos/techspec.md e ADRs separadas para decisões materiais.
```

Saídas esperadas:

- `tasks/prd-listar-pagamentos/techspec.md`
- `tasks/prd-listar-pagamentos/adr-001-*.md`, `adr-002-*.md`, quando aplicável

Uso recomendado:

- cite explicitamente fronteiras de domínio, contratos de interface, idempotência, observabilidade e estratégia de testes;
- quando a decisão tocar modelagem de domínio, peça para carregar `ddd.md`;
- quando tocar fluxo de erro, peça `error-handling.md`;
- quando tocar autenticação, autorização, input externo, dependências ou segredos, peça `security.md` e `security-app.md` conforme o caso;
- quando a estratégia de validação for material, peça `testing.md`.

### 4. Criar as tasks com `create-tasks`

Essa skill tem duas fases:

1. propor apenas o plano de alto nível;
2. depois da aprovação, gerar `tasks.md` e um arquivo por task.

Prompt para a fase 1:

```text
Use create-tasks para tasks/prd-listar-pagamentos/prd.md e tasks/prd-listar-pagamentos/techspec.md.
Primeiro proponha somente o plano de alto nível para aprovação.
Não gere tasks.md nem os arquivos detalhados ainda.
```

Depois de aprovar o plano:

```text
Pode prosseguir.
Gere tasks/prd-listar-pagamentos/tasks.md e os arquivos detalhados de cada task.
Inclua critérios de aceitação, dependências, referências a RF/REQ/RNF e o grafo Mermaid de dependências.
```

Saídas esperadas:

- `tasks/prd-listar-pagamentos/tasks.md`
- `tasks/prd-listar-pagamentos/1.0-*.md`, `2.0-*.md`, etc.

Uso recomendado:

- só gere as tasks detalhadas depois de aprovar o plano de alto nível;
- exija rastreabilidade para RF/REQ/RNF, critérios de aceitação e dependências;
- mantenha tasks pequenas o suficiente para permitir review, bugfix e evidência com baixo risco de regressão.

### 5. Executar uma task isolada com `execute-task`

Quando você quer atacar apenas uma task:

```text
Use execute-task para tasks/prd-listar-pagamentos/1.0-criar-caso-de-uso-listar-pagamentos.md.
Siga o fluxo canonico completo, incluindo validacao direcionada, review, bugfix se necessario e relatorio final.
```

### 6. Revisar do jeito certo com `review`

Para usar `review` da melhor forma, não envie só um diff solto. Passe também o contexto que define a intenção da mudança.

Prompt recomendado:

```text
Use review para o diff atual desta branch.

Contexto obrigatório:
- tasks/prd-listar-pagamentos/prd.md
- tasks/prd-listar-pagamentos/techspec.md
- tasks/prd-listar-pagamentos/1.0-criar-caso-de-uso-listar-pagamentos.md

Revise como code owner e priorize:
- correção funcional;
- regressões;
- segurança;
- testes faltantes;
- lacunas de evidência.

Carregue referências sob demanda via agent-governance quando afetarem materialmente a revisão:
- ddd.md para fronteiras de domínio e invariantes;
- error-handling.md para wrapping, tipos e propagação de erro;
- security.md e security-app.md para input externo, auth, autorização e segredos;
- testing.md para suficiência da estratégia de validação.

Retorne achados primeiro, com veredito canônico.
Se houver bugs acionáveis, emita no formato canônico para consumo de bugfix.
```

Uso recomendado:

- use `APPROVED` e `APPROVED_WITH_REMARKS` como únicos estados aprovadores finais;
- trate `BLOCKED` como falta de contexto ou evidência, não como detalhe cosmético;
- se o review retornar bugs canônicos, siga com `bugfix` dentro do escopo da task e depois rode nova validação e nova revisão.

### 7. Executar todas as tasks aprovadas com o looper

Há duas formas complementares de fazer isso.

#### Via skill `execute-task-all`

Use quando você quer deixar o agente seguir o loop canônico descrito na própria skill:

```text
Use execute-task-all para tasks/prd-listar-pagamentos/tasks.md.
Execute todas as tasks elegíveis em sequência até concluir tudo ou parar em blocked, failed ou needs_input.
```

Essa skill:

- valida presença de `prd.md`, `techspec.md` e `tasks.md`;
- executa `bash scripts/check-rf-coverage.sh ...` antes do loop;
- respeita dependências entre tasks;
- interrompe em `blocked`, `failed` ou `needs_input`;
- consolida evidências ao final.

#### Via script `scripts/loop-execute-tasks.sh`

Use quando você quer uma orquestração externa, com contexto limpo a cada iteração do CLI:

```bash
# usa Claude por default
bash scripts/loop-execute-tasks.sh listar-pagamentos

# executa via Codex
bash scripts/loop-execute-tasks.sh listar-pagamentos --tool codex

# executa via Gemini
bash scripts/loop-execute-tasks.sh listar-pagamentos --tool gemini

# executa via Copilot
bash scripts/loop-execute-tasks.sh listar-pagamentos --tool copilot
```

Contrato do script:

- entrada: `<feature-slug>` sem o prefixo `prd-`;
- exige `tasks/prd-<slug>/prd.md`, `techspec.md` e `tasks.md`;
- executa `scripts/check-rf-coverage.sh` antes de iniciar;
- usa lockfile para evitar dois loops simultâneos da mesma feature;
- grava logs em `.task-loop-logs/<timestamp>/`;
- retorna `0` quando todas as tasks elegíveis concluem com `done`;
- retorna `1` quando o loop para por `blocked`, `failed` ou `needs_input`;
- retorna `2` para uso incorreto ou pré-condição ausente.

Quando usar cada um:

- `execute-task-all`: quando você quer trabalhar no nível da skill e manter o fluxo dentro do agente;
- `scripts/loop-execute-tasks.sh`: quando você quer isolar contexto entre iterações e invocar explicitamente um CLI específico.

Recomendação prática:

- em projetos-alvo instalados pelo fluxo padrão, prefira `scripts/loop-execute-tasks.sh`;
- use `execute-task-all` quando a skill estiver disponível no contexto e você quiser seguir o contrato canônico dentro do próprio agente;
- se a feature for longa ou o contexto estiver pesado, o looper externo tende a ser a opção mais robusta.

### 8. Validar cobertura, drift e fechamento

Depois que o planejamento estiver pronto, estes utilitários ajudam a manter integridade entre os artefatos:

```bash
bash scripts/check-rf-coverage.sh tasks/prd-listar-pagamentos/prd.md tasks/prd-listar-pagamentos/tasks.md

bash scripts/check-spec-drift.sh tasks/prd-listar-pagamentos/tasks.md

bash scripts/check-task-completion.sh tasks/prd-listar-pagamentos

bash scripts/check-budget-regression.sh
```

## Traduções

O diretório `i18n/en/` contém traduções em inglês de arquivos centrais de governança. Hoje ele funciona como referência para times internacionais; a fonte canônica continua sendo o conteúdo em português.

Os validadores também podem carregar padrões localizados via `i18n/<lang>/validator-patterns.sh` quando `GOVERNANCE_LANG` ou a instalação contextual assim determinarem.

## Desenvolvimento e testes

Exemplos de validação local:

```bash
bash tests/test-install.sh
bash tests/test-upgrade.sh
bash tests/test-scripts.sh
bash tests/test-copilot-e2e.sh
bash tests/test-budget-regression.sh
bash tests/test-task-completion.sh
bash tests/test-template-contract.sh
bash tests/test-enforcement-fallback.sh
```

Ao alterar comportamento, prefira rodar primeiro os testes direcionados ao script ou fluxo afetado.

## Restrições e contratos importantes

- `install.sh` e `upgrade.sh` rejeitam o próprio repositório `ai-governance` como alvo;
- `upgrade.sh` só faz sentido para instalações em modo `copy`;
- o perfil local de Codex neste repositório é enxuto por padrão;
- a governança base sempre começa por `AGENTS.md` e `.agents/skills/agent-governance/SKILL.md`;
- tarefas que mudam comportamento devem atualizar testes e rodar validações proporcionais.

## Contribuindo

Ao evoluir o projeto:

- preserve `.agents/skills/` como fonte de verdade;
- evite duplicar processo em adaptadores;
- documente novos scripts e novos contratos operacionais no README;
- mantenha exemplos alinhados ao comportamento real do código.
