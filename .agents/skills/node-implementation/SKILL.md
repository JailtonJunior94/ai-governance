---
name: node-implementation
version: 1.0.0
description: Implementa alteracoes em codigo Node/TypeScript usando governanca base, convencoes de projeto e validacao proporcional. Use quando a tarefa exigir adicionar, corrigir, refatorar ou validar codigo Node.js ou TypeScript. Nao use para tarefas sem codigo Node/TypeScript.
---

# Implementacao Node/TypeScript

## Procedimentos

**Etapa 1: Carregar base obrigatoria**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Ler `references/architecture.md`.
3. Ler `package.json` para identificar dependencias, scripts e engine.
4. Ler `tsconfig.json` quando existir para identificar versao alvo e configuracao de tipos.
5. Executar `bash .agents/skills/agent-governance/scripts/detect-toolchain.sh` para descobrir comandos de fmt, test e lint.

**Patterns frequentes (inline — evitar carregar patterns.md para estes)**
- **Factory Function:** Preferir factory functions sobre classes quando nao houver estado mutavel. Usar factory quando a construcao envolver validacao ou defaults complexos.
- **Dependency Injection:** Preferir injecao via construtor sobre containers automaticos, salvo quando o projeto ja adotar um container (tsyringe, inversify, NestJS IoC). Depender de interfaces/types em fronteiras de IO.
- **Repository:** Interface do repository deve expor operacoes de dominio, nao primitivas SQL. Nao retornar entidades ORM diretamente — mapear para entidades de dominio.

**Etapa 2: Selecionar apenas o contexto necessario**
1. Ler `references/conventions.md` quando a tarefa envolver estrutura de projeto, organizacao de modulos ou padroes de importacao.
2. Ler `references/testing.md` quando a tarefa envolver estrategia de testes, mocking ou cobertura.
3. Ler `references/api.md` quando a tarefa envolver handlers HTTP, middlewares, DTOs, validacao de request ou serializacao.
4. Ler `references/patterns.md` **somente** quando a tarefa envolver strategy, composicao vs heranca ou organizacao de modulos nao cobertos inline. Factory, DI e Repository ja estao definidos na secao "Patterns frequentes" acima e NAO devem motivar o carregamento deste arquivo — isso evita ~500 tokens redundantes.
5. Ler `references/concurrency.md` quando a tarefa envolver Promises, controle de concorrencia, worker threads, streams ou event loop.
6. Ler `references/resilience.md` quando a tarefa envolver retries, circuit breakers, timeouts em chamadas externas, fallbacks ou health checks.
7. Ler `references/build.md` quando a tarefa envolver Dockerfile, pipeline de CI, bundling, package manager ou empacotamento.
8. Ler `references/graceful-lifecycle.md` quando a tarefa envolver shutdown gracioso, signal handling (SIGTERM/SIGINT), drain de conexoes HTTP ou encerramento de workers e streams.
9. Ler `references/examples-domain-flow.md` quando a tarefa precisar de esqueleto concreto de fluxo end-to-end (entidade, use case, handler, teste). Para tarefas menores, usar o esqueleto inline: `Entity/VO -> UseCase(deps) -> Controller(useCase) -> test com jest/vitest mock`, sem carregar o arquivo completo.
10. Ler `references/examples-testing.md` quando a tarefa precisar de exemplos de parametrized tests, factory de mocks, validacao de DTOs ou assercoes async.
11. Ler `references/examples-infrastructure.md` quando a tarefa precisar de exemplo de graceful shutdown, paginacao cursor-based ou versionamento de API.
12. Ler `references/configuration.md` quando a tarefa envolver carregamento de configuracao, variaveis de ambiente ou inicializacao de dependencias.
13. Ler `../agent-governance/references/error-handling.md` quando a tarefa criar, propagar, encapsular ou apresentar erros.
14. Ler `references/persistence.md` quando a tarefa envolver repositories, transactions, migrations, queries ou connection management.
15. Ler `references/observability.md` quando a tarefa envolver logging, tracing, metricas ou health checks.
16. Ler `references/security.md` quando a tarefa envolver autenticacao, autorizacao, validacao de input, rate limiting, CORS ou tratamento de segredos.
17. Ler `references/messaging.md` quando a tarefa envolver producao ou consumo de mensagens, eventos, filas, topicos ou idempotencia de consumidores.

**Economia de contexto**
Se mais de 4 referencias forem necessarias para a mesma tarefa, priorizar as 3 mais criticas para o escopo da mudanca e registrar as demais como contexto nao carregado. Carregar referencias adicionais apenas se a implementacao revelar necessidade concreta.

**Etapa 3: Modelar a alteracao**
1. Identificar o menor conjunto seguro de mudancas que satisfaz a solicitacao.
2. Mapear o comportamento afetado, as dependencias envolvidas e o risco de regressao.
3. Preferir tipagem estrita em TypeScript; evitar `any` sem justificativa.
4. Respeitar o estilo existente do projeto (ESM vs CJS, semicolons, aspas).

**Etapa 4: Implementar**
1. Editar o codigo seguindo as convencoes do contexto analisado.
2. Atualizar ou adicionar testes para toda mudanca de comportamento.
3. Adaptar exemplos ao contexto real em vez de replica-los literalmente.

**Etapa 5: Validar**
1. Seguir Etapa 4 de `.agents/skills/agent-governance/SKILL.md`.
2. Em Node/TypeScript, preferir os scripts definidos em `package.json` (ex: `npm run lint`, `npm test`).

## Tratamento de Erros
* Se `package.json` estiver ausente, parar antes de assumir dependencias ou runtime.
* Se o projeto usar monorepo (workspaces), validar apenas os workspaces afetados pela mudanca.
* Se houver conflito entre esta skill e a governanca base, seguir a restricao mais segura e registrar a suposicao.
