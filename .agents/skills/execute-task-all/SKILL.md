---
name: execute-task-all
version: 1.0.0
depends_on: [execute-task, review]
description: Executa tarefas aprovadas em sequência até esgotar todas as tasks elegíveis de um tasks/prd-<feature-slug>/tasks.md. Para cada task, executa o fluxo completo de execute-task (elegibilidade, contexto, implementação, validação, review, bugfix quando aplicável, evidências e encerramento). Não use para execução de uma única tarefa isolada nem para planejamento.
---

# Executar Todas as Tarefas

## Procedimentos

**Etapa 1: Validar pré-condições globais**
1. Verificar profundidade de invocação: `source scripts/lib/check-invocation-depth.sh || { echo "failed: depth limit exceeded"; exit 1; }` — parar se o limite for atingido.
2. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido.
3. Confirmar que `tasks/prd-<feature-slug>/tasks.md`, `prd.md` e `techspec.md` estão presentes.
4. Executar gate de cobertura de RF: `bash scripts/check-rf-coverage.sh tasks/prd-<feature-slug>/prd.md tasks/prd-<feature-slug>/tasks.md` — parar com `blocked` se houver RFs não cobertos.
5. Verificar coerência temporal: se `prd.md` ou `techspec.md` foram modificados após a criação de `tasks.md`, avisar o usuário que os artefatos de origem podem ter divergido e perguntar se deseja continuar ou re-gerar as tarefas. Parar com `needs_input` se o usuário não confirmar.

**Etapa 2: Selecionar a primeira task elegível**
1. Percorrer `tasks.md` na ordem definida no documento.
2. Uma task é elegível quando:
   - Seu status não é `done`, `blocked`, `failed` nem `skipped`.
   - Todas as dependências declaradas estão em `done`.
   - O arquivo de tarefa correspondente existe.
3. Se nenhuma task elegível for encontrada, ir diretamente para a Etapa 6.

**Etapa 3: Executar o fluxo completo da task selecionada**
1. Executar as Etapas 1 a 6 de `.agents/skills/execute-task/SKILL.md` para a task selecionada, preservando integralmente:
   - Carregamento de contexto de implementação (arquivo de tarefa, `prd.md`, `techspec.md`, skill de linguagem aplicável).
   - Implementação seguindo a ordem das subtarefas e validação direcionada.
   - Validação e aprovação com invocação de `review` e, quando necessário, `bugfix` seguido de revalidação e nova revisão.
   - Persistência de evidências com relatório e validação via `.claude/scripts/validate-task-evidence.sh`.
   - Encerramento explícito com estado canônico.
2. Respeitar o limite de profundidade de invocação definido em `.agents/skills/agent-governance/SKILL.md`. Se review invocar bugfix e bugfix precisar de nova review, esta é a profundidade máxima — não re-invocar bugfix a partir dessa segunda review.
3. Se a task concluir com `done`, registrar o resultado e prosseguir para a Etapa 4.
4. Se a task concluir com `blocked`, `failed` ou `needs_input`, interromper o loop e ir para a Etapa 6 com o estado retornado pela task.

**Etapa 4: Limpar contexto transitório**
1. Descartar variáveis, mapeamentos de arquivos-alvo, critérios de aceitação e estado operacional acumulados exclusivamente durante a execução da task concluída.
2. Esta limpeza é lógica: refere-se ao descarte de contexto de trabalho transitório entre tasks. Não apagar, mover nem alterar arquivos do repositório, cache, histórico de git, relatórios gerados ou qualquer artefato persistido.
3. Manter carregados os artefatos globais (`AGENTS.md`, `agent-governance`, `tasks.md`, `prd.md`, `techspec.md`) para evitar recarga desnecessária.

**Etapa 5: Retomar seleção da próxima task**
1. Reler `tasks.md` para obter o estado atualizado das tasks (o status pode ter sido alterado pela execução anterior).
2. Voltar para a Etapa 2 e selecionar a próxima task elegível.

**Etapa 6: Encerrar o loop**
1. Informar o resumo consolidado: tasks concluídas com sucesso, tasks pendentes (se houver), task que causou a interrupção (se aplicável), e caminhos dos relatórios gerados.
2. Retornar o estado canônico final:
   - `done` — quando todas as tasks elegíveis foram concluídas com sucesso e não restam tasks pendentes.
   - `blocked` — quando uma task retornou `blocked` ou uma pré-condição global não foi atendida.
   - `failed` — quando uma task retornou `failed` ou uma falha de validação não teve remediação segura.
   - `needs_input` — quando uma task retornou `needs_input` ou uma confirmação obrigatória não foi obtida.

## Regra de Parada

O loop encerra exclusivamente em um destes cenários:
- Todas as tasks concluídas com sucesso (`done`).
- Uma task retornou `blocked`, `failed` ou `needs_input`.
- Nenhuma task elegível encontrada após a conclusão da última task executada.
- Limite de profundidade de invocação atingido.
- Divergência temporal entre artefatos sem confirmação do usuário.

## Tratamento de Erros

* Se o arquivo `tasks.md` estiver desatualizado em relação ao codebase ou à especificação técnica, parar e expor o descompasso antes de executar qualquer task.
* Se a automação do repositório não tiver entrypoints `task` ou `make`, descobrir e usar os comandos locais documentados em vez de adivinhar.
* Se uma task falhar em validação e a remediação não for segura, parar o loop com `failed` e incluir a task, o comando bloqueante exato e um diagnóstico curto.
* Respeitar o limite de profundidade de invocação. Se atingido durante a execução de uma task, encerrar essa task com `failed` e interromper o loop.
* Não executar loops infinitos de remediação. Se uma task falhar após a tentativa de bugfix e revalidação, encerrar com `failed`.
* Se uma dependência declarada em uma task não estiver em `done` e não houver outra task elegível, encerrar com `blocked`.
