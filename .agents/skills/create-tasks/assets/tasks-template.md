# Resumo das Tarefas de Implementação para [Funcionalidade]

## Metadados
- **PRD:** `tasks/prd-[nome-da-funcionalidade]/prd.md`
- **Especificação Técnica:** `tasks/prd-[nome-da-funcionalidade]/techspec.md`
- **Total de tarefas:** X
- **Tarefas paralelizáveis:** [lista ou "nenhuma"]

## Tarefas

| # | Título | Status | Dependências | Paralelizável |
|---|--------|--------|-------------|---------------|
| 1.0 | [Título da tarefa] | pending | — | — |
| 2.0 | [Título da tarefa] | pending | 1.0 | Não |
| 3.0 | [Título da tarefa] | pending | — | Com 2.0 |

## Dependências Críticas
- [Descrever dependências bloqueantes entre tarefas]

## Riscos de Integração
- [Pontos de integração que podem causar retrabalho]

## Grafo de Dependencias

```mermaid
graph TD
    T1["1.0 — Titulo da tarefa"]
    T2["2.0 — Titulo da tarefa"] --> T1
    T3["3.0 — Titulo da tarefa"]
```

## Legenda de Status
- `pending`: aguardando execução
- `in_progress`: em execução
- `needs_input`: aguardando informação do usuário
- `blocked`: bloqueado por dependência ou falha externa
- `failed`: falhou após limite de remediação
- `done`: completado e aprovado
