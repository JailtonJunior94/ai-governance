---
name: python-implementation
version: 1.0.0
description: Implementa alteracoes em codigo Python usando governanca base, convencoes de projeto e validacao proporcional. Use quando a tarefa exigir adicionar, corrigir, refatorar ou validar codigo Python. Nao use para tarefas sem codigo Python.
---

# Implementacao Python

## Procedimentos

**Etapa 1: Carregar base obrigatoria**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Ler `references/architecture.md`.
3. Ler `pyproject.toml`, `setup.py` ou `requirements.txt` para identificar dependencias e versao de Python.
4. Executar `bash .agents/skills/agent-governance/scripts/detect-toolchain.sh` para descobrir comandos de fmt, test e lint.

**Patterns frequentes (inline — evitar carregar patterns.md para estes)**
- **Dependency Injection:** Preferir injecao via construtor ou parametros de funcao. Em FastAPI, usar `Depends()`. Depender de Protocol ou ABC em fronteiras de IO.
- **Repository:** Interface do repository deve expor operacoes de dominio, nao primitivas SQL. Nao retornar instancias ORM diretamente — mapear para entidades de dominio.
- **Dataclasses:** Preferir `dataclass` ou `attrs` para value objects e DTOs. Usar `frozen=True` para imutabilidade. Usar `__post_init__` para invariantes.

**Etapa 2: Selecionar apenas o contexto necessario**
1. Ler `references/conventions.md` quando a tarefa envolver estrutura de projeto, organizacao de modulos ou padroes de importacao.
2. Ler `references/testing.md` quando a tarefa envolver estrategia de testes, fixtures ou cobertura.
3. Ler `references/api.md` quando a tarefa envolver handlers HTTP, middlewares, DTOs, validacao de request ou serializacao.
4. Ler `references/patterns.md` **somente** quando a tarefa envolver strategy, composicao vs heranca ou organizacao de modulos nao cobertos inline. DI, Repository e Dataclasses ja estao definidos na secao "Patterns frequentes" acima e NAO devem motivar o carregamento deste arquivo — isso evita ~480 tokens redundantes.
5. Ler `references/concurrency.md` quando a tarefa envolver asyncio, threading, multiprocessing, controle de concorrencia ou paralelismo.
6. Ler `references/resilience.md` quando a tarefa envolver retries, circuit breakers, timeouts em chamadas externas, fallbacks ou health checks.
7. Ler `references/build.md` quando a tarefa envolver Dockerfile, pipeline de CI, packaging, gerenciamento de dependencias ou distribuicao.
8. Ler `references/examples-domain-flow.md` quando a tarefa precisar de esqueleto concreto de fluxo end-to-end (entidade, use case, handler, teste). Para tarefas menores, usar o esqueleto inline: `Entity/dataclass -> UseCase(deps) -> Router(use_case) -> test com pytest fixtures`, sem carregar o arquivo completo.
9. Ler `references/examples-testing.md` quando a tarefa precisar de exemplos de fixtures, parametrize, validacao de schemas ou assercoes async.
10. Ler `references/examples-infrastructure.md` quando a tarefa precisar de exemplo de graceful shutdown, paginacao cursor-based ou versionamento de API.
11. Ler `references/graceful-lifecycle.md` quando a tarefa envolver shutdown gracioso, signal handling (SIGTERM/SIGINT), drain de conexoes, cleanup de asyncio tasks ou encerramento de workers.
12. Ler `references/configuration.md` quando a tarefa envolver carregamento de configuracao, variaveis de ambiente, pydantic-settings ou inicializacao de dependencias.
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
