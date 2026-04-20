---
name: go-implementation
version: 1.0.0
description: Implementa alteracoes em codigo Go usando governanca base, arquitetura, estilo, testes e padroes recorrentes. Use quando a tarefa exigir adicionar, corrigir, refatorar ou validar codigo Go, incluindo interfaces, generics, concorrencia e validacao da stack. Nao use para tarefas sem codigo Go, documentacao geral ou triagem sem alteracao.
---

# Implementacao Go

## Procedimentos

**Etapa 1: Carregar base obrigatoria**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Ler `references/architecture.md`.
3. Executar `bash scripts/verify-go-mod.sh`.
4. Ler `go.mod` quando ele existir no contexto analisado.

**Padroes Go (inline)**
- Preferir nomes curtos e precisos no escopo certo.
- Retornar erros como ultimo valor e usar wrapping com `%w` quando necessario.
- Manter funcoes pequenas quando isso melhorar leitura e teste, sem fragmentacao artificial.
- Preferir zero values uteis e construtores apenas quando houver invariantes ou dependencias obrigatorias.
- Usar `context.Context` em fronteiras de IO, rede, subprocesso ou operacoes cancelaveis.
- Usar sentinel errors (`var ErrNotFound = errors.New(...)`) para erros que o chamador compara com `errors.Is`.
- Usar tipos customizados (`type ValidationError struct{...}`) quando o chamador precisar extrair dados com `errors.As`.
- Formatar com `gofmt`. Usar `go test ./...` como gate minimo.

**Patterns frequentes (inline — evitar carregar patterns.md para estes)**
- **Factory Function:** Usar `New*(deps...) (*T, error)` quando construcao exigir validacao de invariantes ou dependencias obrigatorias. Retornar `(T, error)` ou `*T`. Nao usar factory abstrata para um unico tipo concreto.
- **Functional Options:** Usar `func With*(v) Option` quando o objeto tiver muitos campos opcionais. Preferir sobre builder fluente: `func NewServer(addr string, opts ...ServerOption) *Server`. Cada option e uma `func(*T)` que modifica o alvo.
- **Adapter:** Usar struct que implementa interface do consumidor e delega para tipo externo quando integrar dependencia incompativel. Repository concreto e o exemplo mais comum.

**Indice de referencias** (consultar antes de carregar — evita leitura desnecessaria)
| Arquivo | Descricao |
|---------|-----------|
| `references/architecture.md` | Layouts de diretorio para HTTP/gRPC, worker, monolito modular, CLI |
| `references/interfaces.md` | Quando introduzir, adapter patterns, design orientado ao consumidor |
| `references/generics.md` | Parametros de tipo, constraints, componentes reutilizaveis |
| `references/concurrency.md` | Goroutines, channels, cancelamento, worker pools, sincronizacao |
| `references/patterns-structural.md` | Decorator, Facade — patterns alem dos inline |
| `references/patterns-behavioral.md` | Strategy, chain of responsibility, observer, state machines |
| `references/api.md` | Handlers HTTP/gRPC, middlewares, DTOs, serializacao |
| `references/persistence.md` | Repositories, transactions, migrations, queries, connection management |
| `references/configuration.md` | Variaveis de ambiente, config files, inicializacao de dependencias |
| `references/resilience.md` | Retries, circuit breakers, timeouts, fallbacks |
| `references/messaging.md` | Producao/consumo de mensagens, outbox pattern, idempotencia |
| `references/security.md` | Autenticacao, autorizacao, validacao de input, CORS, segredos |
| `references/observability.md` | Logging estruturado, tracing, metricas |
| `references/testing.md` | Suite-based testing, fixtures, mockery, cobertura |
| `references/build.md` | Dockerfile, Makefile, CI pipeline, build flags |
| `references/graceful-lifecycle.md` | Init ordenado, shutdown gracioso, signal handlers, goroutine drains |
| `references/examples-domain-flow.md` | Esqueleto end-to-end: Entity, Service, Handler, Test |
| `references/examples-testing.md` | Fuzz tests, table-driven tests, invariant constructors |
| `references/examples-infrastructure.md` | Paginacao, API versioning, graceful shutdown |

