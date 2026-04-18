# Observabilidade

## Objetivo
Garantir rastreabilidade, diagnóstico e visibilidade operacional em produção.

## Diretrizes

### Logging Estruturado
- Usar logging estruturado (JSON) com campos consistentes: `level`, `msg`, `error`, `trace_id`, `span_id`.
- Preferir `slog` (stdlib Go 1.21+) como default. Usar `zap` ou `zerolog` apenas quando já adotados no projeto.
- Logar em fronteiras de IO, erros e decisões de negócio relevantes — não em cada linha.
- Não logar dados sensíveis: tokens, senhas, PII, corpos de request com dados pessoais.
- Usar níveis com intenção: `DEBUG` para desenvolvimento, `INFO` para eventos operacionais, `WARN` para degradação tolerada, `ERROR` para falha que exige atenção.

### Tracing Distribuído
- Propagar `context.Context` com trace/span em todas as fronteiras de IO.
- Preferir OpenTelemetry SDK como instrumentação padrão.
- Criar spans em operações com latência relevante: chamadas HTTP/gRPC, queries, filas, cache.
- Nomear spans pelo papel da operação, não pelo nome do método interno.
- Registrar atributos de negócio no span apenas quando úteis para diagnóstico.

### Métricas
- Expor métricas básicas: request count, latência (histograma), error rate, saturação de recursos.
- Usar labels com cardinalidade controlada — nunca user ID, request ID ou valores unbounded como label.
- Preferir histogramas a summaries para latência.
- Registrar métricas de negócio apenas quando houver necessidade concreta de alerta ou dashboard.

### Runtime Metrics
- Expor métricas de runtime Go (`runtime/metrics` ou via OTel runtime instrumentation): goroutines ativas, heap usage, GC pause.
- Usar essas métricas para detectar leaks de goroutine, pressão de memória e pausas de GC anômalas.

### Deployment de Telemetria
- Preferir OTel Collector como pipeline intermediário entre aplicação e backends de observabilidade.
- Aplicação exporta para o collector via OTLP (gRPC ou HTTP) — não diretamente para backend final.
- Collector permite filtragem, sampling e roteamento sem rebuild da aplicação.

### Health Checks
- Expor endpoint de liveness (processo vivo) e readiness (dependências prontas).
- Liveness não deve verificar dependências externas.
- Readiness deve verificar conexões críticas: banco, cache, filas.

## Riscos Comuns
- Log excessivo em hot path degradando throughput.
- Spans criados em loops internos inflando o volume de traces.
- Labels de métrica com alta cardinalidade causando explosão de séries temporais.
- Health check de readiness sem timeout causando cascata de falha.

## Proibido
- `fmt.Println` ou `log.Println` em código de produção.
- Logar tokens, segredos ou PII.
- Métrica com label derivado de input do usuário sem sanitização.
- Ignorar propagação de context em chamadas entre serviços.
