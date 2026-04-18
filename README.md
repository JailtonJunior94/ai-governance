# ai-governance

Governança reutilizável para agentes de IA em diferentes CLIs, com skills canônicas, adaptadores por ferramenta e geração contextual de instruções para cada projeto-alvo.

O objetivo do projeto é oferecer uma base única para instalar e manter instruções operacionais consistentes em repositórios reais, sem duplicar regras entre Claude Code, Codex, Gemini CLI e GitHub Copilot.

> Last reviewed: 2026-04-18

## Visão Geral

`ai-governance` organiza uma camada compartilhada de governança para agentes de IA que trabalham com código. Em vez de manter prompts, regras e instruções separados para cada ferramenta, o repositório centraliza skills, referências e adaptadores leves em uma única base.

Ele foi pensado para projetos que precisam de previsibilidade operacional em tarefas como:

- análise e entendimento de contexto;
- review e refactor;
- bugfix com validação;
- criação de PRD, especificação técnica e tarefas;
- execução guiada por skill.

## Principais Benefícios

- uma fonte canônica única em `.agents/skills/`;
- adaptadores leves para múltiplas ferramentas, sem duplicação de processo;
- geração contextual de `AGENTS.md` e arquivos auxiliares a partir do projeto-alvo;
- versionamento de skills para atualização controlada em instalações por cópia;
- carregamento sob demanda de referências para reduzir ruído e custo de contexto.

## Quick Start

```bash
bash install.sh /caminho/do/projeto
```

O instalador pergunta:

1. quais ferramentas devem ser instaladas;
2. quais linguagens devem receber skills de implementação;
3. gera a governança contextual no projeto-alvo.

Para revisar a instalação antes de gravar arquivos:

```bash
bash install.sh --dry-run /caminho/do/projeto
```

## Quando Usar

Use este repositório quando você quiser:

- padronizar o comportamento de agentes em diferentes ferramentas;
- instalar governança de IA em um projeto existente sem duplicar regras;
- adaptar instruções ao contexto real do repositório-alvo;
- manter skills versionadas e atualizáveis ao longo do tempo.

## Ferramentas Suportadas

| Ferramenta | Integração |
|------------|------------|
| Claude Code | `CLAUDE.md`, `.claude/skills/`, `.claude/agents/`, `.claude/rules/`, `.claude/scripts/` |
| Codex | `.codex/config.toml` |
| Gemini CLI | `GEMINI.md`, `.gemini/commands/` |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/agents/`, `.github/skills/` |

## O Que É Instalado

Dependendo das ferramentas e linguagens selecionadas durante a instalação, o projeto-alvo recebe:

| Tipo | Arquivos ou diretórios |
|------|------------------------|
| Base canônica | `AGENTS.md`, `.agents/skills/` |
| Claude Code | `CLAUDE.md`, `.claude/skills/`, `.claude/agents/`, `.claude/rules/`, `.claude/scripts/` |
| Gemini CLI | `GEMINI.md`, `.gemini/commands/` |
| Codex | `.codex/config.toml` |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/agents/`, `.github/skills/` |

As skills canônicas ficam sempre em `.agents/skills/`. Os adaptadores apenas referenciam ou copiam essa base, sem redefinir o processo.

## Estrutura do Repositório

| Caminho | Papel |
|--------|-------|
| `.agents/skills/` | fonte canônica das skills e referências |
| `.claude/` | integração e wrappers para Claude Code |
| `.gemini/` | comandos para Gemini CLI |
| `.codex/` | configuração para Codex |
| `.github/` | integração para GitHub Copilot |
| `tests/` | testes de snapshot, scripts e fluxo de instalação |
| `install.sh` | instalador interativo da governança |
| `upgrade.sh` | verificador e atualizador de skills copiadas |

## Instalação

### Pré-requisitos

Antes de instalar em um projeto-alvo, tenha no ambiente:

- `bash`;
- permissões de escrita no diretório-alvo;
- um projeto existente para receber a governança.

Para desenvolvimento e execução de todos os testes deste repositório, `python3` também é utilizado em scripts auxiliares e validações.

