---
name: execute-task
version: 1.0.0
description: Executa uma tarefa de implementação aprovada por meio de codificação, validação, revisão e captura de evidências. Use quando um arquivo de tarefa estiver pronto para implementação e fechamento com testes, lint e evidência de revisão. Não use para planejamento, refatorações amplas sem tarefa ou exploração especulativa de código.
---

# Executar Tarefa

## Procedimentos

**Etapa 1: Validar a elegibilidade da tarefa**
1. Confirmar que `tasks/prd-<feature-slug>/tasks.md`, o arquivo de tarefa alvo, `prd.md` e `techspec.md` estão presentes.
2. Selecionar a primeira tarefa elegível apenas quando o usuário não tiver escolhido uma explicitamente.
3. Confirmar que todas as dependências da tarefa estão em `done`.
4. Parar com `needs_input` ou `blocked` se a tarefa não for elegível para execução.

**Etapa 2: Carregar o contexto de implementação**
1. Ler por completo o arquivo de tarefa selecionado, `prd.md` e `techspec.md`.
2. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
3. Se a tarefa tocar código Go, ler também `.agents/skills/go-implementation/SKILL.md` e carregar apenas as referências exigidas pela mudança.
4. Se a tarefa tocar código Node/TypeScript, ler também `.agents/skills/node-implementation/SKILL.md` e carregar apenas as referências exigidas pela mudança.
5. Se a tarefa tocar código Python, ler também `.agents/skills/python-implementation/SKILL.md` e carregar apenas as referências exigidas pela mudança.
6. Mapear objetivo da tarefa, critérios de aceitação, subtarefas e arquivos-alvo antes de editar.

**Etapa 3: Executar a etapa de implementação**
1. Seguir a ordem das subtarefas definida no arquivo de tarefa.
2. Implementar testes junto com as mudanças de produção.
3. Preferir os pontos de entrada de validação documentados no repositório:
   - `task test`, `task lint`, `task fmt` quando disponíveis
   - caso contrário, usar `make test`, `make lint`, `make fmt` ou o equivalente documentado
4. Rodar validação direcionada após subtarefas relevantes, não apenas no final.
5. Registrar comandos executados e arquivos alterados para o relatório.
6. Parar com `needs_input` se uma decisão obrigatória ou entrada faltante bloquear a conclusão segura.

**Etapa 4: Executar a etapa de validação e aprovação**
1. Seguir Etapa 4 de `.agents/skills/agent-governance/SKILL.md`.
2. Rodar os comandos de teste e lint do projeto inteiro quando o escopo da tarefa justificar.
3. Verificar cada critério de aceitação com evidência explícita.
5. Invocar a habilidade `review` para o diff produzido e incluir `prd.md` e `techspec.md` como contexto de revisão.
6. Se `review` retornar `REJECTED` com bugs no formato canônico, invocar a skill `bugfix` para corrigir os achados dentro do escopo da tarefa.
7. Após `bugfix`, rerodar as validações necessárias e uma nova revisão.
8. Aceitar apenas `APPROVED` ou `APPROVED_WITH_REMARKS` como veredito de revisão aprovador final.

**Etapa 5: Persistir as evidências**
1. Ler `assets/task-execution-report-template.md`.
2. Atualizar o status da tarefa em `tasks.md` para `done` apenas depois que implementação, validação e revisão tiverem sido concluídas com sucesso.
3. Salvar o relatório como `tasks/prd-<feature-slug>/[num]_execution_report.md`.
4. Rodar `.claude/scripts/validate-task-evidence.sh` contra o relatório salvo.
5. Se o validador de evidências falhar, retornar `blocked` e descrever a evidência ausente.

**Etapa 6: Encerrar explicitamente**
1. Informar o status da tarefa, os resultados de validação, o veredito do revisor e o caminho do relatório.
2. Retornar `done`, `blocked`, `failed` ou `needs_input` usando apenas nomes de estado canônicos.

## Tratamento de Erros

* Se o arquivo de tarefa estiver desatualizado em relação ao codebase ou à especificação técnica, parar e expor o descompasso antes de editar código.
* Se a automação do repositório não tiver entrypoints `task` ou `make`, descobrir e usar os comandos locais documentados em vez de adivinhar.
* Se as validações falharem, tentar apenas uma remediação limitada. Se a falha apontar para um problema de desenho mais profundo, parar e retornar `failed` com o comando bloqueante exato e um diagnóstico curto.
