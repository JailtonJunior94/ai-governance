# Governança de Regras

- Rule ID: R-GOV-001
- Severidade: hard
- Escopo: `.agents/skills/`, `.claude/rules/` e `.claude/skills/`.

## Objetivo
Definir precedência, resolução de conflitos e critérios de evidência para uso com agentes de IA.

## Fonte de Verdade
- Processos detalhados: `.agents/skills/`
- Regras transversais: `.claude/rules/`
- Referências de governança: `.agents/skills/agent-governance/references/`
- Referências Go: `.agents/skills/go-implementation/references/`

## Precedência
1. Esta governança transversal
2. `.agents/skills/agent-governance/references/security.md`
3. Referências de arquitetura e implementação carregadas pela skill ativa
4. `.agents/skills/agent-governance/references/` (`ddd`, `error-handling`, `tests`)
5. Uber Go Style Guide PT-BR como base transversal (quando aplicável)

Se duas regras do mesmo nível conflitarem:
- prevalece `hard` sobre `guideline`
- se a severidade empatar, prevalece a regra mais restritiva para correção, segurança e determinismo
- convenção explícita local prevalece sobre o guia da Uber quando documentada nas referências
- `go-implementation` prevalece sobre `object-calisthenics-go` quando houver conflito — object calisthenics é ferramenta de revisão e heurística de design, não substitui as diretrizes de implementação. Exemplo prático: `architecture.md` define "preferir tipos concretos por padrão"; OC regra #3 sugere "encapsular primitivos de domínio". Neste caso, encapsular apenas quando o valor carregar invariante de domínio (ex: `OrderID`, `Email`), não para primitivos sem regra de validação

## Política de Evidência
- Toda alteração deve ser justificável pelo PRD, por regra explícita ou por necessidade técnica demonstrável.
- Relatórios devem incluir arquivos alterados, validações executadas, riscos residuais e suposições assumidas.
- Não aprovar solução com lacuna crítica conhecida.

## Segurança Operacional
- Não executar ações de git destrutivas ou publicações remotas sem pedido explícito.
- Se faltar input obrigatório e não houver inferência segura, a execução deve pausar ou falhar de forma explícita.

## Proibido
- Aprovação sem evidência.
- Loops infinitos de remediação.
