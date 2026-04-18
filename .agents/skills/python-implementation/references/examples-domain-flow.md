# Exemplos: Fluxo End-to-End Python

## Erros de domínio

```python
# domain/order/errors.py
class OrderNotFoundError(Exception):
    def __init__(self, order_id: str) -> None:
        super().__init__(f"order not found: {order_id}")
        self.order_id = order_id


class InvalidTransitionError(Exception):
    def __init__(self, from_status: str, to_status: str) -> None:
        super().__init__(f"invalid status transition: {from_status} -> {to_status}")
```

## Entidade de domínio

```python
# domain/order/order.py
from __future__ import annotations
from typing import Literal

OrderStatus = Literal["pending", "confirmed", "cancelled"]


class Order:
    def __init__(self, order_id: str, total_cents: int) -> None:
        if not order_id:
            raise ValueError("order id is required")
        if total_cents <= 0:
            raise ValueError("total must be positive")
        self._id = order_id
        self._status: OrderStatus = "pending"
        self._total_cents = total_cents

    def confirm(self) -> None:
        from domain.order.errors import InvalidTransitionError
        if self._status != "pending":
            raise InvalidTransitionError(self._status, "confirmed")
        self._status = "confirmed"

    @property
    def id(self) -> str:
        return self._id

    @property
    def status(self) -> OrderStatus:
        return self._status

    @property
    def total_cents(self) -> int:
        return self._total_cents
```

## Interface de repository (Protocol no consumidor)

```python
# application/order/service.py
from __future__ import annotations
from typing import Protocol
from domain.order.order import Order
from domain.order.errors import OrderNotFoundError


class OrderRepository(Protocol):
    async def save(self, order: Order) -> None: ...
    async def find_by_id(self, order_id: str) -> Order | None: ...


class OrderService:
    def __init__(self, repo: OrderRepository) -> None:
        self._repo = repo

    async def confirm(self, order_id: str) -> None:
        order = await self._repo.find_by_id(order_id)
        if order is None:
            raise OrderNotFoundError(order_id)
        order.confirm()
        await self._repo.save(order)
```

## Handler HTTP (FastAPI-style)

```python
# handler/order/confirm.py
from fastapi import APIRouter, HTTPException
from application.order.service import OrderService
from domain.order.errors import OrderNotFoundError, InvalidTransitionError

router = APIRouter()


def make_router(service: OrderService) -> APIRouter:
    @router.post("/orders/{order_id}/confirm", status_code=204)
    async def confirm_order(order_id: str) -> None:
        try:
            await service.confirm(order_id)
        except OrderNotFoundError as exc:
            raise HTTPException(status_code=404, detail=str(exc)) from exc
        except InvalidTransitionError as exc:
            raise HTTPException(status_code=409, detail=str(exc)) from exc

    return router
```

## Teste unitário do use case

```python
# tests/application/test_order_service.py
import pytest
from unittest.mock import AsyncMock
from domain.order.order import Order
from domain.order.errors import OrderNotFoundError, InvalidTransitionError
from application.order.service import OrderService


@pytest.fixture()
def repo() -> AsyncMock:
    mock = AsyncMock()
    mock.save.return_value = None
    return mock


@pytest.fixture()
def service(repo: AsyncMock) -> OrderService:
    return OrderService(repo)


async def test_confirm_pending_order(service: OrderService, repo: AsyncMock) -> None:
    order = Order("order-1", 5000)
    repo.find_by_id.return_value = order

    await service.confirm("order-1")

    assert order.status == "confirmed"
    repo.save.assert_awaited_once_with(order)


async def test_confirm_raises_when_order_not_found(
    service: OrderService, repo: AsyncMock
) -> None:
    repo.find_by_id.return_value = None
    with pytest.raises(OrderNotFoundError):
        await service.confirm("missing")
```