### Fluxo Básico

Execute:

```bash
bash install.sh /caminho/do/projeto
```

Durante a execução, o instalador pergunta:

1. quais ferramentas devem ser instaladas: `claude`, `gemini`, `codex`, `copilot` ou todas;
2. quais linguagens devem receber skills de implementação: `go`, `node`, `python` ou todas.

Se nenhuma linguagem for informada, o instalador mantém apenas as skills processuais base e não adiciona skills de linguagem.

### Modo Não Interativo

Para uso em scripts, CI ou automação, passe `--tools` e `--langs` diretamente:

```bash
# instalar apenas Claude e Gemini, com Go e Python
bash install.sh --tools claude,gemini --langs go,python /caminho/do/projeto

# instalar todas as ferramentas e todas as linguagens
bash install.sh --tools all --langs all /caminho/do/projeto

# instalar apenas Codex e Copilot, sem skills de linguagem
bash install.sh --tools codex,copilot /caminho/do/projeto
```

Valores aceitos:
- `--tools`: `claude`, `gemini`, `codex`, `copilot` ou `all`
- `--langs`: `go`, `node`, `python` ou `all`

### Dry Run

Para inspecionar o que seria criado sem alterar arquivos:

```bash
bash install.sh --dry-run /caminho/do/projeto
```

Combinável com modo não interativo:

```bash
bash install.sh --tools all --langs go --dry-run /caminho/do/projeto
```

Esse modo é útil quando você quer auditar a instalação antes de gravar arquivos em um repositório real.

### Modos de Instalação

O comportamento do instalador pode ser ajustado com variáveis de ambiente:

| Variável | Default | Efeito |
|----------|---------|--------|
| `LINK_MODE` | `symlink` | usa `symlink` para manter uma única fonte de verdade ou `copy` para instalar um snapshot local |
| `GENERATE_CONTEXTUAL_GOVERNANCE` | `1` | quando `1`, gera arquivos contextuais; quando `0`, copia os arquivos base sem personalização |
| `CODEX_SKILL_PROFILE` | `minimal` | controla o conjunto de skills em `.codex/config.toml`: `minimal` carrega o baseline operacional enxuto; `full` inclui também skills de planejamento e análise |
| `DETECT_TOOLCHAIN_MAX_DEPTH` | `4` | profundidade máxima para procurar manifests ao detectar fmt, test e lint |
| `DETECT_TOOLCHAIN_FOCUS_PATHS` | vazio | lista de paths afetados separados por vírgula para priorizar o workspace/package mais relevante |

Exemplos:

```bash
# instalação padrão com symlinks
bash install.sh /caminho/do/projeto

# instalação portável com cópia
LINK_MODE=copy bash install.sh /caminho/do/projeto

# instalação sem geração contextual
GENERATE_CONTEXTUAL_GOVERNANCE=0 bash install.sh /caminho/do/projeto

# Codex com perfil completo de skills
CODEX_SKILL_PROFILE=full bash install.sh --tools codex --langs all /caminho/do/projeto
```

## Como o Projeto Funciona

### 1. Fonte canônica

Toda lógica procedural fica em `.agents/skills/`. Cada skill possui seu próprio `SKILL.md`, referências carregadas sob demanda e, quando necessário, scripts auxiliares.

### 2. Adaptadores leves por ferramenta

Claude, Codex, Gemini e Copilot recebem apenas a camada mínima necessária para apontar para a skill correta. O objetivo é evitar divergência entre plataformas.

Para uso operacional, o baseline recomendado é:

- carregar `AGENTS.md`, `agent-governance` e apenas a skill operacional afetada;
- carregar skills de planejamento (`analyze-project`, `create-prd`, `create-technical-specification`, `create-tasks`) apenas sob demanda;
- manter o perfil `minimal` do Codex como default para reduzir custo de contexto.

### 3. Geração contextual de governança

Quando `GENERATE_CONTEXTUAL_GOVERNANCE=1`, o script `.agents/skills/analyze-project/scripts/generate-governance.sh` analisa o projeto-alvo e gera instruções mais precisas com base em:

