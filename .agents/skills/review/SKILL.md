---
name: review
version: 1.0.0
description: Revisa um diff de código quanto a correção, segurança, regressões e testes faltantes usando regras específicas do repositório. Use quando uma branch ou diff local precisar de revisão no estilo dono do código antes de merge ou fechamento de tarefa. Não use para implementação, planejamento de produto ou limpeza apenas de estilo.
---

# Revisar

## Procedimentos

**Etapa 1: Carregar o contexto de revisão**
1. Ler primeiro o diff ou os arquivos alterados.
2. Ler `prd.md`, `techspec.md`, arquivos de tarefa ou contexto de issue quando estiverem disponíveis e forem relevantes para a mudança.
3. Confirmar que o contrato de carga base definido em `AGENTS.md` foi cumprido e carregar referências sob demanda quando afetarem materialmente a revisão:
   - `.agents/skills/agent-governance/references/ddd.md`
   - `.agents/skills/agent-governance/references/error-handling.md`
   - `.agents/skills/agent-governance/references/security.md`
   - `.agents/skills/agent-governance/references/testing.md`

**Etapa 2: Revisar como dono do código**
1. Priorizar correção, segurança, regressões de comportamento, testes faltantes e lacunas de evidência.
2. Verificar a mudança contra o comportamento pretendido, não apenas contra o estilo local de código.
3. Checar se as validações são suficientes para o nível de risco.
4. Tratar observações apenas de estilo como secundárias, a menos que escondam um defeito real.

**Etapa 3: Produzir achados primeiro**
1. Começar pelos achados concretos ordenados por severidade.
2. Incluir referências de arquivo e uma explicação curta do impacto.
3. Quando identificar bugs acionáveis, emitir a lista no formato definido em `.agents/skills/agent-governance/references/bug-schema.json` para consumo pela skill `bugfix`.
4. Se não houver achados, dizer isso explicitamente e registrar riscos residuais ou lacunas de teste.

**Etapa 4: Retornar um veredito canônico**
1. Usar apenas um destes vereditos:
   - `APPROVED`
   - `APPROVED_WITH_REMARKS`
   - `REJECTED`
   - `BLOCKED`
2. Usar `BLOCKED` quando faltar contexto necessário ou evidência de validação.
3. Usar `REJECTED` quando o código tiver defeitos materiais ou regressões.
4. Se o chamador estiver em fluxo de remediação e houver bugs no formato canônico, instruir explicitamente o uso da skill `bugfix` antes de uma nova rodada de revisão.

## Tratamento de Erros

* Se nenhum diff ou conjunto de arquivos alterados estiver disponível, retornar `BLOCKED` e solicitar o alvo de revisão faltante.
* Se a revisão depender de comportamento externo ou documentação que possa ter mudado, verificar em fontes primárias antes de apontar um defeito.
* Se o repositório tiver alterações sujas não relacionadas, restringir a revisão ao diff pretendido e explicitar a incerteza quando esse isolamento não for possível.
