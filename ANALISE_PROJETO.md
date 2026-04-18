# Analise de Qualidade — ai-governance

Data: 2026-04-17
Pipeline validado: PRD -> TechSpec -> Tasks -> Execute -> Review -> (Bugfix) -> Review/Refactor
Revisao: R2 (atualiza a analise R1, reclassifica achados corrigidos e adiciona novos)

---

## 0. Status de Correcoes da Analise R1

| # R1 | Descricao | Status |
|------|-----------|--------|
| A-01 | `.gitignore` ausente | CORRIGIDO (unstaged) |
| A-02 | Duplicacao `.claude/agents/` vs `.github/agents/` | PERMANECE (ver N-01) |
| A-03 | `install.sh` SKILLS incompleto | CORRIGIDO (unstaged) |
| A-04 | Symlinks `.claude/skills/` faltando | CORRIGIDO (unstaged) |
| A-05 | `build_language_references` incompleto | CORRIGIDO (unstaged) |
| A-06 | `.codex/config.toml` inconsistente | CORRIGIDO (unstaged) |
| A-07 | Copilot agents sem campo `skills:` | PERMANECE (ver N-02) |
| A-08 | `validate-task-evidence.sh` falso positivo | CORRIGIDO (unstaged) |
| A-09 | `validate-bug-input.py` sem check de arquivo | PARCIAL — JSON error handling adicionado, mas `file` continua sem check de existencia (ver N-03) |
| A-10 | `install.sh` validacao de diretorio | CORRIGIDO (unstaged) |
| A-11 | `generate-governance.sh` validacao de diretorio | PERMANECE (ver N-04) |
| A-12 | `install.sh` word splitting `$selection` | CORRIGIDO (unstaged) |
| A-13 | Duplicacao `tests.md` entre skills | CORRIGIDO (unstaged) — agent-governance agora delega para go-implementation |
| A-14 | Arquivos de referencia grandes | PERMANECE (ver N-05) |
| A-15 | Copilot install suprimia erros com `2>/dev/null` | CORRIGIDO (unstaged) |
| A-16 | `agents-template.md` sem bugfix/OC | CORRIGIDO (unstaged) — bugfix e OC agora referenciados |
| A-17 | AGENTS.md vs install.sh divergentes | CORRIGIDO (unstaged) |
| A-18 | Alto volume de wrappers | PERMANECE (ver N-06) |
| A-19 | 3 templates separados por ferramenta | CORRIGIDO (unstaged) — consolidado em `ai-tool-template.md` |
| A-20 | `mkdir`/`ln` sem check de sucesso | PERMANECE (risco mitigado por `set -e`) |
| A-21 | `install.sh` sem check de escrita | CORRIGIDO (unstaged) |
| A-22 | Formato de evidencias nao definido | PERMANECE (minor) |
| A-23 | Default "monolito" silencioso | CORRIGIDO (unstaged) — agora emite AVISO para stderr |
| A-24 | Resolucao de conflito OC vs go-implementation ambigua | MELHORADO (unstaged) — exemplo pratico adicionado |

**Resumo R1:** 15 corrigidos, 3 parciais/melhorados, 6 permanecem.

---

## 1. Tabela de Achados Atuais

### 1.1 Achados que Permanecem da R1

| # | Categoria | Severidade | Local | Descricao | Impacto |
|---|-----------|-----------|-------|-----------|---------|
| P-01 | Duplicacao | major | `.claude/agents/*.md` vs `.github/agents/*.agent.md` | 7 pares de arquivos com conteudo quase identico. Diferem apenas no formato de frontmatter (`skills:` vs ausencia) e no nome do campo `name` (ingles vs PT-BR). | Manutencao duplicada: corrigir um agent exige editar 2 arquivos em 2 diretorios. |
| P-02 | Lacuna | major | `.github/agents/*.agent.md` | Os 7 agents do Copilot nao possuem campo `skills:` no frontmatter. Nao ha mecanismo de vinculacao entre agent e skill; o diretorio `.github/skills/` criado pelo `install.sh:148` fica orfao. | Copilot nao tem como carregar skills automaticamente; o fluxo funciona apenas por instrucao textual. |
| P-03 | Economia | minor | `go-implementation/references/` | `implementation-examples.md` (344 linhas) e `design-patterns.md` (304 linhas) sao os dois maiores arquivos do projeto. Carregados inteiros pelo agente mesmo para tarefas simples. | Consumo desproporcional de tokens. Um exemplo de 5 linhas exige carregar 344 linhas. |
| P-04 | Economia | minor | Wrapper/adapter files | 21 arquivos de wrapper (7 `.claude/agents/`, 7 `.github/agents/`, 7 `.gemini/commands/`) com conteudo minimo (~3-8 linhas uteis). | Custo de manutencao linear com numero de ferramentas. Cada nova skill exige editar 3+ locais. |
| P-05 | Determinismo | minor | `analyze-project/SKILL.md:21-22` | "Registrar a classificacao e as evidencias encontradas" — nao define formato, nivel de detalhe ou destino do registro. | Agentes produzem saidas inconsistentes para a mesma etapa. |

