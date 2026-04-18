# ai-governance

Governanca reutilizavel para agentes de IA em diferentes CLIs, com skills canonicas, adaptadores por ferramenta e geracao contextual de instrucoes para cada projeto alvo.

O objetivo do projeto e oferecer uma base unica para instalar e manter instrucoes operacionais consistentes em repositórios reais, sem duplicar regras entre Claude Code, Codex, Gemini CLI e GitHub Copilot.

> Last reviewed: 2026-04-18

## Visao Geral

`ai-governance` organiza uma camada compartilhada de governanca para agentes de IA que trabalham com codigo. Em vez de manter prompts, regras e instrucoes separados para cada ferramenta, o repositorio centraliza skills, referencias e adaptadores leves em uma unica base.

Ele foi pensado para projetos que precisam de previsibilidade operacional em tarefas como:

- analise e entendimento de contexto;
- review e refactor;
- bugfix com validacao;
- criacao de PRD, especificacao tecnica e tarefas;
- execucao guiada por skill.

## Principais Beneficios

- uma fonte canonica unica em `.agents/skills/`;
- adaptadores leves para multiplas ferramentas, sem duplicacao de processo;
- geracao contextual de `AGENTS.md` e arquivos auxiliares a partir do projeto alvo;
- versionamento de skills para atualizacao controlada em instalacoes por copia;
- carregamento sob demanda de referencias para reduzir ruido e custo de contexto.

## Quick Start

```bash
bash install.sh /caminho/do/projeto
```

O instalador pergunta:

1. quais ferramentas devem ser instaladas;
2. quais linguagens devem receber skills de implementacao;
3. gera a governanca contextual no projeto alvo.

Para revisar a instalacao antes de gravar arquivos:

```bash
bash install.sh --dry-run /caminho/do/projeto
```

## Quando Usar

Use este repositorio quando voce quiser:

- padronizar o comportamento de agentes em diferentes ferramentas;
- instalar governanca de IA em um projeto existente sem duplicar regras;
- adaptar instrucoes ao contexto real do repositorio alvo;
- manter skills versionadas e atualizaveis ao longo do tempo.

## Ferramentas Suportadas

| Ferramenta | Integracao |
|------------|------------|
| Claude Code | `CLAUDE.md`, `.claude/skills/`, `.claude/agents/`, `.claude/rules/`, `.claude/scripts/` |
| Codex | `.codex/config.toml` |
| Gemini CLI | `GEMINI.md`, `.gemini/commands/` |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/agents/`, `.github/skills/` |

## O Que E Instalado

Dependendo das ferramentas e linguagens selecionadas durante a instalacao, o projeto alvo recebe:

| Tipo | Arquivos ou diretorios |
|------|------------------------|
| Base canonica | `AGENTS.md`, `.agents/skills/` |
| Claude Code | `CLAUDE.md`, `.claude/skills/`, `.claude/agents/`, `.claude/rules/`, `.claude/scripts/` |
| Gemini CLI | `GEMINI.md`, `.gemini/commands/` |
| Codex | `.codex/config.toml` |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/agents/`, `.github/skills/` |

As skills canonicas ficam sempre em `.agents/skills/`. Os adaptadores apenas referenciam ou copiam essa base, sem redefinir o processo.

## Estrutura do Repositorio

| Caminho | Papel |
|--------|-------|
| `.agents/skills/` | fonte canonica das skills e referencias |
| `.claude/` | integracao e wrappers para Claude Code |
| `.gemini/` | comandos para Gemini CLI |
| `.codex/` | configuracao para Codex |
| `.github/` | integracao para GitHub Copilot |
| `tests/` | testes de snapshot, scripts e fluxo de instalacao |
| `install.sh` | instalador interativo da governanca |
| `upgrade.sh` | verificador e atualizador de skills copiadas |

## Instalacao

### Pre-requisitos

Antes de instalar em um projeto alvo, tenha no ambiente:

- `bash`;
- permissoes de escrita no diretorio alvo;
- um projeto existente para receber a governanca.

Para desenvolvimento e execucao de todos os testes deste repositorio, `python3` tambem e utilizado em scripts auxiliares e validacoes.

### Fluxo Basico

Execute:

```bash
bash install.sh /caminho/do/projeto
```

Durante a execucao, o instalador pergunta:

