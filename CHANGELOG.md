# Changelog

Todas as mudancas relevantes deste projeto serao documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e o versionamento segue [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [Unreleased]

### Added
- Suporte a `--ref` e `AI_GOVERNANCE_REF` para instalar ou atualizar a governanca a partir de tag, branch ou SHA explicitos
- Script `scripts/lib/source-ref.sh` para materializar snapshots limpos de refs Git
- Scripts `scripts/semver-next.sh`, `scripts/update-version.sh` e `scripts/update-changelog-release.sh` para decisao e materializacao de releases SemVer
- Workflow `.github/workflows/release-dry-run.yml` para validar releases sem efeitos colaterais
- Workflow `.github/workflows/release.yml` para criar commit e tag automatizados em `main`
- Gate de total de tokens por ferramenta (claude, gemini, codex, copilot) em `context-metrics.py`
- Testes de hooks em modo `fail` (GOVERNANCE_HOOK_MODE, GOVERNANCE_PRELOAD_MODE) no E2E
- Teste cross-tool upgrade (codex->claude, copilot->gemini) em `test-upgrade.sh`
- Gate de regressao: `analyze-project` ausente do perfil Codex em projetos alvo
- `tiktoken` instalado no CI para gate de drift real
- CHANGELOG.md

### Changed
- `install.sh` e `upgrade.sh` agora registram a fonte da governanca utilizada e rejeitam autorreferencia mesmo com ref explicita
- `README.md` documenta instalacao/upgrade por ref e o fluxo operacional de release

### Fixed
- `install.sh` força `LINK_MODE=copy` quando `--ref` e usado, evitando symlinks para snapshots temporarios
- Testes de install/upgrade cobrem refs invalidas, autorreferencia e restauracao de snapshots por tag
- `parse-hook-input.sh`: buffer aumentado de 8KB para 64KB para evitar truncamento
- Hooks `validate-governance.sh` e `validate-preload.sh`: stdin capturado antes do pipe
- `validate-task-evidence.sh`: `LC_ALL=C` para evitar falhas por locale
- `generate-gemini-commands.sh`: paths com espaco protegidos via `-print0`

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
