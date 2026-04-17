# Arquitetura

## Objetivo
Preservar composição simples, dependências explícitas e fronteiras nítidas.

## Diretrizes
- Preferir packages coesos e dependências direcionadas.
- Manter regras de domínio fora de adapters, handlers e infraestrutura.
- Concentrar orquestração em camadas de aplicação ou serviços explícitos.
- Evitar cross-package helpers que misturem domínio, IO e formatação.
- Nomear tipos e funções pelo papel de negócio ou infraestrutura real.

## Injeção de Dependências
- Preferir DI manual via construtores por padrão.
- Usar container de DI (Wire, fx) apenas quando a árvore de dependências justificar o custo de indireção.
- Construtor deve receber dependências como parâmetros explícitos, não buscar de variável global ou service locator.

## Estrutura de Diretórios

### Projeto existente
- Seguir o layout já adotado pelo projeto, mesmo que divirja dos exemplos abaixo.
- Não reorganizar pacotes para "alinhar com o padrão" sem demanda concreta.
- Novas adições devem respeitar a convenção local de nomes, profundidade e agrupamento.
- Se o projeto misturar convenções, manter consistência dentro do módulo ou pacote alterado.

### Projeto novo — layouts recomendados

#### Serviço HTTP/gRPC
```
cmd/<service>/main.go
internal/
  domain/<aggregate>/         # entidades, value objects, regras
  application/<usecase>/      # orquestração, interfaces de porta
  infra/<adapter>/            # repositórios, clients, messaging
  handler/                    # HTTP/gRPC handlers, DTOs, middlewares
```

#### Worker / Consumer
```
cmd/<worker>/main.go
internal/
  domain/
  application/
  infra/
```

#### Monolito modular
```
cmd/server/main.go
internal/
  <module>/
    domain/
    application/
    infra/
    handler/
```

### Regras comuns
- `cmd/` contém apenas bootstrap: config, DI, wiring e start do servidor ou worker.
- `internal/` impede importação externa e é o default para código de aplicação.
- `pkg/` apenas para código genuinamente reutilizável entre repositórios — na dúvida, não criar.
- Não criar pastas vazias preventivamente; adicionar quando o primeiro arquivo justificar.
- Profundidade máxima prática: `internal/<camada>/<pacote>/`. Evitar sub-sub-pacotes sem necessidade.

## Sinais de excesso
- Pacote novo criado para uma única função sem necessidade estrutural.
- Interface sem consumidor alternativo.
- Pattern introduzido apenas para "preparar o futuro".
- Container de DI para projeto com menos de 10 dependências raiz.