1. quais ferramentas devem ser instaladas: `claude`, `gemini`, `codex`, `copilot` ou todas;
2. quais linguagens devem receber skills de implementacao: `go`, `node`, `python` ou todas.

Se nenhuma linguagem for informada, o instalador usa Go como padrao.

### Dry Run

Para inspecionar o que seria criado sem alterar arquivos:

```bash
bash install.sh --dry-run /caminho/do/projeto
```

Esse modo e util quando voce quer auditar a instalacao antes de gravar arquivos em um repositorio real.

### Modos de Instalacao

O comportamento do instalador pode ser ajustado com variaveis de ambiente:

| Variavel | Default | Efeito |
|----------|---------|--------|
| `LINK_MODE` | `symlink` | usa `symlink` para manter uma unica fonte de verdade ou `copy` para instalar um snapshot local |
| `GENERATE_CONTEXTUAL_GOVERNANCE` | `1` | quando `1`, gera arquivos contextuais; quando `0`, copia os arquivos base sem personalizacao |

Exemplos:

```bash
# instalacao padrao com symlinks
bash install.sh /caminho/do/projeto

# instalacao portavel com copia
LINK_MODE=copy bash install.sh /caminho/do/projeto

# instalacao sem geracao contextual
GENERATE_CONTEXTUAL_GOVERNANCE=0 bash install.sh /caminho/do/projeto
```

## Como O Projeto Funciona

### 1. Fonte canonica

Toda logica procedural fica em `.agents/skills/`. Cada skill possui seu proprio `SKILL.md`, referencias carregadas sob demanda e, quando necessario, scripts auxiliares.

### 2. Adaptadores leves por ferramenta

Claude, Codex, Gemini e Copilot recebem apenas a camada minima necessaria para apontar para a skill correta. O objetivo e evitar divergencia entre plataformas.

### 3. Geracao contextual de governanca

Quando `GENERATE_CONTEXTUAL_GOVERNANCE=1`, o script `.agents/skills/analyze-project/scripts/generate-governance.sh` analisa o projeto alvo e gera instrucoes mais precisas com base em:

- tipo de arquitetura detectado;
- stack principal;
- frameworks encontrados;
- ferramentas instaladas.

### 4. Skills por linguagem

As skills base sao sempre instaladas. Skills de implementacao entram conforme a selecao de linguagem:

| Linguagem | Skills instaladas |
|-----------|-------------------|
| Go | `go-implementation`, `object-calisthenics-go` |
| Node.js / TypeScript | `node-implementation` |
| Python | `python-implementation` |

As skills base instaladas por padrao incluem:

- `agent-governance`
- `analyze-project`
- `bugfix`
- `create-prd`
- `create-technical-specification`
- `create-tasks`
- `execute-task`
- `refactor`
- `review`

## Exemplo de Uso

Fluxo tipico para adotar o projeto em outro repositorio:

```bash
# 1. instalar a governanca
bash install.sh /caminho/do/projeto

# 2. verificar o que foi gerado no projeto alvo
ls -la /caminho/do/projeto

# 3. em instalacoes por copia, checar defasagem futuramente
bash upgrade.sh --check /caminho/do/projeto
```

## Deteccao Contextual

O gerador contextual usa heuristicas locais para reduzir falsos positivos.

### Tipos de arquitetura identificados

| Tipo | Sinais principais |
|------|-------------------|
| Monorepo | `go.work`, `pnpm-workspace.yaml`, `nx.json`, `turbo.json`, `lerna.json`, ou combinacoes como `apps/` + `packages/` |
| Monolito modular | `modules/`, `domains/` ou `internal/` com multiplos subdiretorios |
| Microservico | `Dockerfile` combinado com sinais de deploy isolado como `k8s/`, `helm/`, `deployments/`, `skaffold.yaml` ou `kustomization.yaml` |
| Monolito | fallback quando nao ha sinal forte suficiente |

### Stacks detectadas

Atualmente o gerador identifica, quando presentes:

- Go;
- Node.js;
- Python;
- Java/Kotlin.

Para Go, o gerador tambem tenta inferir frameworks como `Gin`, `Echo`, `Fiber`, `gRPC` e `Connect`.

## Atualizacao de Skills

Quando a instalacao e feita com `LINK_MODE=copy`, o projeto alvo passa a ter uma copia local das skills. Nesse caso, use `upgrade.sh` para verificar defasagem e aplicar atualizacoes.

### Verificar sem alterar

