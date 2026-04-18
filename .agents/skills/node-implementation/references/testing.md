# Testes Node/TypeScript

## Objetivo
Garantir correcao, prevenir regressao e documentar comportamento com custo proporcional ao risco.

## Unit Tests (obrigatorio)
- Usar o framework de teste ja adotado pelo projeto (Jest, Vitest, Mocha, Node test runner).
- Nomear testes pelo cenario, nao pelo metodo: `confirm_order_already_shipped`.
- Manter testes deterministicos — sem timers reais, sem dependencia de ordem, sem estado global.
- Usar mocks apenas para fronteiras externas (IO, rede, filesystem, banco).
- Colocar arquivo de teste ao lado do arquivo testado ou em pasta `__tests__/` conforme convencao do projeto.
- Usar `beforeEach` para reset de mocks — nunca compartilhar instancia mutavel entre casos.

### Mock de fronteira externa (Vitest)

```typescript
// application/order/__tests__/service.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { OrderService } from '../service.js'
import { Order } from '../../../domain/order/order.js'

const makeRepo = () => ({
  save: vi.fn<[Order], Promise<void>>().mockResolvedValue(undefined),
  findById: vi.fn<[string], Promise<Order | null>>(),
})

describe('OrderService.confirm', () => {
  let repo: ReturnType<typeof makeRepo>
  let service: OrderService

  beforeEach(() => {
    repo = makeRepo()
    service = new OrderService(repo)
  })

  it('confirms a pending order', async () => {
    const order = Order.create('order-1', 5000)
    repo.findById.mockResolvedValue(order)
    await service.confirm('order-1')
    expect(order.status).toBe('confirmed')
    expect(repo.save).toHaveBeenCalledOnce()
  })

  it('throws when order not found', async () => {
    repo.findById.mockResolvedValue(null)
    await expect(service.confirm('x')).rejects.toThrow('not found')
  })
})
```

## Integration Tests (quando adotados)
- Separar de unit tests via script dedicado: `npm run test:integration` ou `vitest --project integration`.
- Usar [testcontainers-node](https://node.testcontainers.org/) para provisionar dependencias reais em containers efemeros.
- Nao depender de servicos externos reais (banco de dev, API de staging).
- Cada suite deve provisionar e destruir seu container — nao depender de infra pre-existente.

### Testcontainers (padrao de uso)

```typescript
// infra/order/__tests__/repository.integration.test.ts
import { describe, it, beforeAll, afterAll, expect } from 'vitest'
import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql'

describe('OrderRepository (integration)', () => {
  let container: StartedPostgreSqlContainer
  let connectionUri: string

  beforeAll(async () => {
    container = await new PostgreSqlContainer('postgres:16-alpine').start()
    connectionUri = container.getConnectionUri()
    // rodar migrations aqui usando connectionUri
  })

  afterAll(async () => {
    await container.stop()
  })

  it('saves and finds an order by id', async () => {
    // instanciar repository com connectionUri e testar comportamento real
  })
})
```

## Proibido
- `setTimeout` para sincronizacao em teste.
- Teste que passa sozinho mas falha em suite completa.
- Mock que nao reflete o contrato real da dependencia.
- Teste de integracao sem build tag ou script separado rodando junto com unit tests.
