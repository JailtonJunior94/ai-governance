# Changelog

Todas as mudancas relevantes deste projeto serao documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e o versionamento segue [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [Unreleased]

### Added
- Baseline commitado `.budget-baseline.json` e script `scripts/check-budget-regression.sh` para detectar regressao de token budget contra metricas atuais
- Gate `scripts/check-task-completion.sh` para verificar que tasks marcadas como `done` possuem execution reports validos
- Utilitarios `scripts/lib/compute-spec-hash.sh` e `scripts/lib/validator-patterns.sh` para drift hash-based e headings localizados em validators
- Override `i18n/en/validator-patterns.sh` para validacao de headings em ingles
- Suites `tests/test-budget-regression.sh`, `tests/test-task-completion.sh`, `tests/test-template-contract.sh` e `tests/test-enforcement-fallback.sh`

### Changed
- Workflow reutilizavel `.github/workflows/governance-check.yml` ganhou gates configuraveis para budget regression e task completion
- Workflow `.github/workflows/test.yml` passou a executar as novas suites de governanca e configurar Go para `harness-execution`
- `execute-task` agora exige `check-task-completion.sh` antes de concluir tasks e `create-tasks` passou a incluir `spec-hash-prd` e `spec-hash-techspec`
- Templates e validators de evidencia foram alinhados para headings locale-safe e suporte a padroes carregados por locale

### Fixed
- Fixture `tests/fixtures/go-microservice` foi ajustado para permanecer self-contained sob `go vet` no harness

## [1.1.0] - 2026-04-20

### Added
- Skill `execute-task-all` para execucao sequencial de todas as tasks elegiveis de um `tasks/prd-<feature-slug>/tasks.md` com fluxo completo (execute-task, review, bugfix, evidencias)
- Script `scripts/loop-execute-tasks.sh`: orquestrador externo de loop de tasks, invocando o CLI de IA como processo separado por task (contexto limpo por iteracao)
- Utilitarios `scripts/lib/loop-report-generator.sh`, `report-parser.sh`, `task-selector.sh` e `tool-adapters.sh` para suporte ao loop de execucao
- Script `scripts/collect-efficacy-metrics.sh` para coleta de metricas de eficacia das execucoes
- Script `scripts/trace-requirements.sh` para rastreamento de requisitos em artefatos de tarefa
- Workflow `.github/workflows/governance-check.yml` para verificacao de governanca em CI
- Referencia `enforcement-fallback.md` com politica de fallback para enforcement entre ferramentas
- Diretorio `i18n/` com suporte a internacionalizacao (en e demais locais)
- Fixtures de teste para `go-domain`, `node-domain`, `python-domain` e `loop-tasks`
- Testes `test-loop-execute-tasks.sh`, `test-codex-e2e.sh`, `test-copilot-e2e.sh`, `test-harness-execution.sh` e `test-mutation.bats`
- `tests/lib/` com utilitarios compartilhados de teste
- `README-agent.md` com documentacao adicional voltada a agentes

### Changed
- Skills `agent-governance`, `go-implementation`, `node-implementation` e `python-implementation` atualizadas
- Referencias de governanca atualizadas: `ddd`, `enforcement-matrix`, `error-handling`, `messaging`, `observability`, `persistence`, `security-app`, `security`, `shared-architecture`, `shared-lifecycle`, `shared-patterns`, `shared-testing`, `testing`
- Template de relatorio de execucao de task (`task-execution-report-template.md`) atualizado
- Workflow de testes (`.github/workflows/test.yml`) atualizado
- Scripts `validate-bugfix-evidence.sh`, `validate-refactor-evidence.sh`, `validate-task-evidence.sh` e `check-rf-coverage.sh` atualizados
- `README.md` e `.gitignore` atualizados

## [1.0.1] - 2026-04-19

### Added
- Referencia `shared-patterns.md` com guidance cross-linguagem para Repository, Factory, DI, Error Handling e Value Objects
- Scripts `check-skill-prerequisites.sh`, `check-token-budget.sh` e `governance-wrapper.sh` para validar pre-condicoes e budget antes de invocar skills
- Suite de testes para evidence validators, mutacao de regras de governanca e integracao entre skills
- Documento `prompt_maturidade_projeto.md` para avaliacao de maturidade de projetos

### Changed
- `create-prd` agora exige `spec-version` no topo do PRD para rastrear evolucao do artefato
- `create-tasks` agora exige um grafo Mermaid de dependencias em `tasks.md`
- `check-spec-drift.sh` passa a comparar `spec-version` do PRD com `prd-version` em `tasks.md`
- Workflow de testes passa a executar as suites `evidence-validators`, `mutation` e `skill-integration`

### Fixed
- Validadores de evidencia foram movidos para `scripts/validators/` com wrappers canonicos em `.claude/scripts/`

## [1.0.0] - 2025-05-01

### Added
- Skills canonicas: agent-governance, go-implementation, node-implementation, python-implementation
- Skills processuais: create-prd, create-technical-specification, create-tasks, execute-task, review, refactor, bugfix
- Skill de revisao: object-calisthenics-go
- Skill de analise: analyze-project com geracao contextual de governanca
- Instalador multi-tool: Claude Code, Codex, Gemini CLI, Copilot CLI
- Upgrade e uninstall automatizados
- Hooks de enforcement: validate-governance.sh, validate-preload.sh
- Budget gates automatizados em CI (baselines, flows, skills, wrappers, referencias)
- Rastreabilidade PRD -> teste com validate-task-evidence.sh
- Controle de profundidade de invocacao (limite 2 niveis)
- Bug schema JSON com validacao
- 13 suites de teste com matrix CI (ubuntu + macOS)
- Schema version (governance-schema: 1.0.0)
- Enforcement matrix documentando capacidades por ferramenta