### 1.2 Achados Novos (R2)

| # | Categoria | Severidade | Local | Descricao | Impacto |
|---|-----------|-----------|-------|-----------|---------|
| N-01 | Lacuna | critical | `.claude/agents/`, `.github/agents/`, `.gemini/commands/` | 4 skills nao possuem wrappers de agent/command em nenhuma ferramenta: `agent-governance`, `go-implementation`, `object-calisthenics-go`, `bugfix`. Os symlinks em `.claude/skills/` foram criados, mas sem o agent correspondente em `.claude/agents/`, o fluxo de subagente do Claude Code nao consegue delegar automaticamente. Gemini nao tem commands para essas 4 skills. | Pipeline de subagentes incompleto. A skill `bugfix` — peca critica do ciclo Review->Bugfix — nao tem agent/command em nenhuma ferramenta. Skills de governanca base (`agent-governance`, `go-implementation`) tambem ficam sem wrapper. |
| N-02 | Inconsistencia | major | `.claude/settings.local.json` | Todas as 6 entradas de `permissions.allow` referenciam paths absolutos de um diretorio diferente: `/Users/jailtonjunior/Git/rules/`. O diretorio atual do projeto e `/Users/jailtonjunior/Git/ai-governance/`. | Nenhuma permissao listada tera efeito — os paths nunca serao correspondidos. O arquivo e ativo mas inutil, e pode confundir quem revisar as permissoes do projeto. |
| N-03 | Lacuna | major | `generate-governance.sh:108-131` | `detect_primary_stack` detecta apenas Go, Node.js, Python e Java/Kotlin. Faltam Rust (`Cargo.toml`) e C#/.NET (`*.csproj`, `*.sln`), apesar de ambos serem documentados na Etapa 3 e Etapa 8 do `analyze-project/SKILL.md` e terem comandos de validacao definidos (linhas 93-97 do SKILL.md). | Projetos Rust e C#/.NET serao classificados como "stack principal nao detectada automaticamente". O AGENTS.md gerado nao incluira comandos de validacao corretos para essas stacks. |
| N-04 | Lacuna | major | `generate-governance.sh:77-106` | `detect_frameworks` detecta apenas frameworks Go (Gin, Echo, Fiber, gRPC, Connect). A Etapa 3 do `analyze-project/SKILL.md` documenta deteccao para Express, NestJS, FastAPI, Django, Spring Boot e ASP.NET — nenhum esta implementado no script. | Projetos Node/Python/Java sempre reportam "nenhum framework dominante identificado" mesmo quando usam frameworks comuns. |
| N-05 | Inconsistencia | minor | `generate-governance.sh:10` | `generate-governance.sh` ainda usa `PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"` sem validacao previa de existencia, diferente do `install.sh` que agora valida explicitamente. O `install.sh` chama o script de governanca (linha 159) e ja valida antes, mas o script tambem pode ser chamado diretamente. | Mensagem de erro crptica do shell em vez de mensagem explicita quando chamado diretamente com diretorio invalido. |
| N-06 | Falso Positivo | minor | `validate-bug-input.py:40-42` | Campo `file` do bug e validado apenas como "string nao vazia". Aceita paths como `""`, `"asdf"` ou `"/tmp/inexistente.go"` sem verificar existencia. | Bugs podem referenciar arquivos inexistentes e o validador reporta "SUCCESS". O valor informacional do script cai. |
| N-07 | Robustez | minor | `techspec-template.md:138` | Referencia hardcoded `.claude/rules/` — um path especifico do Claude Code — dentro de um template que deveria ser agnostico de ferramenta. | Projetos que usam apenas Gemini ou Copilot recebem uma instrucao que aponta para um diretorio que pode nao existir. |
| N-08 | Robustez | minor | `object-calisthenics-go/scripts/list-go-files.sh:9` | Usa `mapfile` (bash 4+). O macOS inclui bash 3.2 como default em `/bin/bash`. O shebang `#!/usr/bin/env bash` pode resolver para bash 3.2 em maquinas sem Homebrew. | Script falha silenciosamente ou com erro obscuro em macOS sem bash moderno instalado. |
| N-09 | Lacuna | minor | `generate-governance.sh:204-341` | `build_architecture_restrictions` retorna string vazia (`printf ''`) para `monolito` e `monolito modular`. O placeholder `{{RESTRICOES_ARQUITETURA}}` permanece como linha vazia no final do AGENTS.md gerado. | AGENTS.md gerado tem trailing whitespace sem conteudo util. Esteticamente menor, mas indica que o template nao limpa placeholders nao preenchidos. |
| N-10 | Determinismo | minor | `generate-governance.sh:356-371` | `render_template` usa substituicao bash `${content//\{\{$key\}\}/$value}`. Se `$value` contiver `{{` (ex: um placeholder nao resolvido de outra variavel), a substituicao pode corromper o template resultante. | Baixo risco atual (valores sao internos), mas fragilidade para extensoes futuras do gerador. |
| N-11 | Lacuna | minor | `generate-governance.sh:53-75` | `detect_architectural_pattern` testa `has_any_files "internal"` como ultimo fallback generico. Qualquer projeto Go com `internal/` (pratica padrao) sera classificado como "packages internos coesos, com estrutura orientada por dominio ou componente" — mesmo que nao seja. | Classificacao de padrao arquitetural pode ser incorreta para projetos Go simples que usam `internal/` apenas para encapsulamento de packages. |
| N-12 | Lacuna | minor | Projeto em geral | Nao ha nenhum teste automatizado para os scripts do projeto (`install.sh`, `generate-governance.sh`, `validate-task-evidence.sh`, `validate-bug-input.py`, `verify-go-mod.sh`, `list-go-files.sh`). As unicas validacoes sao execucoes manuais. | Regressoes nos scripts so serao detectadas em uso real. Mudancas como as 15 correcoes da R1 poderiam ter introduzido bugs sem deteccao. |
| N-13 | Inconsistencia | minor | `.github/agents/*.agent.md` | Nomes de agents em PT-BR ("Redator de PRD", "Revisor", "Planejador de Tarefas") divergem dos nomes em ingles dos `.claude/agents/` correspondentes ("prd-writer", "reviewer", "task-planner"). | Inconsistencia de nomenclatura entre ferramentas para o mesmo papel funcional. |

