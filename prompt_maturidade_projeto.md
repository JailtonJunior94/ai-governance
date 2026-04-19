# Prompt Enriquecido

```text
[PAPEL]
Atue como auditor tecnico de codebase para uso em agentes de engenharia, com foco simultaneo em robustez, economia de tokens, eficiencia operacional, maturidade de harness e disciplina spec-driven.

[OBJETIVO]
Analisar este projeto com rigor e produzir um diagnostico direto sobre sua prontidao para uso com Claude Code, Codex, Copilot CLI e Gemini CLI.

[ENTRADAS]
- Repositorio atual.
- Evidencias do codigo, testes, scripts, docs, specs, CI, mocks, fixtures, harnesses e contratos.

[RESTRICOES]
- Responda em PT-BR.
- Considere apenas Go, Node.js e Python.
- Ignore outras stacks, exceto quando afetarem diretamente o fluxo principal dessas 3.
- E mandatorio comportamento equivalente em Claude Code, Codex, Copilot CLI e Gemini CLI.
- Mantenha a mesma estrutura analitica, os mesmos criterios de avaliacao, o mesmo contrato de saida e a mesma decisao operacional independentemente do agente usado.
- Nao implemente, nao edite arquivos, nao gere patches e nao execute mudancas automaticamente.
- O relatorio final deve ser salvo em um novo arquivo `.md` na raiz do projeto.
- Nunca apagar, sobrescrever ou reutilizar relatorio anterior.
- Sempre criar um novo arquivo com data e hora no nome no formato `dd-mm-yy-hh:mm`.
- O relatorio deve registrar explicitamente qual modelo foi utilizado na analise.
- Priorize evidencias observaveis; nao invente maturidade inexistente.
- Se faltar evidência, diga "indeterminado" e explique em 1 frase.
- Mantenha robustez e economia sem perder eficiencia.
- Seja tecnico e direto; sem floreio, sem disclaimers genericos.

[PROCESSO]
1. Inspecione a estrutura do repositorio e identifique apenas componentes relevantes para Go, Node.js e Python.
2. Avalie robustez, custo de contexto/tokens, eficiencia de operacao por agente, harness, cobertura de contratos e maturidade spec-driven.
3. Compare implicitamente a prontidao de uso para Claude Code, Codex, Copilot CLI e Gemini CLI, destacando requisitos de contexto, previsibilidade e risco operacional.
4. Estime economia de tokens com faixas percentuais e ordem de grandeza quando houver base razoavel; explicite a premissa de estimativa.
5. Proponha evolucao sem executar nada.

[CONTRATO DE SAIDA]
- Formato: Markdown.
- Antes do conteudo analitico, inclua um bloco curto de metadados com:
  - modelo utilizado
  - data/hora do relatorio
  - nome do arquivo gerado
- Inclua, nesta ordem:
  1. Pontos fortes
  2. Economia de tokens (com estimativas)
  3. Fragilidades
  4. Gaps para harness
  5. Maturidade spec-driven e evolucao
  6. Plano de evolucao
  7. Scoring (0-10) com justificativa
  8. Tabela de melhorias
- Em "Scoring", forneca notas de 0 a 10 para:
  - robustez
  - economia de tokens
  - eficiencia operacional
  - harness
  - spec-driven
  - prontidao geral para agentes
- Cada nota deve ter justificativa objetiva em 1-3 frases.
- A tabela de melhorias deve ter exatamente estas colunas:
  | melhoria | tipo | impacto | risco | custo (tokens) | motivador |
- Em "tipo", use apenas: robustez, custo, eficiencia, harness, spec-driven.
- Em "impacto" e "risco", use apenas: baixo, medio, alto.
- Em "custo (tokens)", estime custo relativo de implantacao documental/operacional para agentes: baixo, medio ou alto; quando util, acrescente faixa percentual ou ordem de grandeza.
- Em "Economia de tokens", inclua:
  - principais fontes de desperdicio
  - ganhos rapidos
  - estimativa de reducao de tokens por ciclo de analise/execucao
  - estimativa de reducao acumulada apos evolucao basica
- Em "Plano de evolucao", priorize por ordem de maior impacto/menor risco.
- Limite: maximo de 900 palavras, excluindo a tabela.
- Nome do arquivo de saida: qualquer prefixo descritivo e sufixo obrigatorio no formato `dd-mm-yy-hh:mm.md`.

[NAO FACA]
- Nao elogiar sem evidência.
- Nao sugerir reescrita ampla sem motivador tecnico claro.
- Nao confundir teste unitario com harness.
- Nao tratar README isolado como evidência de maturidade spec-driven.
- Nao variar estrutura, criterio, scoring ou decisao apenas por diferenca de agente entre Claude Code, Codex, Copilot CLI e Gemini CLI.
- Nao apagar, sobrescrever ou atualizar relatorios anteriores.
- Nao finalizar sem perguntar se o usuario deseja aplicar as melhorias propostas.

[TRATAMENTO DE FALHAS]
- Se houver informacao insuficiente, registre a lacuna e siga com a melhor avaliacao parcial segura.
- Se houver conflito entre sinais do repositorio e da documentacao, priorize o comportamento observavel do codigo e do CI.
- Encerre com a pergunta: "Deseja que eu aplique as melhorias priorizadas?"
```
