---
name: create-prd
version: 1.0.0
description: Cria documentos de requisitos do produto a partir de solicitações de funcionalidade. Use quando uma funcionalidade precisar de escopo, objetivos, restrições e requisitos funcionais numerados antes do desenho técnico. Não use para planejamento de implementação, mudanças de código ou decisões de arquitetura técnica.
---

# Criar PRD

## Procedimentos

**Etapa 1: Validar o ponto de partida**
1. Confirmar que a solicitação é de definição de produto ou funcionalidade, não de implementação ou correção.
2. Derivar um slug estável da funcionalidade em kebab-case e planejar a saída em `tasks/prd-<slug-da-funcionalidade>/prd.md`.
3. Se a pasta alvo ou o PRD já existirem, ler primeiro e evoluir o artefato existente em vez de criar um documento concorrente.

**Etapa 2: Coletar o contexto mínimo viável de produto**
1. Fazer perguntas de esclarecimento cobrindo as seis categorias obrigatórias:
   - problema e objetivo
   - usuário ou ator principal
   - escopo incluído
   - escopo excluído
   - restrições e conformidade
   - critérios de sucesso mensuráveis
2. Parar após no máximo duas rodadas de esclarecimento.
3. Se ainda faltarem respostas objetivas ou houver contradições, retornar `needs_input`, listar os pontos em aberto e não redigir o PRD final.

**Etapa 3: Carregar apenas o contexto necessário para escrever bem**
1. Ler `assets/prd-template.md` antes de redigir.
2. Ler o contexto do repositório (README, AGENTS.md) apenas quando a funcionalidade depender de restrições específicas do projeto.
3. Ler `.agents/skills/agent-governance/references/security.md` ou outras referências apenas quando impactarem as restrições de produto declaradas.
4. Usar pesquisa na web apenas quando a solicitação depender de fatos externos atuais, regulações, integrações ou restrições de mercado. Se a navegação não estiver disponível, declarar a suposição explicitamente.

**Etapa 4: Redigir o PRD**
1. Escrever o documento com foco de produto no que e por que, não no como.
2. Seguir `assets/prd-template.md` com fidelidade suficiente para preservar a intenção das seções, adaptando o conteúdo à funcionalidade.
3. Numerar requisitos funcionais para rastreabilidade.
4. Manter o documento concreto, testável e orientado a decisão.
5. Incluir a seção `Suposições e Questões em Aberto` sempre que restarem suposições.

**Etapa 5: Persistir o artefato**
1. Criar `tasks/prd-<slug-da-funcionalidade>/` quando não existir.
2. Salvar o documento final como `tasks/prd-<slug-da-funcionalidade>/prd.md`.
3. Evitar criar cópias alternativas em pastas ad hoc.

**Etapa 6: Encerrar com status explícito**
1. Informar o caminho final.
2. Resumir a funcionalidade em 3-5 linhas.
3. Listar suposições abertas ou questões não resolvidas.
4. Retornar estado final `done` quando o PRD estiver completo, caso contrário `needs_input`.

## Tratamento de Erros

* Se a solicitação pular direto para detalhes de implementação, redirecionar o documento para a intenção de produto e registrar itens técnicos apenas como restrições de alto nível.
* Se a definição do problema for ampla o bastante para esconder múltiplas features, dividir o escopo e perguntar qual fatia deve virar o PRD.
* Se um PRD existente conflitar com novas instruções, preservar as duas versões da decisão no histórico do documento e explicitar o conflito antes de sobrescrever conteúdo.
