# Resiliencia Python

## Objetivo
Orientar implementacao de retries, circuit breakers, timeouts e fallbacks em servicos Python.

## Timeouts
- Toda chamada externa deve ter timeout explicito.
- `httpx`: usar `timeout=httpx.Timeout(5.0)` na instancia do client.
- `requests`: usar `timeout=(connect_timeout, read_timeout)`, ex: `timeout=(3, 10)`.
- `asyncio`: usar `asyncio.wait_for(coro, timeout=5.0)` para qualquer coroutine.
- `aiohttp`: configurar `ClientTimeout(total=10)` no session.
- Nunca usar timeout `None` em chamadas de producao.

## Retries
- Aplicar retry apenas em erros transitorios (5xx, timeout, ConnectionError), nunca em 4xx.
- Usar backoff exponencial com jitter.
- Lib recomendada: `tenacity` — madura, flexivel, suporta sync e async.
  ```python
  from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

  @retry(
      stop=stop_after_attempt(3),
      wait=wait_exponential(multiplier=1, min=1, max=10),
      retry=retry_if_exception_type((ConnectionError, TimeoutError)),
  )
  async def fetch_with_retry(client: httpx.AsyncClient, url: str) -> httpx.Response:
      response = await client.get(url)
      response.raise_for_status()
      return response
  ```
- Alternativa sem dependencia:
  ```python
  import asyncio
  import random

  async def with_retry(fn, max_attempts=3, base_delay=0.2):
      for attempt in range(1, max_attempts + 1):
          try:
              return await fn()
          except Exception:
              if attempt == max_attempts:
                  raise
              delay = base_delay * (2 ** (attempt - 1)) * (0.5 + random.random() * 0.5)
              await asyncio.sleep(delay)
  ```
- Limitar tentativas (3-5) e logar cada retry com contexto.

## Circuit Breaker
- Usar quando falhas repetidas em servico externo degradam o sistema.
- Lib recomendada: `pybreaker`.
  ```python
  import pybreaker

  breaker = pybreaker.CircuitBreaker(fail_max=5, reset_timeout=60)

  @breaker
  def call_external_service():
      ...
  ```
- Estados: closed -> open -> half-open.
- Configurar: threshold de falhas, timeout de reset, fallback.

## Fallbacks
- Definir resposta degradada para funcionalidades nao-criticas.
- Monitorar ativacao de fallback — nao usar como substituto permanente.
- Fallback deve ser mais simples e rapido que o caminho principal.

## Health Checks
- `/health` ou `/healthz`: 200 se o servico esta operacional.
- `/ready`: valida dependencias (DB, cache) e retorna 503 se indisponivel.
- Nao depender de servico externo nao-critico no health check.

## Proibido
- Retry infinito sem backoff.
- Timeout `None` ou ausente em chamada externa.
- Swallow de excecao em retry sem logging.
- Circuit breaker sem fallback definido.
