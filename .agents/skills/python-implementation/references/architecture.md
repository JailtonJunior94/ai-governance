> **Carregar quando:** estrutura de diretorios, DI, injecao de dependencias, layout de modulos — **Escopo:** organizacao de camadas, wiring, composicao — **~600tk**

# Arquitetura

## Objetivo
Preservar composicao simples, dependencias explicitas e fronteiras nitidas.

## Diretrizes
- Preferir modulos coesos e dependencias direcionadas.
- Manter regras de dominio fora de routers, handlers e infraestrutura.
- Concentrar orquestracao em camadas de aplicacao ou servicos explicitos.
- Evitar cross-module helpers que misturem dominio, IO e formatacao.
- Nomear modulos e classes pelo papel de negocio ou infraestrutura real.

## Injecao de Dependencias
- Preferir DI manual via construtores ou factory functions por padrao.
- Usar container de DI (dependency-injector, FastAPI Depends) apenas quando a arvore de dependencias justificar o custo de indireção.
- Construtor deve receber dependencias como parametros explicitos, nao buscar de variavel global ou service locator.

## Estrutura de Diretorios

### Projeto existente
- Seguir o layout ja adotado pelo projeto, mesmo que divirja dos exemplos abaixo.
- Nao reorganizar modulos para "alinhar com o padrao" sem demanda concreta.
- Novas adicoes devem respeitar a convencao local de nomes, profundidade e agrupamento.

### Projeto novo — layouts recomendados

#### API HTTP
```
src/
  domain/<aggregate>/         # entidades, value objects, regras
  application/<usecase>/      # orquestracao, interfaces de porta
  infra/<adapter>/            # repositories, clients, messaging
  api/                        # routers, DTOs, middlewares
```

#### Worker / Consumer
```
src/
  domain/
  application/
  infra/
  workers/                    # consumers, job handlers
```

### Regras comuns
- `src/` contem codigo de aplicacao; `tests/` contem testes.
- Evitar `utils/` ou `helpers/` que misturem responsabilidades.
- Nao criar pastas vazias preventivamente.
- Profundidade maxima pratica: `src/<camada>/<modulo>/`. Evitar sub-sub-modulos sem necessidade.
- `__init__.py` apenas quando necessario para o import.

## Sinais de excesso
- Modulo novo criado para uma unica funcao sem necessidade estrutural.
- ABC/Protocol sem consumidor alternativo.
- Pattern introduzido apenas para "preparar o futuro".
- Container de DI para projeto com menos de 10 dependencias raiz.
