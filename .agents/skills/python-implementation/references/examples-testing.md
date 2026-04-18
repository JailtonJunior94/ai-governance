# Exemplos: Testes e Validacao

## Fixture com factory
```python
# tests/conftest.py
import pytest
from unittest.mock import AsyncMock


@pytest.fixture()
def repo() -> AsyncMock:
    mock = AsyncMock()
    mock.save.return_value = None
    return mock


@pytest.fixture()
def service(repo: AsyncMock) -> OrderService:
    return OrderService(repo)
```

## Parametrize
```python
import pytest
from domain.order.normalize import normalize


@pytest.mark.parametrize(
    "input_val, expected",
    [
        (" a ", "a"),
        ("", ""),
        ("ABC", "abc"),
    ],
)
def test_normalize(input_val: str, expected: str) -> None:
    assert normalize(input_val) == expected
```

## DTO validation test (pydantic)
```python
import pytest
from pydantic import ValidationError
from api.schemas import CreateOrderRequest


def test_valid_input() -> None:
    req = CreateOrderRequest(customer_id="c-1", total=5000)
    assert req.total == 5000


def test_rejects_negative_total() -> None:
    with pytest.raises(ValidationError):
        CreateOrderRequest(customer_id="c-1", total=-1)


def test_rejects_missing_customer_id() -> None:
    with pytest.raises(ValidationError):
        CreateOrderRequest(total=100)  # type: ignore[call-arg]
```

## Async error assertion
```python
async def test_confirm_raises_when_not_found(
    service: OrderService, repo: AsyncMock
) -> None:
    repo.find_by_id.return_value = None
    with pytest.raises(OrderNotFoundError):
        await service.confirm("missing")
```
