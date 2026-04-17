# Regras para Agentes de IA

Este diretorio centraliza regras para uso com agentes de IA em tarefas reais de analise, alteracao e validacao de codigo.

## Objetivo

Use estas instrucoes para manter consistencia, seguranca e qualidade ao trabalhar com codigo, configuracao, validacao e evolucao de sistemas.

## Arquitetura: {{TIPO_ARQUITETURA}}

{{DESCRICAO_ARQUITETURA}}

## Estrutura de Pastas

```
{{ARVORE_DIRETORIOS}}
```

## Padrao Arquitetural

{{PADRAO_ARQUITETURAL}}

### Fluxo de Dependencias

{{FLUXO_DEPENDENCIAS}}

## Modo de trabalho

1. Entender o contexto antes de editar qualquer arquivo.
2. Preferir a menor mudanca segura que resolva a causa raiz.
3. Preservar arquitetura, convencoes e fronteiras ja existentes no contexto analisado.
4. Nao introduzir abstracoes, camadas ou dependencias sem demanda concreta.
5. Atualizar ou adicionar testes quando houver mudanca de comportamento.
6. Rodar validacoes proporcionais a mudanca.
7. Registrar bloqueios e suposicoes explicitamente quando o contexto estiver incompleto.

## Diretrizes de Estrutura

1. Priorize entendimento do codigo e do contexto atual antes de propor refatoracoes.
2. Respeite padroes existentes de nomenclatura, organizacao e tratamento de erro.
3. Defina estrutura simples, evolutiva e com defaults explicitos.
4. Evite reescritas amplas quando uma alteracao localizada resolver o problema.
5. Estabeleca contratos, testes e comandos de validacao cedo quando eles ainda nao existirem.
6. Considere risco de regressao como restricao principal.
7. Evite overengineering disfarcado de arquitetura futura.

{{REGRAS_ARQUITETURA}}

## Regras por Linguagem

Para tarefas que alteram codigo, carregar a skill:

- `.agents/skills/agent-governance/SKILL.md`

{{REGRAS_LINGUAGEM}}

## Referencias da Skill

Ler conforme necessidade:

- `.agents/skills/agent-governance/references/ddd.md`
- `.agents/skills/agent-governance/references/error-handling.md`
- `.agents/skills/agent-governance/references/security.md`
- `.agents/skills/agent-governance/references/tests.md`

{{REFERENCIAS_LINGUAGEM}}

## Validacao

Antes de concluir uma alteracao:

{{COMANDOS_VALIDACAO}}

## Restricoes

1. Nao inventar contexto ausente.
2. Nao assumir versao de linguagem, framework ou runtime sem verificar.
3. Nao alterar comportamento publico sem deixar isso explicito.
4. Nao usar exemplos como copia cega; adaptar ao contexto real.

{{RESTRICOES_ARQUITETURA}}
