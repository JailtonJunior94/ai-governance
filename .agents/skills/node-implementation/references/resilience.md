# Resiliencia Node/TypeScript

## Objetivo
Orientar implementacao de retries, circuit breakers, timeouts e fallbacks em servicos Node.js.

## Timeouts
- Toda chamada externa (HTTP, DB, fila, gRPC) deve ter timeout explicito.
- Para `fetch`: usar `AbortController` com `setTimeout`.
  ```typescript
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);
  try {
    const res = await fetch(url, { signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
  ```
- Para clients HTTP (axios, got): configurar `timeout` na instancia, nao por chamada.
- Default recomendado: 5s para APIs externas, 2s para servicos internos, 30s para operacoes batch.

## Retries
- Aplicar retry apenas em erros transitórios (5xx, timeout, ECONNRESET), nunca em 4xx.
- Usar backoff exponencial com jitter para evitar thundering herd.
- Limitar tentativas (3-5 no maximo) e logar cada retry com contexto.
- Libs recomendadas: `p-retry`, `async-retry`, ou implementacao manual simples:
  ```typescript
  async function withRetry<T>(fn: () => Promise<T>, maxAttempts = 3, baseDelay = 200): Promise<T> {
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await fn();
      } catch (err) {
        if (attempt === maxAttempts) throw err;
        const delay = baseDelay * Math.pow(2, attempt - 1) * (0.5 + Math.random() * 0.5);
        await new Promise(r => setTimeout(r, delay));
      }
    }
    throw new Error("unreachable");
  }
  ```

## Circuit Breaker
- Usar quando falhas repetidas em um servico externo degradam o sistema inteiro.
- Estados: closed (normal) -> open (falhas acima do threshold) -> half-open (teste periodico).
- Libs: `opossum` (mais madura para Node), `cockatiel`.
- Configurar: failure threshold (ex: 5 falhas em 30s), timeout de reset (ex: 60s), fallback response.
- Em half-open, permitir apenas uma request de teste antes de fechar ou reabrir.

## Fallbacks
- Definir resposta degradada para funcionalidades nao-criticas (cache stale, valor default, feature flag off).
- Nao usar fallback como substituto permanente — monitorar e alertar quando fallback estiver ativo.
- Fallback deve ser mais simples e mais rapido que o caminho principal.

## Health Checks
- Endpoint `/health` ou `/healthz`: retorna 200 se o servico esta operacional.
- Endpoint `/ready`: valida dependencias (DB, cache, filas) e retorna 503 se alguma nao responder.
- Nao fazer health check que depende de servico externo nao-critico.

## Proibido
- Retry infinito sem backoff.
- Timeout de 0 ou sem timeout em chamada externa.
- Circuit breaker sem fallback definido (rejeitar requests sem resposta alternativa pode ser pior).
- Swallow de erro em retry: sempre logar a tentativa e o erro original.