---

## 2. Recomendacoes Estrategicas

### 2.1 Robustez (Alta Prioridade)

| Prioridade | Recomendacao | Justificativa | Achados |
|-----------|-------------|---------------|---------|
| Critica | Criar wrappers de agent/command para as 4 skills faltantes (`agent-governance`, `go-implementation`, `object-calisthenics-go`, `bugfix`) em `.claude/agents/`, `.github/agents/` e `.gemini/commands/`. | O pipeline `Review -> Bugfix` e a governanca base ficam sem ponto de entrada para subagentes. Sem o agent `bugfix`, o ciclo de remediacao documentado no pipeline nao funciona via delegacao automatica. | N-01 |
| Alta | Corrigir ou remover `.claude/settings.local.json` — todas as permissoes apontam para `/Users/jailtonjunior/Git/rules/` que nao e o diretorio do projeto. | Arquivo ativo mas sem efeito. Pode causar confusao ou falsa sensacao de seguranca nas permissoes. | N-02 |
| Alta | Implementar deteccao de Rust (`Cargo.toml`) e C#/.NET (`*.csproj`, `*.sln`) em `detect_primary_stack`. | O SKILL.md promete deteccao dessas stacks (Etapa 3) e comandos de validacao (Etapa 8), mas o script nao implementa. Discrepancia entre documentacao e comportamento real. | N-03 |
| Media | Implementar deteccao de frameworks para Node.js (Express, NestJS), Python (FastAPI, Django) e Java (Spring Boot) em `detect_frameworks`. | Alinhamento com a especificacao do SKILL.md. Projetos nao-Go sempre reportam "nenhum framework" mesmo usando frameworks conhecidos. | N-04 |
| Media | Adicionar validacao de existencia de diretorio em `generate-governance.sh` antes de `cd "$PROJECT_DIR"`, com mensagem explicita (mesmo padrao do `install.sh` corrigido). | O script pode ser chamado diretamente fora do `install.sh`. | N-05 |
| Baixa | Substituir `mapfile` em `list-go-files.sh` por alternativa compativel com bash 3.2 (ex: `while IFS= read -r`). | Compatibilidade com macOS default. | N-08 |
| Baixa | Remover referencia hardcoded `.claude/rules/` do `techspec-template.md:138`, substituir por referencia generica a `.agents/skills/agent-governance/references/`. | Template deve ser agnostico de ferramenta. | N-07 |

