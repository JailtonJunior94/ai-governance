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

**Etapa 2: Selecionar apenas o contexto necessario**
1. Ler `references/interfaces.md` quando a tarefa introduzir, remover ou remodelar interfaces, construtores ou fronteiras de dependencia.
2. Ler `references/generics.md` quando a tarefa introduzir ou alterar parametros de tipo, constraints ou componentes reutilizaveis com generics.
3. Ler `references/concurrency.md` quando a tarefa usar goroutines, channels, cancelamento, worker pools ou sincronizacao.
4. Ler `references/patterns.md` quando a tarefa envolver decorators/middleware, facades, strategy, chain of responsibility, observer/eventos, maquina de estado ou template method. Factory Function, Functional Options e Adapter ja estao inline acima — carregar o arquivo completo apenas para os demais patterns. Quando apenas uma categoria for necessaria, ler somente a secao relevante: Structural (linhas 62-137), Behavioral (linhas 138-259).
5. Ler `references/observability.md` quando a tarefa envolver logging, tracing, metricas ou health checks.
6. Ler `references/api.md` quando a tarefa envolver handlers HTTP/gRPC, middlewares, DTOs ou serializacao.
7. Ler `references/persistence.md` quando a tarefa envolver repositories, transactions, migrations, queries ou connection management.
8. Ler `references/configuration.md` quando a tarefa envolver carregamento de configuracao, variáveis de ambiente ou inicializacao de dependencias.
9. Ler `references/resilience.md` quando a tarefa envolver retries, circuit breakers, timeouts em chamadas externas, fallbacks ou protecao contra falhas transitórias.
10. Ler `references/messaging.md` quando a tarefa envolver produção ou consumo de mensagens, eventos, filas, tópicos, outbox pattern ou idempotência de consumidores.
11. Ler `references/security.md` quando a tarefa envolver autenticação, autorização, validação de input, rate limiting, CORS ou tratamento de segredos.
12. Ler `references/testing.md` quando a tarefa envolver estratégia de testes, integration tests, testcontainers, fixtures ou cobertura.
13. Ler `references/examples-domain-flow.md` quando a tarefa precisar de esqueleto concreto de fluxo end-to-end (dominio, service, handler, teste com suite e mockery).
14. Ler `references/examples-testing.md` quando a tarefa precisar de exemplos de fuzz test, table-driven test, construtor com invariantes ou interface no consumidor.
15. Ler `references/examples-infrastructure.md` quando a tarefa precisar de exemplo de graceful shutdown, paginacao cursor-based ou versionamento de API.
16. Ler `references/build.md` quando a tarefa envolver Dockerfile, Makefile, pipeline de CI, build flags, imagem de container ou gates de qualidade.
17. Ler `references/graceful-lifecycle.md` quando a tarefa envolver inicializacao ordenada, shutdown gracioso, handler de sinais, drain de conexoes ou encerramento de goroutines de longa duracao.

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
