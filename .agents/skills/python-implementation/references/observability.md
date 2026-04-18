# Observabilidade Python

## Objetivo
Garantir rastreabilidade, diagnostico e visibilidade operacional em producao.

## Diretrizes

### Logging Estruturado
- Usar logging estruturado (JSON) com campos consistentes: `level`, `msg`, `error`, `trace_id`, `request_id`.
- Preferir `structlog` como default. Usar `logging` stdlib com formatador JSON quando structlog nao estiver disponivel.
- Logar em fronteiras de IO, erros e decisoes de negocio relevantes — nao em cada linha.
- Nao logar dados sensiveis: tokens, senhas, PII, corpos de request com dados pessoais.
- Usar niveis com intencao: `DEBUG` para desenvolvimento, `INFO` para eventos operacionais, `WARNING` para degradacao tolerada, `ERROR` para falha que exige atencao.

### Tracing Distribuido
- Preferir OpenTelemetry SDK como instrumentacao padrao.
- Criar spans em operacoes com latencia relevante: chamadas HTTP, queries, filas, cache.
- Propagar context de trace entre servicos via headers padrao (W3C Trace Context).

### Metricas
- Expor metricas basicas: request count, latencia (histograma), error rate.
- Usar labels com cardinalidade controlada.
- Preferir prometheus_client ou OTel metrics API.

### Health Checks
- Expor endpoint de liveness e readiness.
- Liveness nao deve verificar dependencias externas.
- Readiness deve verificar conexoes criticas: banco, cache, filas.

## Proibido
- `print()` em codigo de producao.
- Logar tokens, segredos ou PII.
- Metrica com label derivado de input do usuario sem sanitizacao.
