## Prompt Enriquecido

```text
Você deve atuar como revisor técnico sênior de engenharia de software e analisar o projeto atual com rigor, objetividade e foco em viabilidade prática.

Objetivo:
Avaliar a base com ênfase em:
1. robustez operacional e de manutenção;
2. custo de contexto e consumo de tokens por agentes;
3. eficiência de execução e de fluxo de trabalho;
4. maturidade de harness para automação e validação;
5. maturidade spec-driven e capacidade de evolução disciplinada.

Escopo obrigatório:
- considerar explicitamente o uso do projeto com Claude Code, Codex, Copilot CLI e Gemini CLI;
- limitar a análise a artefatos, fluxos, scripts, convenções, validações e documentação relacionados apenas a Go, Node.js e Python;
- ignorar recomendações centradas em outras linguagens, stacks ou runtimes, exceto quando afetarem diretamente o fluxo dessas três linguagens;
- preservar o contexto real do repositório e não inventar ferramentas, versões, integrações ou garantias não verificáveis.

Critérios de análise:
- robustez: previsibilidade, isolamento de falhas, clareza de contratos, validação, tratamento de erro, segurança operacional e risco de regressão;
- custo de tokens: tamanho de instruções, duplicação de contexto, necessidade de leitura recorrente, carga obrigatória por tarefa, volume de regras, fragmentação excessiva e potencial de compressão sem perda de controle;
- eficiência: tempo para entender, executar, validar e evoluir tarefas; clareza do caminho feliz; overhead operacional; custo-benefício das salvaguardas;
- harness: presença, qualidade e acionabilidade de scripts, workflows, validações, gates, smoke tests, testes direcionados, detecção de toolchain e mecanismos de enforcement;
- spec-driven: existência e uso disciplinado de PRD, especificação técnica, tasks, critérios de aceitação, rastreabilidade entre especificação e execução, e capacidade de evolução incremental.

Instruções obrigatórias:
- seja técnico, direto e opinativo, sem linguagem promocional;
- diferencie fatos observáveis de inferências;
- sempre explicite trade-offs entre robustez, economia de tokens e eficiência;
- priorize a menor mudança segura que aumente robustez e reduza custo operacional;
- quando estimar economia de tokens, informe a hipótese usada;
- não implemente automaticamente nenhuma melhoria;
- ao final, pergunte explicitamente se o usuário deseja que as melhorias priorizadas sejam aplicadas;
- se o usuário autorizar implementação, então implemente, valide `.github/workflows/test.yml` e informe o status final.

Formato obrigatório da resposta em PT-BR:

## Pontos Fortes
- liste os principais pontos fortes observados.

## Economia de Tokens
- estime desperdícios e oportunidades de redução;
- apresente estimativas por faixa quando não for possível medir com precisão;
- explicite impacto esperado em prompts, contexto carregado e repetição operacional.

## Fragilidades
- liste fragilidades estruturais, operacionais e de manutenção.

## Gaps para Harness
- descreva lacunas em scripts, validações, workflows, enforcement e repetibilidade.

## Maturidade Spec-Driven e Evolução
- avalie o estado atual;
- explique o que já existe, o que falta e o que impede maior disciplina de execução;
- comente a aderência para Claude Code, Codex, Copilot CLI e Gemini CLI quando relevante.

## Plano de Evolução
- proponha uma sequência incremental e pragmática;
- ordene por maior relação impacto/risco/custo;
- mantenha o plano compatível com robustez e economia sem perda de eficiência.

## Scoring
- atribua notas de 0 a 10 para:
  - robustez;
  - economia de tokens;
  - eficiência operacional;
  - maturidade harness;
  - maturidade spec-driven;
  - prontidão multi-agente (Claude Code, Codex, Copilot CLI e Gemini CLI);
- justifique cada nota de forma objetiva;
- apresente uma nota geral final de 0 a 10 com justificativa consolidada.

## Tabela de Melhorias
Apresente uma tabela Markdown com as colunas exatas:
| melhoria | tipo | impacto | risco | custo (tokens) | motivador |

Regras da tabela:
- `tipo`: usar apenas `robustez`, `tokens`, `eficiência`, `harness`, `spec-driven` ou `multi-agente`;
- `impacto`: usar apenas `alto`, `médio` ou `baixo`;
- `risco`: usar apenas `alto`, `médio` ou `baixo`;
- `custo (tokens)`: estimar se a melhoria tende a reduzir, manter ou aumentar consumo, com breve noção quantitativa quando possível;
- `motivador`: explicar a causa raiz da recomendação.

Critérios de qualidade da resposta:
- não repetir diagnóstico com palavras diferentes;
- não sugerir abstrações desnecessárias;
- não propor burocracia spec-driven sem ganho operacional claro;
- não sacrificar robustez para reduzir tokens;
- não sacrificar eficiência para aumentar formalismo;
- manter foco no que é aplicável ao repositório analisado.

Fechamento obrigatório:
Finalize com a pergunta:
"Deseja que eu aplique as melhorias priorizadas? Se autorizar, implemento, valido `.github/workflows/test.yml` e informo o status."
```

## Justificativa do Enriquecimento

| adição | justificativa |
|---|---|
| papel explícito de revisor técnico sênior | reduz ambiguidade de tom e aumenta rigor analítico |
| objetivo quebrado em cinco eixos | evita respostas genéricas e organiza critérios de avaliação |
| escopo limitado a Go, Node.js e Python | elimina deriva para outras stacks e reduz resposta irrelevante |
| menção explícita a Claude Code, Codex, Copilot CLI e Gemini CLI | força comparação multi-agente em vez de análise mono-ferramenta |
| critérios claros para robustez, tokens, eficiência, harness e spec-driven | melhora previsibilidade e consistência da avaliação |
| distinção entre fatos e inferências | reduz afirmações especulativas |
| instrução para explicitar hipóteses de economia de tokens | torna estimativas auditáveis |
| scoring por dimensão e nota final | facilita comparação objetiva e priorização |
| tabela com valores controlados | aumenta padronização e utilidade prática do resultado |
| fechamento obrigatório perguntando se deseja aplicar | garante que não haja implementação automática |

## Variante Curta

Use esta versão quando quiser um prompt mais compacto, com menor custo de contexto, mantendo a mesma intenção:

```text
Analise este projeto com rigor técnico, em PT-BR, focando apenas em Go, Node.js e Python. Considere explicitamente o uso com Claude Code, Codex, Copilot CLI e Gemini CLI.

Avalie:
- robustez;
- custo de tokens;
- eficiência operacional;
- maturidade de harness;
- maturidade spec-driven.

Diferencie fatos de inferências. Seja direto. Não invente contexto não verificável.

Responda com:
1. pontos fortes;
2. economia de tokens com estimativas e hipóteses;
3. fragilidades;
4. gaps para harness;
5. maturidade spec-driven e evolução;
6. plano de evolução incremental;
7. scoring de 0 a 10 por dimensão e nota geral, com justificativa.

Inclua uma tabela Markdown com:
| melhoria | tipo | impacto | risco | custo (tokens) | motivador |

Tipos permitidos: robustez, tokens, eficiência, harness, spec-driven, multi-agente.

Mantenha robustez e economia sem perder eficiência. Não implemente automaticamente.

Ao final, pergunte:
"Deseja que eu aplique as melhorias priorizadas? Se autorizar, implemento, valido `.github/workflows/test.yml` e informo o status."
```
