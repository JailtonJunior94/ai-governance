# Regras para Agentes de IA

Este diretorio centraliza regras para uso com agentes de IA em tarefas reais de analise, alteracao e validacao de codigo.

## Objetivo

Use estas instrucoes para manter consistencia, seguranca e qualidade ao trabalhar com codigo, configuracao, validacao e evolucao de sistemas.

## Arquitetura: microservico

O projeto aparenta ser um microservico independente, com foco em contrato de API, inicializacao, dependencias externas e seguranca operacional. A governanca deve preservar o escopo do servico e o seu deploy independente.

Stack detectada: Go.
Frameworks detectados: Echo,gRPC.

## Estrutura de Pastas

```
.
Dockerfile
cmd
cmd/server
cmd/server/main.go
go.mod
internal
internal/order
internal/order/service.go
k8s
k8s/deployment.yaml
```

## Padrao Arquitetural

Predominio de packages internos coesos, com estrutura orientada por dominio ou componente.

### Fluxo de Dependencias

- Transporte e adapters devem depender de casos de uso ou servicos explicitos, nao do contrario.
- Dominio nao deve conhecer detalhes de HTTP, banco, filas, serializacao ou drivers.
- Infraestrutura pode implementar contratos consumidos pela aplicacao, preservando dependencia para dentro.

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

## Regras por Arquitetura

1. Preservar contratos publicados e compatibilidade de integracao.
2. Manter inicializacao, observabilidade e shutdown como parte do comportamento do servico.
3. Nao acoplar o servico a convencoes de outros servicos sem contrato explicito.

## Regras por Linguagem

Para tarefas que alteram codigo, carregar a skill:

- `.agents/skills/agent-governance/SKILL.md`

Para tarefas que alteram codigo Go, carregar tambem:

- `.agents/skills/go-implementation/SKILL.md`

Para tarefas de revisao ou refatoracao incremental de design em Go guiadas por heuristicas de object calisthenics, carregar tambem:

- `.agents/skills/object-calisthenics-go/SKILL.md`

Para tarefas de correcao de bugs com remediacao e teste de regressao, carregar tambem:

- `.agents/skills/bugfix/SKILL.md`

### Composicao Multi-Linguagem

Em projetos com mais de uma linguagem (ex: monorepo Go + Node), carregar apenas a skill da linguagem afetada pela mudanca. Se a tarefa cruzar linguagens, carregar ambas e aplicar a validacao de cada stack nos arquivos correspondentes. Nao misturar convencoes de uma linguagem em arquivos de outra.

## Referencias

Cada skill lista suas proprias referencias em `references/` com gatilhos de carregamento no respectivo `SKILL.md`. Nao duplicar a listagem aqui — consultar o SKILL.md da skill ativa para saber quais referencias carregar e em que condicao.

## Validacao

Antes de concluir uma alteracao:

Seguir Etapa 4 de `.agents/skills/agent-governance/SKILL.md` como base canonica.

Comandos especificos do projeto (Go):
1. Rodar `gofmt` nos arquivos Go alterados.
3. Rodar primeiro testes direcionados e depois `go test ./...` quando o custo for proporcional.
4. Rodar `go vet ./...` quando esse passo fizer parte do gate do projeto.

## Restricoes

1. Nao inventar contexto ausente.
2. Nao assumir versao de linguagem, framework ou runtime sem verificar.
3. Nao alterar comportamento publico sem deixar isso explicito.
4. Nao usar exemplos como copia cega; adaptar ao contexto real.

5. Nao alterar contratos externos, readiness, observabilidade ou semantica operacional sem explicitar a mudanca.
