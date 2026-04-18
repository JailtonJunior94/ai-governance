# Regras para Agentes de IA

Este diretorio centraliza regras para uso com agentes de IA em tarefas reais de analise, alteracao e validacao de codigo.

## Objetivo

Use estas instrucoes para manter consistencia, seguranca e qualidade ao trabalhar com codigo, configuracao, validacao e evolucao de sistemas.

## Arquitetura: monolito

O projeto aparenta ser um monolito unico. A governanca deve privilegiar coesao local, limites de pacote claros e crescimento incremental da estrutura.

Stack detectada: Python.
Frameworks detectados: FastAPI.

## Estrutura de Pastas

```
.
pyproject.toml
src
src/__init__.py
src/main.py
tests
tests/__init__.py
```

## Padrao Arquitetural

Padrao arquitetural nao inferido com alta confianca; assumir composicao simples e dependencias explicitas.

### Fluxo de Dependencias

- Dependencias devem apontar de bordas externas para o nucleo do negocio.
- Detalhes de framework, IO e persistencia nao devem vazar para o centro do sistema.

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

1. Preservar coesao local e dependencia unidirecional entre packages.
2. Evitar helpers transversais que escondam regra de negocio ou IO.
3. Crescer a estrutura apenas quando o codigo atual ja nao comportar a mudanca com clareza.

## Regras por Linguagem

Para tarefas que alteram codigo, carregar a skill:

- `.agents/skills/agent-governance/SKILL.md`


Para tarefas que alteram codigo Python, carregar tambem:

- `.agents/skills/python-implementation/SKILL.md`

Para tarefas de correcao de bugs com remediacao e teste de regressao, carregar tambem:

- `.agents/skills/bugfix/SKILL.md`

### Composicao Multi-Linguagem

Em projetos com mais de uma linguagem (ex: monorepo Go + Node), carregar apenas a skill da linguagem afetada pela mudanca. Se a tarefa cruzar linguagens, carregar ambas e aplicar a validacao de cada stack nos arquivos correspondentes. Nao misturar convencoes de uma linguagem em arquivos de outra.

## Referencias

Cada skill lista suas proprias referencias em `references/` com gatilhos de carregamento no respectivo `SKILL.md`. Nao duplicar a listagem aqui — consultar o SKILL.md da skill ativa para saber quais referencias carregar e em que condicao.

## Validacao

Antes de concluir uma alteracao:

Seguir Etapa 4 de `.agents/skills/agent-governance/SKILL.md` como base canonica.

Comandos especificos do projeto (Python):
1. Rodar `ruff format .` ou `black .` conforme toolchain do projeto.
2. Rodar `pytest` ou o comando de teste equivalente do contexto.
3. Rodar `ruff check .` ou lint equivalente quando disponivel.

## Restricoes

1. Nao inventar contexto ausente.
2. Nao assumir versao de linguagem, framework ou runtime sem verificar.
3. Nao alterar comportamento publico sem deixar isso explicito.
4. Nao usar exemplos como copia cega; adaptar ao contexto real.


