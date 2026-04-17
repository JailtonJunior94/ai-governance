# Claude Code

Use `AGENTS.md` como fonte canonica das regras deste repositorio.

## Instrucoes

1. Ler `AGENTS.md` no inicio da sessao.
2. `.claude/skills/` sao symlinks para `.agents/skills/` — a fonte de verdade e sempre `.agents/skills/`.
3. `.claude/agents/` sao wrappers leves que delegam para a habilidade canonica.
4. Carregar referencias adicionais apenas quando a tarefa exigir.
5. Preservar estilo, arquitetura e fronteiras existentes antes de propor mudancas.
6. Validar mudancas com comandos proporcionais ao risco.

{{SECAO_STACK}}
