---
name: node-implementation
version: 1.0.0
description: Implementa alteracoes em codigo Node/TypeScript usando governanca base, convencoes de projeto e validacao proporcional. Use quando a tarefa exigir adicionar, corrigir, refatorar ou validar codigo Node.js ou TypeScript. Nao use para tarefas sem codigo Node/TypeScript.
---

# Implementacao Node/TypeScript

## Procedimentos

**Etapa 1: Carregar base obrigatoria**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Ler `package.json` para identificar dependencias, scripts e engine.
3. Ler `tsconfig.json` quando existir para identificar versao alvo e configuracao de tipos.
4. Executar `bash .agents/skills/agent-governance/scripts/detect-toolchain.sh` para descobrir comandos de fmt, test e lint.

**Etapa 2: Selecionar apenas o contexto necessario**
1. Ler `references/conventions.md` quando a tarefa envolver estrutura de projeto, organizacao de modulos ou padroes de importacao.
2. Ler `references/testing.md` quando a tarefa envolver estrategia de testes, mocking ou cobertura.
3. Ler `references/error-handling.md` quando a tarefa criar, propagar, encapsular ou apresentar erros.
4. Ler `references/api.md` quando a tarefa envolver handlers HTTP, middlewares, DTOs, validacao de request ou serializacao.
5. Ler `references/patterns.md` quando a tarefa envolver dependency injection, repository, factory, strategy ou organizacao de modulos.
6. Ler `references/observability.md` quando a tarefa envolver logging, tracing, metricas ou health checks.
7. Ler `references/concurrency.md` quando a tarefa envolver Promises, controle de concorrencia, worker threads, streams ou event loop.
8. Ler `references/resilience.md` quando a tarefa envolver retries, circuit breakers, timeouts em chamadas externas, fallbacks ou health checks.
9. Ler `references/build.md` quando a tarefa envolver Dockerfile, pipeline de CI, bundling, package manager ou empacotamento.

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
