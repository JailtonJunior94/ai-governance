# Graceful Lifecycle

## Objetivo
Unificar padroes de inicializacao ordenada e encerramento gracioso para servidores ASGI/WSGI, workers e CLIs Python.

## Diretrizes

### Inicializacao
- Inicializar dependencias em ordem explicita: config -> logger -> telemetry -> database -> cache -> messaging -> server.
- Falhar fast se uma dependencia obrigatoria nao estiver disponivel na inicializacao.
- Logar versao e configuracao nao-sensivel no startup para diagnostico.
- Usar readiness probe para sinalizar que o servico esta pronto para receber trafego.

### Sinais e Cancelamento
- Registrar handlers para `SIGTERM` e `SIGINT` com `signal.signal()` ou loop de asyncio.
- Em apps async, usar `loop.add_signal_handler()` para integrar com o event loop.
- Nao usar `sys.exit()` diretamente em threads ou tasks — deixar o shutdown coordenado fluir.

```python
import signal
import asyncio

async def shutdown(loop: asyncio.AbstractEventLoop, sig: signal.Signals) -> None:
    logger.info("received signal %s, shutting down", sig.name)
    tasks = [t for t in asyncio.all_tasks() if t is not asyncio.current_task()]
    for task in tasks:
        task.cancel()
    await asyncio.gather(*tasks, return_exceptions=True)
    loop.stop()

loop = asyncio.get_event_loop()
for sig in (signal.SIGTERM, signal.SIGINT):
    loop.add_signal_handler(sig, lambda s=sig: asyncio.create_task(shutdown(loop, s)))
```

### Shutdown de Servidor ASGI (uvicorn/gunicorn)
- Uvicorn: usar `--timeout-graceful-shutdown` para definir tempo de drain (default: nenhum).
- Gunicorn: configurar `graceful_timeout` (default: 30s). Workers recebem `SIGTERM` e devem finalizar requests ativos.
- Timeout de shutdown deve ser menor que `terminationGracePeriodSeconds` do orquestrador.
- Usar lifespan events do framework (FastAPI `@app.on_event("shutdown")` ou lifespan context manager) para cleanup.

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI

@asynccontextmanager
async def lifespan(app: FastAPI):
    # startup: inicializar recursos
    db = await create_pool()
    yield
    # shutdown: fechar na ordem inversa
    await db.close()
    await flush_telemetry()

app = FastAPI(lifespan=lifespan)
```

### Shutdown de Workers e Consumers
- Celery: usar `worker_shutdown` signal para cleanup. Configurar `worker_max_tasks_per_child` para reciclagem.
- Consumers de fila (Kafka, RabbitMQ): parar de consumir ao receber sinal; processar mensagens em andamento ate o timeout.
- Threads e background tasks devem verificar um `threading.Event` ou `asyncio.Event` para saber quando encerrar.

### Shutdown de Dependencias
- Fechar na ordem inversa de inicializacao: server -> messaging -> cache -> database -> telemetry -> logger.
- Usar context managers (`async with`) para garantir cleanup automatico.
- Flush de telemetry (traces, metrics) antes de fechar o exporter.

### CLIs e Processos Curtos
- Scripts que fazem IO (HTTP calls, queries) devem capturar `KeyboardInterrupt` para cleanup.
- Usar `try/finally` ou context managers para fechar recursos mesmo em processos curtos.

## Riscos Comuns
- Shutdown abrupto cortando requests em andamento (502 no load balancer).
- Timeout de shutdown maior que `terminationGracePeriodSeconds` do orquestrador.
- Asyncio tasks pendentes nao canceladas — `RuntimeWarning: coroutine was never awaited`.
- Telemetry perdida por falta de flush antes do shutdown.
- Consumer que commita offset de mensagem nao-processada durante shutdown.
- `sys.exit()` em thread secundaria nao encerra o processo principal.

## Proibido
- Processo sem handler de sinal — shutdown deve ser sempre coordenado.
- Background task sem mecanismo de cancelamento.
- `os._exit()` fora de cenarios de ultimo recurso.
- Ignorar erro de shutdown — logar mesmo que nao seja recuperavel.
- Servir trafego antes de todas as dependencias estarem prontas.
