---
name: agent-governance
description: Orquestra regras de governanca, DDD, tratamento de erros, seguranca e testes para tarefas com agentes de IA. Use quando a tarefa exigir aplicar padroes obrigatorios antes de analisar, editar ou validar codigo. Nao use para tarefas casuais sem alteracao de codigo nem para substituir skills especificas de linguagem.
---

# Governanca para Agentes

## Procedimentos

**Etapa 1: Carregar contexto base**
1. Ler `AGENTS.md` antes de propor ou executar mudancas.
2. Identificar se a tarefa afeta modelagem de dominio, fluxo de erro, seguranca, validacao ou testes.
3. Aplicar a menor mudanca segura que preserve arquitetura, convencoes e fronteiras existentes.

**Etapa 2: Carregar referencias sob demanda**
1. Ler `references/ddd.md` quando a tarefa alterar entidades, value objects, aggregate roots, transicoes de estado ou regras de aplicacao.
2. Ler `references/error-handling.md` quando a tarefa criar, propagar, encapsular, comparar ou apresentar erros.
3. Ler `references/security.md` quando a tarefa envolver filesystem, subprocessos, segredos, configuracao, runtime, input externo ou dependencias.
4. Ler `references/tests.md` quando a tarefa alterar comportamento, validadores, runtime, adapters, persistencia ou gates de validacao.

**Etapa 3: Executar com controle**
1. Preservar comportamento publico existente, salvo quando a mudanca explicitar a alteracao.
2. Nao inventar contexto ausente, versao de linguagem, framework ou runtime sem verificacao local.
3. Nao introduzir abstracoes, camadas ou dependencias sem demanda concreta.
4. Atualizar ou adicionar testes quando houver mudanca de comportamento.

**Etapa 4: Validar proporcionalmente**
1. Rodar formatter dos arquivos alterados quando a stack oferecer esse passo.
2. Rodar primeiro testes direcionados e depois validacoes mais amplas quando o custo for proporcional ao risco.
3. Informar falhas de validacao com o comando exato e um diagnostico curto.

## Tratamento de Erros
* Se a tarefa nao deixar claro quais referencias carregar, aplicar `AGENTS.md` como baseline e ler apenas os arquivos tematicos diretamente ligados a superficie alterada.
* Se houver conflito entre convencao local identificada e regra generica desta skill, priorizar a arquitetura e os contratos ja existentes no contexto analisado e registrar a suposicao.
* Se um comando de validacao nao existir no contexto analisado, nao inventar substitutos; registrar a ausencia explicitamente.
