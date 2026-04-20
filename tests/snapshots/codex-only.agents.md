<!-- governance-schema: 1.1.0 -->
# Regras para Agentes de IA

Este diretorio centraliza regras para uso com agentes de IA em tarefas reais de analise, alteracao e validacao de codigo.

## Objetivo

Use estas instrucoes para manter consistencia, seguranca e qualidade ao trabalhar com codigo, configuracao, validacao e evolucao de sistemas.

## Arquitetura: monolito

O projeto aparenta ser um monolito unico. A governanca deve privilegiar coesao local, limites de pacote claros e crescimento incremental da estrutura.

Stack detectada: Go.
Frameworks detectados: nenhum framework dominante identificado.

## Estrutura de Pastas

```
go.mod
```

## Padrao Arquitetural

Padrao arquitetural nao inferido com alta confianca; assumir composicao simples e dependencias explicitas.

### Fluxo de Dependencias

- Transporte e adapters devem depender de casos de uso ou servicos explicitos, nao do contrario.
- Dominio nao deve conhecer detalhes de HTTP, banco, filas, serializacao ou drivers.
- Infraestrutura pode implementar contratos consumidos pela aplicacao, preservando dependencia para dentro.

## Modo de trabalho

1. Entender o contexto antes de editar qualquer arquivo.
2. Preferir a menor mudanca segura que resolva a causa raiz.
3. Preservar arquitetura, convencoes e fronteiras ja existentes no contexto analisado.
4. Nao introduzir abstracoes, camadas ou dependencias sem demanda concreta.
5. Atualizar ou adicionar testes quando houver mudanca de comportamento.
6. Rodar validacoes proporcionais a mudanca.
7. Registrar bloqueios e suposicoes explicitamente quando o contexto estiver incompleto.

## Regras por Arquitetura

1. Preservar coesao local e dependencia unidirecional entre packages.
2. Evitar helpers transversais que escondam regra de negocio ou IO.
3. Crescer a estrutura apenas quando o codigo atual ja nao comportar a mudanca com clareza.

## Regras por Linguagem

Para tarefas que alteram codigo, carregar a skill:

- `.agents/skills/agent-governance/SKILL.md`

Para tarefas que alteram codigo Go, carregar tambem:

- `.agents/skills/go-implementation/SKILL.md`

Para tarefas de revisao ou refatoracao incremental de design em Go guiadas por heuristicas de object calisthenics, carregar tambem:

- `.agents/skills/object-calisthenics-go/SKILL.md`

Para tarefas de correcao de bugs com remediacao e teste de regressao, carregar tambem:

- `.agents/skills/bugfix/SKILL.md`

## Referencias

Cada skill lista suas proprias referencias em `references/` com gatilhos de carregamento no respectivo `SKILL.md`. Nao duplicar a listagem aqui — consultar o SKILL.md da skill ativa para saber quais referencias carregar e em que condicao.

## Notas por Ferramenta

- **Claude Code**: skills pre-carregadas via `.claude/skills/`, hooks via `.claude/hooks/`, agents delegados via `.claude/agents/`.
- **Gemini CLI**: commands em `.gemini/commands/*.toml` apontam para skills canonicas. Sem hooks ou agents nativos — o modelo deve seguir as instrucoes procedurais do SKILL.md carregado.
- **Codex**: le `AGENTS.md` como instrucao de sessao. Entradas em `.codex/config.toml` sao metadados para `upgrade.sh`, nao spec oficial do Codex CLI. O agente deve seguir as instrucoes de `AGENTS.md` para descobrir e carregar skills.
- **Copilot**: `.github/copilot-instructions.md` como instrucao principal. `.github/agents/` sao wrappers. Sem hooks nativos — compliance depende do modelo seguir as instrucoes.

### Matrix de Enforcement

| Capacidade | Claude Code | Gemini CLI | Codex | Copilot |
|---|---|---|---|---|
| Carga base automatica | hook PreToolUse | procedural | procedural | procedural |
| Protecao de governanca | hook PostToolUse | procedural | procedural | procedural |
| Skills pre-carregadas | sim (symlinks) | sim (commands) | nao | sim (agents) |
| Enforcement programatico | sim (hooks) | nao | nao | nao |
| Validacao de evidencias | script | procedural | procedural | procedural |

Ferramentas sem enforcement programatico dependem do modelo seguir instrucoes procedurais. A compliance nessas ferramentas e best-effort.

## Validacao

Antes de concluir uma alteracao:

Seguir Etapa 4 de `.agents/skills/agent-governance/SKILL.md` como base canonica.

Comandos detectados no projeto (Go):
1. Rodar fmt: `gofmt -w .`.
2. Rodar test: `go test ./...`.
3. Rodar lint: `golangci-lint run`.

## Restricoes

1. Nao inventar contexto ausente.
2. Nao assumir versao de linguagem, framework ou runtime sem verificar.
3. Nao alterar comportamento publico sem deixar isso explicito.
4. Nao usar exemplos como copia cega; adaptar ao contexto real.
