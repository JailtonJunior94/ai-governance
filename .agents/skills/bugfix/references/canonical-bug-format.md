# Formato Canonico de Bug

Use cada bug como um objeto com os campos abaixo:

```json
{
  "id": "BUG-001",
  "severity": "critical",
  "file": "internal/service/foo.go",
  "line": 42,
  "reproduction": "Executar X com Y e observar Z",
  "expected": "Resultado esperado",
  "actual": "Resultado observado"
}
```

## Campos Obrigatorios
- `id`: identificador estavel do bug.
- `severity`: usar apenas `critical`, `major` ou `minor`.
- `file`: arquivo principal do defeito.
- `line`: linha aproximada do problema.
- `reproduction`: cenario minimo para reproduzir o defeito.
- `expected`: comportamento esperado.
- `actual`: comportamento atual observado.

## Estados Canonicos de Processamento
- `fixed`: correcao aplicada e validada.
- `blocked`: depende de contexto externo indisponivel.
- `skipped`: fora do escopo acordado.
- `failed`: limite de remediacao excedido ou validacao inconclusiva.
