# Testes Python

## Objetivo
Garantir correcao, prevenir regressao e documentar comportamento com custo proporcional ao risco.

## Unit Tests (obrigatorio)
- Usar o framework ja adotado pelo projeto (pytest, unittest). Preferir pytest quando nao houver convencao existente.
- Nomear testes pelo cenario: `test_confirm_order_already_shipped`.
- Manter testes deterministicos — sem sleep, sem dependencia de ordem, sem estado global.
- Usar fixtures do pytest para setup/teardown compartilhado.
- Usar mocks apenas para fronteiras externas (IO, rede, filesystem, banco).
- Usar `unittest.mock.AsyncMock` para corrotinas e `MagicMock` para sincrono.

### Mock de fronteira externa (pytest + AsyncMock)

```python
# tests/application/test_order_service.py
import pytest
from unittest.mock import AsyncMock
from domain.order.order import Order
from domain.order.errors import OrderNotFoundError
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

## Integration Tests (quando adotados)
- Separar via marcador (`@pytest.mark.integration`) ou diretorio `tests/integration/`.
- Rodar com comando explicito: `pytest -m integration`.
- Usar [testcontainers-python](https://testcontainers-python.readthedocs.io/) para provisionar dependencias reais.
- Nao depender de servicos externos reais (banco de dev, API de staging).
- Cada suite deve provisionar e destruir seu container — nao depender de infra pre-existente.

### Testcontainers (padrao de uso)

```python
# tests/integration/test_order_repository.py
import pytest
from testcontainers.postgres import PostgresContainer


@pytest.fixture(scope="module")
def pg_url() -> str:  # type: ignore[return]
    with PostgresContainer("postgres:16-alpine") as pg:
        # rodar migrations aqui usando pg.get_connection_url()
        yield pg.get_connection_url()


@pytest.mark.integration
async def test_save_and_find_by_id(pg_url: str) -> None:
    # instanciar repository com pg_url e testar comportamento real
    pass
```

## Proibido
- `time.sleep` para sincronizacao em teste.
- Teste que passa sozinho mas falha em suite completa.
- Mock que nao reflete o contrato real da dependencia.
- Fixture com logica complexa que precisa de seus proprios testes.
- Teste de integracao sem marcador `integration` rodando junto com unit tests.