### 2.2 Economia (Performance/Custo)

| Prioridade | Recomendacao | Justificativa | Achados |
|-----------|-------------|---------------|---------|
| Alta | Dividir `implementation-examples.md` (344 linhas) por dominio (ex: `examples-constructors.md`, `examples-api.md`, `examples-persistence.md`). Mesmo para `design-patterns.md` (304 linhas) — separar por categoria (creational, structural, behavioral). | Agentes carregam o arquivo inteiro via `Ler references/implementation-examples.md` mesmo para uma unica linha. Divisao permite carregamento seletivo e reduz custo de tokens por chamada. | P-03 |
| Media | Avaliar geracao automatica dos wrappers de agent/command a partir de metadados das skills (frontmatter `name` e `description`). Um script `generate-wrappers.sh` eliminaria 21+ arquivos de manutencao manual e garantiria que novas skills ganhem suporte multi-ferramenta automaticamente. | Cada skill nova exige criar 3 arquivos de wrapper manualmente. O problema tende a piorar com a adicao de novas skills ou ferramentas. | P-04, N-01 |
| Baixa | Consolidar os 7 pares `.claude/agents/*.md` + `.github/agents/*.agent.md` em uma unica fonte de metadados por skill, gerando os wrappers por ferramenta de forma automatica. | Reduz duplicacao e risco de divergencia. | P-01 |

### 2.3 Determinismo

| Prioridade | Recomendacao | Justificativa | Achados |
|-----------|-------------|---------------|---------|
| Media | Refinar `detect_architectural_pattern` para nao classificar `internal/` generico como "orientado por dominio". Considerar verificar se `internal/` tem subdiretorios com nomes de dominio ou se e apenas encapsulamento de packages. | Projetos Go com `internal/` padrao recebem classificacao potencialmente incorreta. | N-11 |
| Media | Limpar placeholders nao preenchidos no template — `render_template` poderia remover linhas que contenham `{{...}}` residuais apos todas as substituicoes. | Evita conteudo vazio ou placeholders nao resolvidos no AGENTS.md gerado. | N-09, N-10 |
| Baixa | Definir formato explicito para "evidencias" na Etapa 2 do `analyze-project/SKILL.md` — especificar se e tabela, bullet list ou secao markdown com campos fixos. | Reduz variancia na saida dos agentes. | P-05 |

### 2.4 Qualidade de Engenharia

| Prioridade | Recomendacao | Justificativa | Achados |
|-----------|-------------|---------------|---------|
| Media | Adicionar testes automatizados minimos para os scripts criticos: `install.sh` (teste de instalacao em diretorio temporario), `generate-governance.sh` (teste de output para projeto Go e projeto Node), `validate-task-evidence.sh` (teste com relatorio valido e invalido). | 6 scripts sem nenhum teste. As 15 correcoes da R1 foram aplicadas sem rede de seguranca. | N-12 |
| Baixa | Padronizar nomenclatura dos agents entre ferramentas — usar nomes em ingles (consistente com os nomes de skill) ou em PT-BR, mas nao misturar. | Copilot usa PT-BR, Claude usa ingles, para a mesma funcao. | N-13 |

### 2.5 Commit Pendente

Todas as 15 correcoes da R1 estao em estado `unstaged` — nenhuma foi commitada. Alem disso:
- `.gitignore` esta como arquivo nao rastreado (`??`)
- `ANALISE_PROJETO.md` esta como arquivo nao rastreado (`??`)
- 3 templates antigos (`claude-template.md`, `gemini-template.md`, `copilot-template.md`) estao marcados como deletados mas nao staged
- 1 template novo (`ai-tool-template.md`) esta como nao rastreado
- `.pyc` foi removido do index (staged deletion) via commit anterior, mas o arquivo `__pycache__/` pode reaparecer sem `.gitignore` commitado

