# Principios de Arquitetura (Cross-Linguagem)

## Diretrizes
- Modulos/packages coesos com dependencias direcionadas.
- Regras de dominio fora de handlers, controllers e infraestrutura.
- Orquestracao em camadas de aplicacao ou servicos explicitos.
- Evitar cross-module helpers que misturem dominio, IO e formatacao.
- Nomear pelo papel de negocio ou infraestrutura real.

## Injecao de Dependencias
- DI manual via construtores ou factory functions por padrao.
- Container de DI apenas quando a arvore de dependencias justificar o custo.
- Construtor recebe dependencias como parametros explicitos, nao via global ou service locator.

## Projeto Existente
- Seguir layout ja adotado. Nao reorganizar para "alinhar com padrao" sem demanda.
- Novas adicoes respeitam convencao local de nomes, profundidade e agrupamento.

## Sinais de Excesso
- Modulo/package para uma unica funcao sem necessidade estrutural.
- Interface/ABC sem consumidor alternativo.
- Pattern introduzido apenas para "preparar o futuro".
- Container de DI para < 10 dependencias raiz.
