# Concorrencia Python

## Objetivo
Orientar uso correto de asyncio, threading, multiprocessing e controle de fluxo concorrente em Python.

## asyncio
- Usar `asyncio` para IO-bound concorrente (HTTP, DB, filas, filesystem async).
- Preferir `async/await` sobre callbacks ou futures manuais.
- `asyncio.gather()` para executar coroutines independentes em paralelo.
- `asyncio.TaskGroup` (Python 3.11+) como alternativa mais segura a `gather` — cancela tasks restantes em caso de erro.
  ```python
  async with asyncio.TaskGroup() as tg:
      task1 = tg.create_task(fetch_user(user_id))
      task2 = tg.create_task(fetch_orders(user_id))
  user, orders = task1.result(), task2.result()
  ```
- Nao usar `asyncio.run()` dentro de funcao ja async — causa erro de event loop aninhado.
- Nao misturar chamadas sync bloqueantes (ex: `requests.get`) dentro de funcoes async sem `run_in_executor`.

## Controle de Concorrencia
- `asyncio.Semaphore` para limitar concorrencia de operacoes async:
  ```python
  sem = asyncio.Semaphore(10)
  async def limited_fetch(url: str) -> Response:
      async with sem:
          return await client.get(url)
  ```
- Default seguro: 5-10 operacoes concorrentes para chamadas externas.
- Para processamento em lote, usar `asyncio.as_completed()` para processar resultados conforme ficam prontos.

## Threading
- Usar `threading` para IO-bound quando asyncio nao for viavel (libs sync-only).
- `concurrent.futures.ThreadPoolExecutor` com `max_workers` explicito.
- Nao usar threads para CPU-bound — GIL impede paralelismo real em CPython.
- Preferir `threading.Event` e `queue.Queue` sobre locks manuais quando possivel.

## Multiprocessing
- Usar `multiprocessing` ou `concurrent.futures.ProcessPoolExecutor` para CPU-bound (compressao, parsing pesado, ML inference).
- Dados passados entre processos sao serializados via pickle — evitar objetos grandes ou nao-serializaveis.
- `ProcessPoolExecutor` e mais simples que `multiprocessing.Pool` para casos comuns.
- Fechar pools explicitamente (`executor.shutdown()`) para evitar processos orfaos.

## Patterns Comuns
- Producer-consumer: `asyncio.Queue` para async, `queue.Queue` para threads.
- Fan-out/fan-in: `gather()` ou `TaskGroup` para fan-out, agregacao manual para fan-in.
- Graceful shutdown: capturar `SIGTERM`/`SIGINT` e cancelar tasks pendentes antes de encerrar o loop.

## Proibido
- Chamar funcao sync bloqueante dentro de coroutine async sem `loop.run_in_executor()`.
- `asyncio.sleep(0)` em loop como substituto de yield — usar `asyncio.sleep` com valor real ou redesenhar.
- Compartilhar estado mutavel entre threads sem sincronizacao.
- `multiprocessing` para operacoes IO-bound (overhead de processo desnecessario).
