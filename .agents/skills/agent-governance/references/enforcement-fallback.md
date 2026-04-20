# Fallback de Enforcement para Ferramentas sem Hooks

<!-- @lang: all -->

Procedimentos compensatorios para Codex, Gemini CLI e Copilot CLI, que nao possuem hooks de pre/pos-edicao.

## Contexto

Apenas Claude Code possui enforcement mecanico (PreToolUse/PostToolUse hooks). Nas demais ferramentas, a governanca depende de cooperacao do modelo. Este documento define procedimentos compensatorios para reduzir o risco de desvio.

## Procedimentos por Ferramenta

### Codex

1. **Contrato de carga**: `AGENTS.md` e carregado automaticamente como instrucao de sessao. Verificar no inicio da tarefa se o modelo confirma ter lido `AGENTS.md` e `agent-governance/SKILL.md`.
2. **Skills**: registradas em `.codex/config.toml` via `[[skills.config]]`. O modelo deve ser instruido a listar skills carregadas antes de iniciar implementacao.
3. **Validacao manual**: ao final de cada tarefa, rodar os validators de evidencia localmente:
   - `bash .claude/scripts/validate-task-evidence.sh <report>`
   - `bash .claude/scripts/validate-bugfix-evidence.sh <report>`
   - `bash .claude/scripts/validate-refactor-evidence.sh <report>`
4. **Budget gate**: usar `bash scripts/check-token-budget.sh` antes de submeter contexto extenso.
5. **Profundidade**: incluir instrucao explicita no prompt limitando cadeia a 2 niveis.

### Gemini CLI

1. **Contrato de carga**: `GEMINI.md` deve conter instrucao explicita para ler `AGENTS.md` e `agent-governance/SKILL.md`. Verificar com `@agent-governance` no inicio da sessao.
2. **Commands**: `.gemini/commands/*.toml` servem como ponto de entrada. Instruir o modelo a usar `@<command>` para invocar skills em vez de operar livremente.
3. **Validacao manual**: identico ao Codex — rodar validators localmente ao final de cada tarefa.
4. **Checklist pre-merge**: antes de aceitar qualquer alteracao produzida por Gemini CLI, verificar:
   - [ ] `AGENTS.md` foi consultado (evidencia no output)
   - [ ] Skill de linguagem carregada quando aplicavel
   - [ ] Testes executados e passando
   - [ ] Lint executado e passando
   - [ ] Execution report gerado e validado
5. **Profundidade**: Gemini CLI nao possui controle nativo. Instruir no prompt: "Nao encadeie mais de 2 skills em sequencia."

### Copilot CLI

1. **Contrato de carga**: `.github/copilot-instructions.md` e carregado automaticamente. Agents em `.github/agents/*.agent.md` incluem contrato de carga inline.
2. **Agents**: usar agents dedicados (`@prd-writer`, `@task-executor`, etc.) em vez de prompts abertos.
3. **Validacao manual**: identico ao Codex — rodar validators localmente ao final de cada tarefa.
4. **Checklist pre-merge**: identico ao Gemini CLI.
5. **Profundidade**: agents do Copilot nao possuem controle de profundidade. Instruir no prompt e monitorar output.

## Gate CI Compensatorio

Para todas as ferramentas sem hooks, o CI deve servir como gate de ultima instancia:

1. **Budget gate**: `scripts/check-token-budget.sh` no CI valida que o contexto carregado nao excede o limite.
2. **Spec drift**: `scripts/check-spec-drift.sh` no CI detecta se PRD/TechSpec foram mutados sem atualizacao de tasks.
3. **Evidence validation**: validators de evidencia podem ser executados como step de CI em PRs que incluam execution reports.
4. **Governance lint**: `tests/test-governance-lint.sh` valida integridade dos arquivos de governanca em qualquer PR.

## Checklist Universal (todas as ferramentas sem hooks)

Antes de aceitar output de qualquer ferramenta sem enforcement mecanico:

- [ ] Modelo confirmou leitura de `AGENTS.md`
- [ ] Skill de linguagem carregada (se codigo foi alterado)
- [ ] Referencias carregadas sob demanda (evidencia no output)
- [ ] Testes executados com resultado explicito
- [ ] Lint executado com resultado explicito
- [ ] Execution report gerado
- [ ] Execution report validado por validator
- [ ] Nenhuma edicao direta em arquivos de governanca

## Proibido

- Aceitar output sem verificar evidencia de contrato de carga.
- Dispensar validacao manual "porque o modelo disse que seguiu as regras".
- Confiar em output de modelo como substituto para execucao real de testes e lint.
