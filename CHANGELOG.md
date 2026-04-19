# Changelog

Todas as mudancas relevantes deste projeto serao documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e o versionamento segue [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [Unreleased]

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
