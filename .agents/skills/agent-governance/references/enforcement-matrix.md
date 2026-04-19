# Enforcement Matrix

Tabela de capacidades de enforcement por ferramenta de IA suportada.

## Legenda

- **full**: suporte nativo com enforcement real (bloqueio ou alerta automatico)
- **partial**: suporte parcial (depende de cooperacao do agente ou configuracao manual)
- **none**: sem suporte nativo para a capacidade

## Matrix

| Capacidade | Claude Code | Codex | Gemini CLI | Copilot CLI |
|---|---|---|---|---|
| PreToolUse hook (bloqueio) | full | none | none | none |
| PostToolUse hook (alerta) | full | none | none | none |
| Contrato de carga base (AGENTS.md) | full | partial | partial | partial |
| Skills como SKILL.md | full | partial | partial | partial |
| Subagentes dedicados | full | none | none | full |
| Commands/slash commands | full | none | full | none |
| Carregamento lazy de referencias | full | partial | partial | partial |
| Budget gates (CI-time) | full | full | full | full |
| Validacao de evidencia (reports) | full | partial | partial | partial |
| Bug schema JSON validation | full | full | full | full |
| Controle de profundidade de invocacao | full | partial | partial | partial |
| Governanca contextual gerada | full | full | full | full |

## Notas

1. **Codex**: carrega skills via `[[skills.config]]` em `.codex/config.toml`, mas nao possui hooks para enforcement em tempo de edicao. A governanca depende do agente seguir as instrucoes de `AGENTS.md`.
2. **Gemini CLI**: commands em `.gemini/commands/*.toml` servem como ponto de entrada, mas nao ha mecanismo de hook para validar contrato de carga. O enforcement depende da instrucao em `GEMINI.md`.
3. **Copilot CLI**: `.github/agents/*.agent.md` definem agentes com contrato de carga inline, mas hooks de pre/pos-edicao nao existem. O enforcement depende da instrucao em `.github/copilot-instructions.md`.
4. **Budget gates** rodam em CI (GitHub Actions) e sao agnositcos a ferramenta — qualquer alteracao que estoure o budget sera bloqueada independentemente do agente que a produziu.
5. Capacidades marcadas como **partial** significam que a instrucao existe nos arquivos de configuracao da ferramenta, mas nao ha mecanismo tecnico para impedir que o agente ignore a instrucao.
