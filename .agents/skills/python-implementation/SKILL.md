---
name: python-implementation
version: 1.0.0
description: Implementa alteracoes em codigo Python usando governanca base, convencoes de projeto e validacao proporcional. Use quando a tarefa exigir adicionar, corrigir, refatorar ou validar codigo Python. Nao use para tarefas sem codigo Python.
---

# Implementacao Python

## Procedimentos

**Etapa 1: Carregar base obrigatoria**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Ler `pyproject.toml`, `setup.py` ou `requirements.txt` para identificar dependencias e versao de Python.
3. Executar `bash .agents/skills/agent-governance/scripts/detect-toolchain.sh` para descobrir comandos de fmt, test e lint.

**Etapa 2: Selecionar apenas o contexto necessario**
1. Ler `references/conventions.md` quando a tarefa envolver estrutura de projeto, organizacao de modulos ou padroes de importacao.
2. Ler `references/architecture.md` quando a tarefa envolver layout de diretorios, injecao de dependencias ou fronteiras entre camadas.
3. Ler `references/testing.md` quando a tarefa envolver estrategia de testes, fixtures ou cobertura.
4. Ler `references/error-handling.md` quando a tarefa criar, propagar, encapsular ou apresentar erros.
5. Ler `references/api.md` quando a tarefa envolver handlers HTTP, middlewares, DTOs, validacao de request ou serializacao.
6. Ler `references/patterns.md` quando a tarefa envolver dependency injection, repository, dataclasses, strategy ou organizacao de modulos.
7. Ler `references/observability.md` quando a tarefa envolver logging, tracing, metricas ou health checks.
8. Ler `references/concurrency.md` quando a tarefa envolver asyncio, threading, multiprocessing, controle de concorrencia ou paralelismo.
9. Ler `references/resilience.md` quando a tarefa envolver retries, circuit breakers, timeouts em chamadas externas, fallbacks ou health checks.
10. Ler `references/persistence.md` quando a tarefa envolver repositories, transactions, migrations, queries ou connection management.
11. Ler `references/security.md` quando a tarefa envolver autenticacao, autorizacao, validacao de input, rate limiting, CORS ou tratamento de segredos.
12. Ler `references/build.md` quando a tarefa envolver Dockerfile, pipeline de CI, packaging, gerenciamento de dependencias ou distribuicao.
13. Ler `references/examples-domain-flow.md` quando a tarefa precisar de esqueleto concreto de fluxo end-to-end (entidade, use case, handler, teste).
14. Ler `references/graceful-lifecycle.md` quando a tarefa envolver shutdown gracioso, signal handling (SIGTERM/SIGINT), drain de conexoes, cleanup de asyncio tasks ou encerramento de workers.
15. Ler `references/configuration.md` quando a tarefa envolver carregamento de configuracao, variaveis de ambiente, pydantic-settings ou inicializacao de dependencias.
16. Ler `references/messaging.md` quando a tarefa envolver producao ou consumo de mensagens, eventos, filas, topicos ou idempotencia de consumidores.

**Economia de contexto**
Se mais de 4 referencias forem necessarias para a mesma tarefa, priorizar as 3 mais criticas para o escopo da mudanca e registrar as demais como contexto nao carregado. Carregar referencias adicionais apenas se a implementacao revelar necessidade concreta.

**Etapa 3: Modelar a alteracao**
1. Identificar o menor conjunto seguro de mudancas que satisfaz a solicitacao.
2. Mapear o comportamento afetado, as dependencias envolvidas e o risco de regressao.
3. Preferir type hints em funcoes publicas.
4. Respeitar o estilo existente do projeto.

**Etapa 4: Implementar**
1. Editar o codigo seguindo a versao Python declarada no projeto e as convencoes do contexto analisado.
2. Atualizar ou adicionar testes para toda mudanca de comportamento.
3. Adaptar exemplos ao contexto real em vez de replica-los literalmente.

**Etapa 5: Validar**
1. Seguir Etapa 4 de `.agents/skills/agent-governance/SKILL.md`.
2. Em Python, preferir `ruff` para lint e format quando disponivel; caso contrario, `black` + `flake8` ou o toolchain do projeto.

## Tratamento de Erros
* Se nenhum arquivo de configuracao Python for encontrado, parar antes de assumir versao ou dependencias.
* Se o projeto usar monorepo, validar apenas os packages afetados pela mudanca.
* Se houver conflito entre esta skill e a governanca base, seguir a restricao mais segura e registrar a suposicao.
