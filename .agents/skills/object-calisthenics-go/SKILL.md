---
name: object-calisthenics-go
version: 1.0.0
description: Aplica heuristicas de object calisthenics em codigo Go por meio de refatoracoes pequenas com preservacao de comportamento, criterios de revisao e passos de validacao adaptados a packages, structs, interfaces, metodos e tratamento de erro. Use quando o codigo Go precisar de melhoria incremental de desenho, menor complexidade, responsabilidades mais estreitas ou orientacao de revisao baseada em regras. Nao use para definicao de escopo de funcionalidade, migracao de framework, reescritas amplas ou mudancas que exijam quebra de API publica sem aprovacao explicita.
---

# Object Calisthenics Go

## Procedimentos

**Etapa 1: Carregar a base proporcional ao modo**
1. Ler `AGENTS.md`.
2. Executar `bash scripts/list-go-files.sh` para confirmar a superficie Go candidata dentro do contexto atual.
3. Parar se nao houver arquivos Go relevantes ou se a solicitacao nao estiver limitada o suficiente para uma mudanca segura.
4. Se o modo for `review` (sem edicao): carregar apenas `references/rules.md` e `references/evaluation-guide.md`. Nao carregar `agent-governance/SKILL.md` nem `go-implementation/SKILL.md` — o custo de contexto nao se justifica para avaliacao sem alteracao.
5. Se o modo for `execution`: carregar `.agents/skills/agent-governance/SKILL.md` e `.agents/skills/go-implementation/SKILL.md` antes de alterar codigo Go.

**Etapa 2: Delimitar o alvo da calibragem**
1. Identificar o menor conjunto de arquivos, tipos, funcoes e testes que concentra o problema.
2. Mapear comportamento publico, invariantes, dependencias, pontos de integracao e risco de regressao.
3. Classificar a solicitacao em um dos modos:
   - `review`: avaliar o desenho atual sem editar
   - `execution`: aplicar refatoracao incremental
4. Tratar o modo como `review` por padrao quando a solicitacao nao pedir alteracao explicita.

**Etapa 3: Carregar apenas as referencias necessarias**
1. Em modo `review`, `references/rules.md` e `references/evaluation-guide.md` ja foram carregados na Etapa 1.
2. Ler `references/go-mapping.md` quando a duvida estiver em como traduzir uma heuristica para packages, structs, interfaces, errors, slices, maps ou funcoes.
3. Ler `assets/result-template.md` apenas quando for preciso materializar a saida final em formato consistente.
4. Em modo `execution`, ler `references/rules.md` e `references/evaluation-guide.md` se ainda nao carregados.

**Etapa 4: Avaliar antes de refatorar**
1. Confirmar quais regras melhoram clareza e isolamento no contexto real.
2. Tratar as regras como heuristicas e nao como restricoes absolutas.
3. Preservar contratos publicos, nomes estaveis, semantica de erro e comportamento observavel, salvo quando a mudanca explicitar o contrario.
4. Priorizar a menor mudanca segura que reduza complexidade acidental.
5. Evitar aplicar varias regras ao mesmo tempo quando uma unica extracao, renomeacao ou separacao resolver o problema dominante.

**Etapa 5: Executar a melhoria em modo incremental**
1. Em `review`:
   - identificar quais regras estao sendo violadas de forma material
   - apontar risco, impacto e menor ajuste seguro
   - evitar recomendacoes vagas como "usar clean architecture" sem necessidade concreta
2. Em `execution`:
   - aplicar a menor refatoracao segura por vez
   - preferir extracao de funcao, extracao de tipo, encapsulamento local, composicao simples e reducao de branching
   - atualizar ou adicionar testes quando houver risco de regressao
   - interromper se a proxima melhoria exigir quebra de API publica, mudanca transversal ou redesenho amplo

**Etapa 6: Validar de forma proporcional**
1. Rodar formatter nos arquivos alterados.
2. Rodar primeiro testes direcionados aos packages afetados.
3. Rodar testes mais amplos quando o custo for proporcional ao risco.
4. Rodar lint quando o projeto oferecer esse passo.
5. Registrar falhas com comando exato e diagnostico curto.

**Etapa 7: Retornar a conclusao**
1. Informar o modo aplicado, as regras mais relevantes, os arquivos afetados e a validacao executada.
2. Explicitar quando uma recomendacao foi rejeitada por custo, risco, idiomatismo Go ou preservacao de contrato.
3. Se produzir um parecer estruturado, usar `assets/result-template.md` como base.

## Tratamento de Erros
* Se `bash scripts/list-go-files.sh` nao encontrar arquivos Go, parar antes de assumir que a skill se aplica.
* Se a codebase depender de estilo idiomatico Go que conflite com uma heuristica classica, priorizar o idiomatismo local e registrar a adaptacao.
* Se uma regra empurrar a solucao para indirecao, excesso de interfaces ou fragmentacao artificial, recuar e manter a alternativa mais simples.
* Se nao houver testes suficientes para sustentar uma refatoracao arriscada, reduzir o escopo ou adicionar cobertura antes de prosseguir.
* Se a solicitacao pedir varias regras ao mesmo tempo em uma area grande do sistema, decompor por package, agregado ou fluxo e executar iterativamente.