**Etapa 2: Selecionar apenas o contexto necessario**
1. Ler `references/interfaces.md` quando a tarefa introduzir, remover ou remodelar interfaces, construtores ou fronteiras de dependencia.
2. Ler `references/generics.md` quando a tarefa introduzir ou alterar parametros de tipo, constraints ou componentes reutilizaveis com generics.
3. Ler `references/concurrency.md` quando a tarefa usar goroutines, channels, cancelamento, worker pools ou sincronizacao.
4. Ler `references/patterns-structural.md` **somente** quando a tarefa envolver Decorator, Facade ou detalhes de Creational nao cobertos inline. Factory Function, Functional Options e Adapter ja estao definidos na secao "Patterns frequentes" acima e NAO devem motivar o carregamento deste arquivo — isso evita ~960 tokens redundantes.
5. Ler `references/patterns-behavioral.md` quando a tarefa envolver strategy, chain of responsibility, observer/eventos, maquina de estado ou template method.
6. Ler `references/observability.md` quando a tarefa envolver logging, tracing, metricas ou health checks.
7. Ler `references/api.md` quando a tarefa envolver handlers HTTP/gRPC, middlewares, DTOs ou serializacao.
8. Ler `references/persistence.md` quando a tarefa envolver repositories, transactions, migrations, queries ou connection management.
9. Ler `references/configuration.md` quando a tarefa envolver carregamento de configuracao, variaveis de ambiente ou inicializacao de dependencias.
10. Ler `references/resilience.md` quando a tarefa envolver retries, circuit breakers, timeouts em chamadas externas, fallbacks ou protecao contra falhas transitorias.
11. Ler `references/messaging.md` quando a tarefa envolver producao ou consumo de mensagens, eventos, filas, topicos, outbox pattern ou idempotencia de consumidores.
12. Ler `references/security.md` quando a tarefa envolver autenticacao, autorizacao, validacao de input, rate limiting, CORS ou tratamento de segredos.
13. Ler `references/testing.md` quando a tarefa envolver estrategia de testes, integration tests, testcontainers, fixtures ou cobertura.
14. Ler `references/examples-domain-flow.md` quando a tarefa precisar de esqueleto concreto de fluxo end-to-end (dominio, service, handler, teste com suite e mockery). Para tarefas menores, usar o esqueleto inline: `Entity -> Service(deps) -> Handler(service) -> test com suite/mockery`, sem carregar o arquivo completo.
15. Ler `references/examples-testing.md` quando a tarefa precisar de exemplos de fuzz test, table-driven test, construtor com invariantes ou interface no consumidor.
16. Ler `references/examples-infrastructure.md` quando a tarefa precisar de exemplo de graceful shutdown, paginacao cursor-based ou versionamento de API.
17. Ler `references/build.md` quando a tarefa envolver Dockerfile, Makefile, pipeline de CI, build flags, imagem de container ou gates de qualidade.
18. Ler `references/graceful-lifecycle.md` quando a tarefa envolver inicializacao ordenada, shutdown gracioso, handler de sinais, drain de conexoes ou encerramento de goroutines de longa duracao.

**Economia de contexto**
Se mais de 4 referencias forem necessarias para a mesma tarefa, priorizar as 3 mais criticas para o escopo da mudanca e registrar as demais como contexto nao carregado. Carregar referencias adicionais apenas se a implementacao revelar necessidade concreta.

**Etapa 3: Modelar a alteracao**
1. Identificar o menor conjunto seguro de mudancas que satisfaz a solicitacao.
2. Mapear o comportamento afetado, as dependencias envolvidas e o risco de regressao.
3. Preferir tipos concretos por padrao.
4. Introduzir interface apenas quando existir fronteira consumidora real, necessidade de substituicao ou ponto claro de teste.
5. Aplicar pattern apenas quando ele reduzir acoplamento, branching recorrente ou ambiguidade arquitetural.

**Etapa 4: Implementar**
1. Editar o codigo seguindo a versao Go declarada em `go.mod` e as convencoes do contexto analisado.
2. Manter comentarios curtos e apenas quando agregarem contexto real.
3. Atualizar ou adicionar testes para toda mudanca de comportamento.
4. Adaptar exemplos ao contexto real em vez de replica-los literalmente.

**Etapa 5: Validar**
1. Seguir Etapa 4 de `.agents/skills/agent-governance/SKILL.md`.
2. Em Go, preferir `gofmt` como formatter e `golangci-lint run` como lint quando disponiveis.

## Tratamento de Erros
* Se `go.mod` estiver ausente, parar antes de assumir versao de Go ou dependencias.
* Se o contexto nao fornecer comando de teste, lint ou formatter, registrar a ausencia explicitamente em vez de inventar substitutos.
* Se mais de uma abordagem parecer plausivel, preferir a alternativa com menos tipos, menos indirecao e menor custo de teste.
* Se houver conflito entre esta skill e a governanca base, seguir a restricao mais segura e registrar a suposicao.
