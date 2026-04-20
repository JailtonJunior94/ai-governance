# Regras para Agentes de IA

Este diretório centraliza regras para análise, alteração e validação de código com agentes de IA.

## Objetivo

Use estas instruções para manter consistência, segurança e validação proporcional.

## Regras Gerais

1. Entender o contexto antes de editar qualquer arquivo.
2. Preferir a menor mudança segura que resolva a causa raiz.
3. Preservar arquitetura, convenções, fronteiras e comportamento público existente.
4. Não introduzir abstrações, camadas ou dependências sem demanda concreta.
5. Atualizar testes e rodar validações proporcionais quando houver risco de regressão.
6. Registrar bloqueios e suposições quando o contexto estiver incompleto.

## Contrato de carga base

Toda skill que altera código deve carregar como primeiro passo:

1. Ler este `AGENTS.md`.
2. Ler `.agents/skills/agent-governance/SKILL.md`.

A base cobre governança, referências sob demanda e critérios mínimos de risco e validação. Skills individuais devem declarar apenas cargas adicionais.

## Regras por Linguagem

- Go: `.agents/skills/go-implementation/SKILL.md`
- Node/TypeScript: `.agents/skills/node-implementation/SKILL.md`
- Python: `.agents/skills/python-implementation/SKILL.md`
- Refatoração incremental em Go com object calisthenics: `.agents/skills/object-calisthenics-go/SKILL.md`
- Correção de bugs com remediação e teste de regressão: `.agents/skills/bugfix/SKILL.md`

## Referências

Cada skill lista suas próprias referências em `references/` e seus gatilhos de carga. Não duplicar a listagem aqui.

## Validação

Antes de concluir uma alteração, seguir Etapa 4 de `.agents/skills/agent-governance/SKILL.md`.

## Restrições

1. Não inventar contexto ausente.
2. Não assumir versão de linguagem, framework ou runtime sem verificar.
3. Não alterar comportamento público sem deixar isso explícito.
4. Não usar exemplos como cópia cega; adaptar ao contexto real.
