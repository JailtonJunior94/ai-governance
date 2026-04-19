---
name: create-tasks
version: 1.0.0
description: Cria tarefas incrementais de implementação a partir de um PRD e de uma especificação técnica. Use quando documentos de produto e técnicos aprovados precisarem ser decompostos em itens de trabalho ordenados e testáveis. Não use para mudanças diretas de código, descoberta de funcionalidade ou revisão de branch.
---

# Criar Tarefas

## Procedimentos

**Etapa 1: Validar os documentos de origem**
1. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
2. Confirmar que `tasks/prd-<feature-slug>/prd.md` e `tasks/prd-<feature-slug>/techspec.md` existem.
2. Ler os dois arquivos por completo antes de propor itens de trabalho.
3. Parar com `needs_input` se qualquer documento estiver ausente ou contraditório o suficiente para bloquear o planejamento.

**Etapa 2: Extrair fatias de entrega**
1. Identificar requisitos, decisões técnicas, pontos de integração, dependências e áreas de risco.
2. Agrupar o trabalho em fatias que entreguem valor verificável.
3. Preferir a sequência `domain -> interfaces/ports -> use cases -> adapters/repositories -> handlers -> integration`, salvo quando a especificação técnica justificar outra ordem.

**Etapa 3: Propor primeiro o plano de tarefas em alto nível**
1. Ler `assets/tasks-template.md` e `assets/task-template.md` antes de redigir.
2. Produzir uma lista de alto nível com no máximo 10 tarefas.
3. Para cada tarefa, incluir objetivo, entregável e dependências.
4. Parar e aguardar aprovação antes de gerar os arquivos finais.
5. Se a aprovação não estiver disponível na sessão atual, retornar `needs_input` e não escrever os arquivos de tarefa.

**Etapa 4: Gerar os artefatos detalhados de tarefa**
1. Após a aprovação, criar `tasks/prd-<feature-slug>/tasks.md` a partir de `assets/tasks-template.md`.
2. Criar um arquivo por tarefa usando `assets/task-template.md`.
3. Dar a cada tarefa critérios de aceitação explícitos, arquivos relevantes e expectativas de teste.
4. Garantir que cada tarefa seja executável de forma independente e revisável objetivamente.
5. Ao escrever `tasks.md`, calcular e inserir os comentários de rastreabilidade de spec no cabeçalho:
   - `<!-- spec-hash-prd: $(sha256sum tasks/prd-<feature-slug>/prd.md | awk '{print $1}') -->`
   - `<!-- spec-hash-techspec: $(sha256sum tasks/prd-<feature-slug>/techspec.md | awk '{print $1}') -->`
   Estes hashes permitem detectar drift posterior via `bash scripts/check-spec-drift.sh`.

**Etapa 5: Marcar dependências e paralelismo com clareza**
1. Usar apenas estados canônicos: `pending`, `in_progress`, `needs_input`, `blocked`, `failed`, `done`.
2. Marcar dependências críticas explicitamente.
3. Identificar paralelismo seguro apenas quando ele não esconder risco de integração.
4. Gerar bloco mermaid `graph TD` em `tasks.md` representando o grafo de dependencias entre tarefas. Formato: `T1["1.0 — Titulo"] --> T2["2.0 — Titulo"]` para cada dependencia.

**Etapa 6: Reportar o resultado**
1. Listar os arquivos gerados.
2. Destacar dependências críticas e tarefas paralelizáveis.
3. Retornar estado final `done` quando os arquivos forem gerados ou `needs_input` quando a aprovação ainda for necessária.

## Tratamento de Erros

* Se o PRD e a especificação técnica divergirem sobre o escopo, pausar e expor o conflito em vez de codificar os dois nas tarefas.
* Se uma tarefa proposta misturar preocupações não relacionadas, dividi-la antes de escrever os arquivos.
* Se o plano exceder 10 itens principais, consolidar ou reagrupar o trabalho até que cada tarefa represente uma fatia coerente de entrega, e não um micro-passo.
