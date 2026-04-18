---
name: go-implementation
version: 1.0.0
description: Implementa alteracoes em codigo Go usando governanca base, arquitetura, estilo, testes e padroes recorrentes. Use quando a tarefa exigir adicionar, corrigir, refatorar ou validar codigo Go, incluindo interfaces, generics, concorrencia e validacao da stack. Nao use para tarefas sem codigo Go, documentacao geral ou triagem sem alteracao.
---

# Implementacao Go

## Procedimentos

**Etapa 1: Carregar base obrigatoria**
1. Ler `AGENTS.md`.
2. Ler `.agents/skills/agent-governance/SKILL.md`.
3. Ler `references/governance.md`.
4. Ler `references/architecture.md`.
5. Ler `references/go-standards.md`.
6. Executar `bash scripts/verify-go-mod.sh`.
7. Ler `go.mod` quando ele existir no contexto analisado.

**Etapa 2: Selecionar apenas o contexto necessario**
1. Ler `references/interfaces.md` quando a tarefa introduzir, remover ou remodelar interfaces, construtores ou fronteiras de dependencia.
2. Ler `references/generics.md` quando a tarefa introduzir ou alterar parametros de tipo, constraints ou componentes reutilizaveis com generics.
3. Ler `references/concurrency.md` quando a tarefa usar goroutines, channels, cancelamento, worker pools ou sincronizacao.
4. Ler `references/patterns-creational.md` quando a tarefa envolver factory functions, functional options, builders ou inicializacao controlada de objetos.
5. Ler `references/patterns-structural.md` quando a tarefa envolver adapters para integracao externa, decorators/middleware ou facades de orquestracao.
6. Ler `references/patterns-behavioral.md` quando a tarefa envolver strategy, chain of responsibility, observer/eventos, maquina de estado ou template method.
7. Ler `references/observability.md` quando a tarefa envolver logging, tracing, metricas ou health checks.
8. Ler `references/api.md` quando a tarefa envolver handlers HTTP/gRPC, middlewares, DTOs ou serializacao.
9. Ler `references/persistence.md` quando a tarefa envolver repositories, transactions, migrations, queries ou connection management.
10. Ler `references/configuration.md` quando a tarefa envolver carregamento de configuracao, variáveis de ambiente ou inicializacao de dependencias.
11. Ler `references/resilience.md` quando a tarefa envolver retries, circuit breakers, timeouts em chamadas externas, fallbacks ou protecao contra falhas transitórias.
12. Ler `references/messaging.md` quando a tarefa envolver produção ou consumo de mensagens, eventos, filas, tópicos, outbox pattern ou idempotência de consumidores.
13. Ler `references/security.md` quando a tarefa envolver autenticação, autorização, validação de input, rate limiting, CORS ou tratamento de segredos.
14. Ler `references/tests.md` quando a tarefa envolver estratégia de testes, integration tests, testcontainers, fixtures ou cobertura.
15. Ler `references/examples-domain-flow.md` quando a tarefa precisar de esqueleto concreto de fluxo end-to-end (dominio, service, handler, teste com suite e mockery).
16. Ler `references/examples-testing.md` quando a tarefa precisar de exemplos de fuzz test, table-driven test, construtor com invariantes ou interface no consumidor.
17. Ler `references/examples-infrastructure.md` quando a tarefa precisar de exemplo de graceful shutdown, paginacao cursor-based ou versionamento de API.
18. Ler `references/build.md` quando a tarefa envolver Dockerfile, Makefile, pipeline de CI, build flags, imagem de container ou gates de qualidade.
19. Ler `references/graceful-lifecycle.md` quando a tarefa envolver inicializacao ordenada, shutdown gracioso, handler de sinais, drain de conexoes ou encerramento de goroutines de longa duracao.

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
1. Executar `gofmt` ou o formatter adotado pelo contexto nos arquivos Go alterados.
2. Executar primeiro testes direcionados e depois testes mais amplos quando o custo for proporcional.
3. Executar lint quando esse passo existir.
4. Registrar falhas com o comando exato e um diagnostico curto.

## Tratamento de Erros
* Se `go.mod` estiver ausente, parar antes de assumir versao de Go ou dependencias.
* Se o contexto nao fornecer comando de teste, lint ou formatter, registrar a ausencia explicitamente em vez de inventar substitutos.
* Se mais de uma abordagem parecer plausivel, preferir a alternativa com menos tipos, menos indirecao e menor custo de teste.
* Se houver conflito entre esta skill e a governanca base, seguir a restricao mais segura e registrar a suposicao.
