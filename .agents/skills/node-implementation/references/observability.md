# Observabilidade Node/TypeScript

## Objetivo
Garantir rastreabilidade, diagnostico e visibilidade operacional em producao.

## Diretrizes

### Logging Estruturado
- Usar logging estruturado (JSON) com campos consistentes: `level`, `msg`, `error`, `traceId`, `requestId`.
- Preferir pino como default por performance. Usar winston quando ja adotado no projeto.
- Logar em fronteiras de IO, erros e decisoes de negocio relevantes — nao em cada linha.
- Nao logar dados sensiveis: tokens, senhas, PII, corpos de request com dados pessoais.
- Usar niveis com intencao: `debug` para desenvolvimento, `info` para eventos operacionais, `warn` para degradacao tolerada, `error` para falha que exige atencao.

### Tracing Distribuido
- Preferir OpenTelemetry SDK como instrumentacao padrao.
- Criar spans em operacoes com latencia relevante: chamadas HTTP, queries, filas, cache.
- Propagar context de trace entre servicos via headers padrao (W3C Trace Context).

### Metricas
- Expor metricas basicas: request count, latencia (histograma), error rate.
- Usar labels com cardinalidade controlada — nunca user ID ou request ID como label.
- Preferir histogramas a summaries para latencia.

### Health Checks
- Expor endpoint de liveness (processo vivo) e readiness (dependencias prontas).
- Liveness nao deve verificar dependencias externas.
- Readiness deve verificar conexoes criticas: banco, cache, filas.

## Proibido
- `console.log` em codigo de producao.
- Logar tokens, segredos ou PII.
- Metrica com label derivado de input do usuario sem sanitizacao.
