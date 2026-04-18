---
name: create-technical-specification
version: 1.0.0
description: Cria especificações técnicas prontas para implementação a partir de um PRD aprovado e do contexto do repositório. Use quando arquitetura, interfaces, riscos, ADRs e estratégia de testes precisarem ser definidos antes da codificação. Não use para descoberta de produto, execução de tarefa ou revisão de código.
---

# Criar Especificação Técnica

## Procedimentos

**Etapa 1: Validar o artefato de entrada**
1. Confirmar que o PRD alvo existe em `tasks/prd-<slug-da-funcionalidade>/prd.md`.
2. Extrair requisitos, restrições, métricas e itens fora de escopo do PRD antes de explorar o codebase.
3. Parar com `needs_input` se o PRD estiver ausente ou incompleto demais para sustentar decisões de arquitetura.

**Etapa 2: Mapear o repositório e as restrições técnicas**
1. Ler `AGENTS.md` e explorar a estrutura do repositório relevante para o PRD.
2. Explorar apenas os caminhos de código, módulos, integrações e interfaces relevantes para o PRD.
3. Mapear impactos em arquitetura, fluxo de dados, observabilidade, tratamento de erros e testes.
4. Se dependências externas ou o comportamento atual de fornecedores forem relevantes, verificar em documentação primária ou oficial.

**Etapa 3: Resolver bloqueios de arquitetura**
1. Fazer perguntas técnicas de esclarecimento cobrindo:
   - fronteiras de domínio
   - fluxo de dados
   - contratos de interface
   - falhas esperadas e idempotência
   - estratégia de testes
2. Limitar o esclarecimento a duas rodadas.
3. Se a arquitetura continuar bloqueada após duas rodadas, retornar `needs_input` com as decisões faltantes.

**Etapa 4: Verificar conformidade com as regras do repositório**
1. Ler `.agents/skills/agent-governance/SKILL.md` e carregar referências sob demanda:
   - `.agents/skills/agent-governance/references/ddd.md`
   - `.agents/skills/agent-governance/references/error-handling.md`
   - `.agents/skills/agent-governance/references/security.md`
   - `.agents/skills/agent-governance/references/testing.md`
2. Para cada desvio intencional, registrar a justificativa e a alternativa aderente rejeitada.

**Etapa 5: Redigir a especificação técnica**
1. Ler `assets/techspec-template.md` antes de redigir.
2. Focar em como implementar a funcionalidade, não em reexplicar o PRD.
3. Incluir um mapeamento de requisito para decisão e teste.
4. Documentar abordagens escolhidas, trade-offs, alternativas rejeitadas, riscos e implicações de observabilidade.
5. Manter interfaces e modelos de dados concretos o suficiente para orientar a implementação.

**Etapa 6: Criar ADRs para decisões materiais**
1. Ler `assets/adr-template.md`.
2. Para cada decisão material introduzida na especificação técnica, criar uma ADR separada em `tasks/prd-<slug-da-funcionalidade>/`.
3. Usar nomes estáveis de arquivo como `adr-001-<slug-da-decisao>.md`.
4. Vincular as ADRs a partir da especificação técnica.

**Etapa 7: Persistir e reportar**
1. Salvar a especificação técnica como `tasks/prd-<slug-da-funcionalidade>/techspec.md`.
2. Informar o caminho final, os caminhos das ADRs e os itens ainda em aberto.
3. Retornar estado final `done` ou `needs_input`.

## Tratamento de Erros

* Se o PRD misturar produto com detalhe de implementação, preservar a intenção de produto e mover apenas as decisões de implementação para a especificação técnica.
* Se a exploração do repositório mostrar que o desenho solicitado viola regras existentes de arquitetura ou segurança, documentar o conflito explicitamente em vez de normalizá-lo em silêncio.
* Se a documentação externa de uma dependência estiver indisponível, marcar a decisão afetada como suposição e reduzir o raio de impacto dessa suposição na implementação proposta.
