# Regras para Agentes de IA

Este diretório centraliza regras para uso com agentes de IA em tarefas reais de análise, alteração e validação de código.

## Objetivo

Use estas instruções para manter consistência, segurança e qualidade ao trabalhar com código, configuração, validação e evolução de sistemas.

## Modo de trabalho

1. Entender o contexto antes de editar qualquer arquivo.
2. Preferir a menor mudança segura que resolva a causa raiz.
3. Preservar arquitetura, convenções e fronteiras já existentes no contexto analisado.
4. Não introduzir abstrações, camadas ou dependências sem demanda concreta.
5. Atualizar ou adicionar testes quando houver mudança de comportamento.
6. Rodar validações proporcionais à mudança.
7. Registrar bloqueios e suposições explicitamente quando o contexto estiver incompleto.

## Diretrizes de Estrutura

1. Priorize entendimento do código e do contexto atual antes de propor refatorações.
2. Respeite padrões existentes de nomenclatura, organização e tratamento de erro.
3. Defina estrutura simples, evolutiva e com defaults explícitos.
4. Evite reescritas amplas quando uma alteração localizada resolver o problema.
5. Estabeleça contratos, testes e comandos de validação cedo quando eles ainda não existirem.
6. Considere risco de regressão como restrição principal.
7. Evite overengineering disfarçado de arquitetura futura.

## Regras por Linguagem

Para tarefas que alteram código, carregar a skill:

- `.agents/skills/agent-governance/SKILL.md`

Para tarefas que alteram código Go, carregar também:

- `.agents/skills/go-implementation/SKILL.md`

Para tarefas de revisão ou refatoração incremental de design em Go guiadas por heurísticas de object calisthenics, carregar também:

- `.agents/skills/object-calisthenics-go/SKILL.md`

Para tarefas de correção de bugs com remediação e teste de regressão, carregar também:

- `.agents/skills/bugfix/SKILL.md`

Essa skill define:

- base obrigatória de governança para análise, alteração e validação
- carregamento sob demanda de regras de DDD, erros, segurança e testes
- critérios mínimos de preservação arquitetural, risco e validação proporcional

## Referências

Cada skill lista suas próprias referências em `references/` com gatilhos de carregamento no respectivo `SKILL.md`. Não duplicar a listagem aqui — consultar o SKILL.md da skill ativa para saber quais referências carregar e em que condição.

## Validação

Antes de concluir uma alteração:

1. Rodar formatter dos arquivos alterados.
2. Rodar primeiro testes direcionados.
3. Rodar testes mais amplos quando o custo for proporcional.
4. Rodar lint se o contexto oferecer esse passo.
5. Informar falhas com o comando exato e um diagnóstico curto.

## Restrições

1. Não inventar contexto ausente.
2. Não assumir versão de linguagem, framework ou runtime sem verificar.
3. Não alterar comportamento público sem deixar isso explícito.
4. Não usar exemplos como cópia cega; adaptar ao contexto real.
