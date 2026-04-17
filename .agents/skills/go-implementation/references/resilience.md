# Resiliência

## Objetivo
Proteger o sistema contra falhas transitórias e degradação em dependências externas.

## Diretrizes

### Timeouts
- Definir timeout explícito em toda chamada de rede, banco ou serviço externo.
- Propagar timeout via `context.WithTimeout` — não usar timeouts de cliente desconectados do context.
- Timeout do caller deve ser menor que o timeout do serviço chamado para evitar retry em cascata.

### Retries
- Retry apenas para erros transitórios (timeout, 503, connection reset) — nunca para 4xx ou erros de lógica.
- Usar backoff exponencial com jitter para evitar thundering herd.
- Definir número máximo de tentativas (geralmente 2-3).
- Respeitar `context.Context` — abortar retries se o context for cancelado.
- Tornar operações retryable idempotentes ou garantir idempotência no receptor.

### Circuit Breaker
- Usar circuit breaker quando uma dependência degradada puder derrubar o caller por esgotamento de recursos.
- Configurar thresholds explícitos: percentual de falha, janela de observação, tempo em estado aberto.
- Retornar erro claro quando o circuito estiver aberto — não bloquear a goroutine.
- Não usar circuit breaker para dependências que já têm timeout curto e retry limitado.

### Fallbacks
- Preferir degradação graceful (cache stale, resposta parcial, default seguro) a falha total quando o domínio permitir.
- Não mascarar falhas — logar o erro original mesmo quando o fallback for ativado.

## Riscos Comuns
- Retry sem backoff causando amplificação de carga em serviço degradado.
- Timeout ausente em chamada HTTP deixando goroutine pendurada.
- Circuit breaker com threshold muito sensível abrindo em picos normais de latência.
- Retry em erro não-transitório (400, 409) desperdiçando recursos.

## Proibido
- Chamada de rede sem timeout.
- Retry infinito ou sem limite de tentativas.
- Ignorar cancelamento de context durante retry loop.
