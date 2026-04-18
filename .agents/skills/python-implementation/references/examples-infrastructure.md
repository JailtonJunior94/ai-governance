# Exemplos: Infraestrutura

## Graceful Shutdown (FastAPI + uvicorn)
```python
# src/main.py
import asyncio
import signal
import uvicorn
from contextlib import asynccontextmanager
from fastapi import FastAPI
from infra.db import engine


@asynccontextmanager
async def lifespan(app: FastAPI):
    # startup
    yield
    # shutdown
    await engine.dispose()


app = FastAPI(lifespan=lifespan)


def main() -> None:
    loop = asyncio.new_event_loop()

    config = uvicorn.Config(app, host="0.0.0.0", port=8000, loop="none")
    server = uvicorn.Server(config)

    def handle_signal(sig: int, _) -> None:
        loop.call_soon_threadsafe(server.should_exit.__setattr__, "value", True)

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)

    loop.run_until_complete(server.serve())
```

## Pagination — Cursor-based
```python
# infra/order/repository.py
from dataclasses import dataclass


@dataclass(frozen=True)
class PaginatedResult[T]:
    items: list[T]
    next_cursor: str | None
    has_more: bool


async def list_orders(
    cursor: str | None = None, limit: int = 20
) -> PaginatedResult[Order]:
    if cursor:
        query = "SELECT id, status, total FROM orders WHERE id > $1 ORDER BY id ASC LIMIT $2"
        rows = await db.fetch(query, cursor, limit + 1)
    else:
        query = "SELECT id, status, total FROM orders ORDER BY id ASC LIMIT $1"
        rows = await db.fetch(query, limit + 1)

    has_more = len(rows) > limit
    items = rows[:limit] if has_more else rows
    next_cursor = items[-1]["id"] if has_more else None

    return PaginatedResult(items=items, next_cursor=next_cursor, has_more=has_more)
```

## Versionamento de API por path (FastAPI)
```python
# src/api/router.py
from fastapi import APIRouter
from api.v1.order import router as order_v1
from api.v2.order import router as order_v2

api_router = APIRouter()
api_router.include_router(order_v1, prefix="/v1/orders", tags=["orders-v1"])
api_router.include_router(order_v2, prefix="/v2/orders", tags=["orders-v2"])
```