- tipo de arquitetura detectado;
- stack principal;
- frameworks encontrados;
- ferramentas instaladas.

O gerador usa `detect-toolchain.sh` como fonte primária para comandos de validação quando esse detector consegue inferir fmt, test e lint do projeto, inclusive em manifests de subdiretórios.

Quando houver múltiplos manifests elegíveis, o detector pode priorizar o workspace afetado com `DETECT_TOOLCHAIN_FOCUS_PATHS` ou com o segundo argumento posicional do script.

### 4. Skills por linguagem

As skills base são sempre instaladas. Skills de implementação entram conforme a seleção de linguagem:

| Linguagem | Skills instaladas |
|-----------|-------------------|
| Go | `go-implementation`, `object-calisthenics-go` |
| Node.js / TypeScript | `node-implementation` |
| Python | `python-implementation` |

As skills base instaladas por padrão incluem:

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

Fluxo típico para adotar o projeto em outro repositório:

```bash
# 1. instalar a governança
bash install.sh /caminho/do/projeto

# 2. verificar o que foi gerado no projeto-alvo
ls -la /caminho/do/projeto

# 3. em instalações por cópia, checar defasagem futuramente
bash upgrade.sh --check /caminho/do/projeto
```

## Detecção Contextual

O gerador contextual usa heurísticas locais para reduzir falsos positivos.

### Tipos de arquitetura identificados

| Tipo | Sinais principais |
|------|-------------------|
| Monorepo | `go.work`, `pnpm-workspace.yaml`, `nx.json`, `turbo.json`, `lerna.json`, ou combinações como `apps/` + `packages/` |
| Monolito modular | `modules/`, `domains/` ou `internal/` com múltiplos subdiretórios |
| Microserviço | `Dockerfile` combinado com sinais de deploy isolado como `k8s/`, `helm/`, `deployments/`, `skaffold.yaml` ou `kustomization.yaml` |
| Monolito | fallback quando não há sinal forte suficiente |

### Stacks detectadas

Atualmente o gerador identifica, quando presentes na raiz ou em subdiretórios relevantes:

- Go;
- Node.js;
- Python;
- Java/Kotlin.

Para Go, o gerador também tenta inferir frameworks como `Gin`, `Echo`, `Fiber`, `gRPC` e `Connect`.

## Atualização de Skills

Quando a instalação é feita com `LINK_MODE=copy`, o projeto-alvo passa a ter uma cópia local das skills. Nesse caso, use `upgrade.sh` para verificar defasagem e aplicar atualizações.

### Verificar sem alterar

```bash
bash upgrade.sh --check /caminho/do/projeto
```

### Atualizar

```bash
bash upgrade.sh /caminho/do/projeto
```

O script compara o campo `version` do frontmatter de cada `SKILL.md` da fonte com a versão instalada no projeto-alvo.

Além da versão do `SKILL.md`, o `upgrade.sh` também detecta divergências de conteúdo por checksum e diferenças no diretório `references/` quando ele existe.

Após atualizar skills copiadas, o script também tenta:

- re-gerar adaptadores de Claude, GitHub e Gemini;
- re-gerar `.codex/config.toml` com base nas skills instaladas;
- re-gerar a governança contextual quando o projeto-alvo já possui `AGENTS.md`.

Se o projeto estiver usando symlinks, o script detecta isso e evita cópias desnecessárias.

### Filtrar por linguagem

Quando você quiser revisar ou atualizar apenas skills de linguagem específicas:

```bash
# verificar apenas skills de Go
bash upgrade.sh --check --langs go /caminho/do/projeto

# atualizar apenas skills de Node.js
bash upgrade.sh --langs node /caminho/do/projeto
```

Valores aceitos em `--langs`: `go`, `node`, `python`.

## Desenvolvimento

### Validações disponíveis

Este repositório possui múltiplos gates de validação para instalação, geração contextual, adaptadores, referências e orçamento de contexto:

