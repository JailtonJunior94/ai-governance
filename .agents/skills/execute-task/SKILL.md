---
name: execute-task
version: 1.0.0
depends_on: [review]
description: Executa uma tarefa de implementação aprovada por meio de codificação, validação, revisão e captura de evidências. Use quando um arquivo de tarefa estiver pronto para implementação e fechamento com testes, lint e evidência de revisão. Não use para planejamento, refatorações amplas sem tarefa ou exploração especulativa de código.
---

# Executar Tarefa

## Procedimentos

**Etapa 1: Validar a elegibilidade da tarefa**
1. Verificar profundidade de invocação: `source scripts/lib/check-invocation-depth.sh || { echo "failed: depth limit exceeded"; exit 1; }` — parar se o limite for atingido.
2. Confirmar que `tasks/prd-<feature-slug>/tasks.md`, o arquivo de tarefa alvo, `prd.md` e `techspec.md` estão presentes.
3. Executar gate de cobertura de RF: `bash scripts/check-rf-coverage.sh tasks/prd-<feature-slug>/prd.md tasks/prd-<feature-slug>/tasks.md` — parar com `blocked` se houver RFs não cobertos.
4. Selecionar a primeira tarefa elegível apenas quando o usuário não tiver escolhido uma explicitamente.
5. Confirmar que todas as dependências da tarefa estão em `done`.
6. Se a tarefa não for elegível, retornar `needs_input` ou `blocked`.

**Etapa 2: Carregar o contexto de implementação**
1. Ler por completo o arquivo de tarefa selecionado, `prd.md` e `techspec.md`.
2. Verificar coerência temporal: se `prd.md` ou `techspec.md` forem mais novos que `tasks.md`, avisar o usuário e parar com `needs_input` se não houver confirmação.
3. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
4. Se a tarefa tocar código Go, ler também `.agents/skills/go-implementation/SKILL.md` e carregar apenas as referências exigidas pela mudança.
5. Se a tarefa tocar código Node/TypeScript, ler também `.agents/skills/node-implementation/SKILL.md` e carregar apenas as referências exigidas pela mudança.
6. Se a tarefa tocar código Python, ler também `.agents/skills/python-implementation/SKILL.md` e carregar apenas as referências exigidas pela mudança.
7. Mapear objetivo da tarefa, critérios de aceitação, subtarefas e arquivos-alvo antes de editar.

**Etapa 3: Executar a etapa de implementação**
1. Seguir a ordem das subtarefas definida no arquivo de tarefa.
2. Implementar testes junto com as mudanças de produção.
3. Preferir os pontos de entrada documentados: `task *`, depois `make *`, depois o equivalente local já documentado.
4. Rodar validação direcionada após subtarefas relevantes, não apenas no final.
5. Registrar comandos executados e arquivos alterados para o relatório.
6. Parar com `needs_input` se uma decisão obrigatória ou entrada faltante bloquear a conclusão segura.

**Etapa 4: Executar a etapa de validação e aprovação**
1. Seguir Etapa 4 de `.agents/skills/agent-governance/SKILL.md`.
2. Rodar testes e lint mais amplos quando o escopo justificar.
3. Verificar cada critério de aceitação com evidência explícita.
5. Invocar `review` para o diff produzido e incluir `prd.md` e `techspec.md` como contexto.
6. Se `review` retornar `REJECTED` com bugs no formato canônico, invocar a skill `bugfix` para corrigir os achados dentro do escopo da tarefa.
7. Após `bugfix`, rerodar as validações necessárias e uma nova revisão.
8. Aceitar apenas `APPROVED` ou `APPROVED_WITH_REMARKS` como veredito de revisão aprovador final.

**Etapa 5: Persistir as evidências**
1. Ler `assets/task-execution-report-template.md`.
2. Atualizar o status em `tasks.md` para `done` apenas depois de implementação, validação e revisão concluídas com sucesso.
3. Salvar o relatório como `tasks/prd-<feature-slug>/[num]_execution_report.md`.
4. Rodar `.claude/scripts/validate-task-evidence.sh` no relatório salvo.
5. Se o validador de evidências falhar, retornar `blocked` e descrever a evidência ausente.
6. Antes de marcar a task como `done` em `tasks.md`, executar `bash scripts/check-task-completion.sh tasks/prd-<feature-slug>/` — parar com `blocked` se houver violações.

**Etapa 6: Encerrar explicitamente**
1. Informar o status da tarefa, os resultados de validação, o veredito do revisor e o caminho do relatório.
2. Retornar `done`, `blocked`, `failed` ou `needs_input` usando apenas nomes de estado canônicos.

## Tratamento de Erros

* Se o arquivo de tarefa estiver desatualizado em relação ao codebase ou à especificação técnica, parar e expor o descompasso antes de editar código.
* Se a automação do repositório não tiver entrypoints `task` ou `make`, descobrir e usar os comandos locais documentados em vez de adivinhar.
* Se as validações falharem, tentar apenas uma remediação limitada. Se o problema for mais profundo, retornar `failed` com o comando bloqueante exato e um diagnóstico curto.
* Respeitar o limite de profundidade de invocação definido em `.agents/skills/agent-governance/SKILL.md`. Se review invocar bugfix e bugfix precisar de nova review, esta é a profundidade máxima — não re-invocar bugfix a partir dessa segunda review.