**Risco:** se a working tree for descartada (ex: `git checkout .`), todas as 15 correcoes serao perdidas.

---

## 3. Pipeline: PRD -> TechSpec -> Tasks -> Execute -> Review -> Bugfix -> Refactor

| Etapa | Status | Observacao |
|-------|--------|-----------|
| PRD | OK | Skill `create-prd` completa com template, procedimentos e tratamento de erros. |
| TechSpec | OK com ressalva | Skill completa, mas `techspec-template.md:138` referencia `.claude/rules/` diretamente (N-07). |
| Tasks | OK | Skill `create-tasks` com limite de 10 tarefas, estados canonicos e dependencias. |
| Execute | OK | Skill `execute-task` com validacao de evidencias e integracao com review e bugfix. |
| Review | OK | Skill `review` com veredito canonico e emissao de bugs no formato para bugfix. |
| Bugfix | PARCIAL | Skill existe e esta bem definida. Symlink em `.claude/skills/` foi criado (correcao R1). Entrada no `.codex/config.toml` foi adicionada (correcao R1). **Porem**: nao tem agent em `.claude/agents/`, `.github/agents/`, nem command em `.gemini/commands/` (N-01). Pipeline de subagente nao funciona sem o wrapper. |
| Refactor | OK | Skill `refactor` com modos advisory/execution e integracao com review e bugfix. |

---

## 4. Seguranca

| Achado | Status |
|--------|--------|
| Nao ha segredos hardcoded no repositorio. | OK |
| Scripts usam `set -euo pipefail`. | OK |
| Nao ha `eval` ou shell injection nos scripts. | OK |
| `validate-bug-input.py` usa `json.load` com `argparse` (sem concatenacao insegura). | OK |
| `render_template` usa substituicao bash que pode ser fragil com valores contendo `{{` (N-10). | ATENCAO (risco baixo atual) |
| `.claude/settings.local.json` aponta para paths de outro diretorio (N-02). | ATENCAO (sem risco de seguranca, mas ineficaz) |
| `.gitignore` criado mas nao commitado — `.pyc` pode reaparecer. | ATENCAO |

---

## 5. Resumo Executivo

O projeto `ai-governance` evoluiu significativamente desde a analise R1: **15 dos 24 achados originais foram corrigidos** em mudancas ainda nao commitadas. Os destaques sao a consolidacao de templates (3 -> 1 parametrizado), a inclusao de todas as 11 skills no `install.sh` e `.codex/config.toml`, a criacao do `.gitignore`, e a melhoria do `validate-task-evidence.sh` para exigir headings Markdown.

**Porem, a correcao mais critica esta incompleta:** a skill `bugfix` ganhou symlink e entrada no Codex, mas **continua sem agent wrapper em nenhuma ferramenta** (N-01). O mesmo vale para `agent-governance`, `go-implementation` e `object-calisthenics-go`. Sem esses wrappers, o pipeline de subagentes documentado no projeto nao funciona para delegacao automatica.

**Novo achado critico:** o `.claude/settings.local.json` aponta para um diretorio diferente (`/Users/jailtonjunior/Git/rules/`), tornando todas as permissoes configuradas ineficazes (N-02).

**Risco imediato:** nenhuma das correcoes esta commitada. Um `git checkout .` descartaria todo o trabalho.

**Contagem atual: 18 achados** (1 critical, 4 major, 13 minor)
- 5 permanecem da R1 (1 major, 4 minor)
- 13 novos (1 critical, 3 major, 9 minor)

**Top 5 acoes de maior impacto:**

1. **Commitar as 15 correcoes da R1** — proteger o trabalho ja realizado.
2. **Criar wrappers de agent/command para as 4 skills faltantes** — completar o pipeline de subagentes em todas as ferramentas (N-01).
3. **Corrigir `.claude/settings.local.json`** — atualizar paths para o diretorio correto ou remover o arquivo (N-02).
4. **Implementar deteccao de Rust/C#/.NET e frameworks nao-Go** — alinhar o script com a documentacao do SKILL.md (N-03, N-04).
5. **Dividir `implementation-examples.md` e `design-patterns.md`** — reduzir custo de tokens por chamada de agente (P-03).