```bash
# valida snapshots do gerador contextual
bash tests/test-generate-governance.sh

# valida o fluxo de instalação end-to-end
bash tests/test-install.sh

# valida scripts auxiliares
bash tests/test-scripts.sh

# valida upgrade e regeneração de adaptadores
bash tests/test-upgrade.sh

# valida orçamento de contexto e perfil minimal do Codex
bash tests/test-context-metrics.sh

# valida paridade de adaptadores gerados
bash tests/test-adapter-parity.sh

# valida referências declaradas nas skills
bash tests/test-skill-references.sh
```

### Atualização intencional de snapshots

Se houver mudança deliberada na saída do gerador contextual:

```bash
bash tests/test-generate-governance.sh --update
```

## Estrutura de Testes

O diretório `tests/fixtures/` contém projetos artificiais que exercitam os cenários principais de detecção:

- `go-microservice`
- `go-modular`
- `node-monorepo`
- `python-fastapi`
- `python-monorepo`
- `polyglot-monorepo`

Os snapshots esperados ficam em `tests/snapshots/` e são comparados contra o `AGENTS.md` gerado para cada fixture.

## Decisões Importantes de Design

### Portabilidade sem duplicação

O projeto separa claramente:

- a fonte de verdade procedural em `.agents/skills/`;
- as regras canônicas em `AGENTS.md`;
- os adaptadores específicos de cada ferramenta.

Isso reduz manutenção duplicada e preserva consistência entre CLIs.

### Menor carga de contexto

As referências das skills são carregadas sob demanda. Em vez de enviar grandes blocos fixos para toda tarefa, cada skill define quando ler regras de DDD, segurança, erros, testes ou padrões mais específicos.

### Atualização controlada

O campo `version` no frontmatter de cada `SKILL.md` permite comparar fonte e destino ao usar instalação por cópia. Isso fecha o ciclo de manutenção para projetos que não usam symlink.

## Limitações e Observações

- `install.sh` não permite instalar a governança no próprio repositório `ai-governance`;
- o diretório-alvo precisa existir antes da instalação;
- a geração contextual depende dos sinais encontrados localmente no projeto-alvo;
- quando nenhum padrão forte é detectado, o gerador assume um fallback conservador e registra isso no resultado.

## Fluxo Recomendado de Uso

Para adotar este projeto em outro repositório:

1. execute `bash install.sh /caminho/do/projeto`;
2. escolha as ferramentas de IA que o projeto realmente usa;
3. selecione apenas as linguagens relevantes para reduzir ruído;
4. revise os arquivos gerados no projeto-alvo;
5. se optar por `LINK_MODE=copy`, inclua `upgrade.sh --check` na manutenção periódica.

## Arquivos Principais

| Arquivo | Finalidade |
|--------|------------|
| `AGENTS.md` | regra canônica compartilhada entre agentes |
| `CLAUDE.md` | adaptador base para Claude Code |
| `GEMINI.md` | adaptador base para Gemini CLI |
| `install.sh` | instalação interativa no projeto-alvo |
| `upgrade.sh` | verificação e atualização de skills copiadas |

## Contribuição

Contribuições devem preservar o contrato entre a base canônica e os adaptadores. Ao propor mudanças:

1. altere a skill canônica primeiro, evitando replicar lógica nos adaptadores;
2. mantenha a menor mudança segura e coerente com o padrão atual;
3. atualize testes e snapshots quando a saída esperada mudar;
4. revise o README se o fluxo operacional do projeto mudar.

Comandos úteis para validar mudanças:

```bash
bash tests/test-generate-governance.sh
bash tests/test-install.sh
bash tests/test-context-metrics.sh
bash tests/test-scripts.sh
bash tests/test-upgrade.sh
```

## Roadmap Natural do Repositório

Este projeto tende a evoluir em quatro frentes principais:

- novas skills canônicas;
- refinamento das heurísticas de detecção contextual;
- melhoria dos adaptadores por ferramenta;
- fortalecimento de validações e testes de regressão.

## Resumo

`ai-governance` é uma base reutilizável para instalar, adaptar e manter governança de agentes de IA em projetos reais. O repositório combina fonte canônica única, adaptadores multiplataforma, geração contextual e estratégia de atualização, com foco em consistência operacional e baixo custo de manutenção.
