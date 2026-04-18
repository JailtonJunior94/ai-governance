# Graceful Lifecycle

## Objetivo
Unificar padroes de inicializacao ordenada e encerramento gracioso para servidores ASGI/WSGI, workers e CLIs Python.

## Diretrizes

### Inicializacao
- Ordem explicita: config -> logger -> telemetry -> database -> cache -> messaging -> server.
- Fail fast se dependencia obrigatoria indisponivel. Readiness probe antes de servir trafego.

### Sinais e Cancelamento
- `signal.signal()` ou `loop.add_signal_handler()` para SIGTERM/SIGINT.

```python
async def shutdown(loop: asyncio.AbstractEventLoop, sig: signal.Signals) -> None:
    tasks = [t for t in asyncio.all_tasks() if t is not asyncio.current_task()]
    for task in tasks:
        task.cancel()
    await asyncio.gather(*tasks, return_exceptions=True)
    loop.stop()

for sig in (signal.SIGTERM, signal.SIGINT):
    loop.add_signal_handler(sig, lambda s=sig: asyncio.create_task(shutdown(loop, s)))
```

### Shutdown ASGI (uvicorn/gunicorn)
- Timeout de shutdown < `terminationGracePeriodSeconds`. Usar lifespan events para cleanup.

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI

@asynccontextmanager
async def lifespan(app: FastAPI):
    db = await create_pool()
    yield
    await db.close()
    await flush_telemetry()

app = FastAPI(lifespan=lifespan)
```

### Workers/Consumers
- Celery: `worker_shutdown` signal. Kafka/RabbitMQ: parar consumo, processar in-flight.
- Threads/tasks: verificar `threading.Event` ou `asyncio.Event` para encerrar.

### Shutdown de Dependencias
- Fechar na ordem inversa. Context managers (`async with`) para cleanup. Flush telemetry antes.

## Riscos Comuns
- Shutdown abrupto = 502. Timeout > terminationGracePeriodSeconds.
- Tasks pendentes nao canceladas. Telemetry perdida. Consumer commitando offset nao-processado.

## Proibido
- Processo sem signal handler. Task sem cancelamento. `os._exit()` fora de ultimo recurso.
- Ignorar erro de shutdown. Servir trafego antes de ready.