```bash
bash upgrade.sh --check /caminho/do/projeto
```

### Atualizar

```bash
bash upgrade.sh /caminho/do/projeto
```

O script compara o campo `version` do frontmatter de cada `SKILL.md` da fonte com a versao instalada no projeto alvo.

Se o projeto estiver usando symlinks, o script detecta isso e evita copias desnecessarias.

## Desenvolvimento

### Validacoes disponiveis

Este repositorio possui tres entradas principais de validacao:

```bash
# valida snapshots do gerador contextual
bash tests/test-generate-governance.sh

# valida o fluxo de instalacao end-to-end
bash tests/test-install.sh

# valida scripts auxiliares
bash tests/test-scripts.sh
```

### Atualizacao intencional de snapshots

Se houver mudanca deliberada na saida do gerador contextual:

```bash
bash tests/test-generate-governance.sh --update
```

## Estrutura de Testes

O diretorio `tests/fixtures/` contem projetos artificiais que exercitam os cenarios principais de deteccao:

- `go-microservice`
- `go-modular`
- `node-monorepo`

Os snapshots esperados ficam em `tests/snapshots/` e sao comparados contra o `AGENTS.md` gerado para cada fixture.

## Decisoes Importantes de Design

### Portabilidade sem duplicacao

O projeto separa claramente:

- a fonte de verdade procedural em `.agents/skills/`;
- as regras canonicas em `AGENTS.md`;
- os adaptadores especificos de cada ferramenta.

Isso reduz manutencao duplicada e preserva consistencia entre CLIs.

### Menor carga de contexto

As referencias das skills sao carregadas sob demanda. Em vez de enviar grandes blocos fixos para toda tarefa, cada skill define quando ler regras de DDD, seguranca, erros, testes ou padroes mais especificos.

### Atualizacao controlada

O campo `version` no frontmatter de cada `SKILL.md` permite comparar fonte e destino ao usar instalacao por copia. Isso fecha o ciclo de manutencao para projetos que nao usam symlink.

## Limitacoes e Observacoes

- `install.sh` nao permite instalar a governanca no proprio repositorio `ai-governance`;
- o diretorio alvo precisa existir antes da instalacao;
- a geracao contextual depende dos sinais encontrados localmente no projeto alvo;
- quando nenhum padrao forte e detectado, o gerador assume um fallback conservador e registra isso no resultado.

## Fluxo Recomendado de Uso

Para adotar este projeto em outro repositorio:

1. execute `bash install.sh /caminho/do/projeto`;
2. escolha as ferramentas de IA que o projeto realmente usa;
3. selecione apenas as linguagens relevantes para reduzir ruido;
4. revise os arquivos gerados no projeto alvo;
5. se optar por `LINK_MODE=copy`, inclua `upgrade.sh --check` na manutencao periodica.

## Arquivos Principais

| Arquivo | Finalidade |
|--------|------------|
| `AGENTS.md` | regra canonica compartilhada entre agentes |
| `CLAUDE.md` | adaptador base para Claude Code |
| `GEMINI.md` | adaptador base para Gemini CLI |
| `install.sh` | instalacao interativa no projeto alvo |
| `upgrade.sh` | verificacao e atualizacao de skills copiadas |

## Contribuicao

Contribuicoes devem preservar o contrato entre a base canonica e os adaptadores. Ao propor mudancas:

1. altere a skill canonica primeiro, evitando replicar logica nos adaptadores;
2. mantenha a menor mudanca segura e coerente com o padrao atual;
3. atualize testes e snapshots quando a saida esperada mudar;
4. revise o README se o fluxo operacional do projeto mudar.

Comandos uteis para validar mudancas:

```bash
bash tests/test-generate-governance.sh
bash tests/test-install.sh
bash tests/test-scripts.sh
```

## Roadmap Natural do Repositorio

Este projeto tende a evoluir em quatro frentes principais:

- novas skills canonicas;
- refinamento das heuristicas de deteccao contextual;
- melhoria dos adaptadores por ferramenta;
- fortalecimento de validacoes e testes de regressao.

## Resumo

`ai-governance` e uma base reutilizavel para instalar, adaptar e manter governanca de agentes de IA em projetos reais. O repositorio combina fonte canonica unica, adaptadores multiplataforma, geracao contextual e estrategia de atualizacao, com foco em consistencia operacional e baixo custo de manutencao.
