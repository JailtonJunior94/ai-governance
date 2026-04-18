# Exemplos: Fluxo End-to-End Node/TypeScript

## Erros de domínio

```typescript
// domain/order/errors.ts
export class OrderNotFoundError extends Error {
  constructor(id: string) {
    super(`order not found: ${id}`)
    this.name = 'OrderNotFoundError'
  }
}

export class InvalidTransitionError extends Error {
  constructor(from: string, to: string) {
    super(`invalid status transition: ${from} -> ${to}`)
    this.name = 'InvalidTransitionError'
  }
}
```

## Entidade de domínio

```typescript
// domain/order/order.ts
export type OrderStatus = 'pending' | 'confirmed' | 'cancelled'

export class Order {
  private constructor(
    private readonly _id: string,
    private _status: OrderStatus,
    private readonly _totalCents: number,
  ) {}

  static create(id: string, totalCents: number): Order {
    if (!id) throw new Error('order id is required')
    if (totalCents <= 0) throw new Error('total must be positive')
    return new Order(id, 'pending', totalCents)
  }

  confirm(): void {
    if (this._status !== 'pending') {
      throw new InvalidTransitionError(this._status, 'confirmed')
    }
    this._status = 'confirmed'
  }

  get id(): string { return this._id }
  get status(): OrderStatus { return this._status }
  get totalCents(): number { return this._totalCents }
}
```

## Interface de repository (definida no consumidor)

```typescript
// application/order/service.ts
import type { Order } from '../../domain/order/order.js'
import { OrderNotFoundError } from '../../domain/order/errors.js'

interface OrderRepository {
  save(order: Order): Promise<void>
  findById(id: string): Promise<Order | null>
}

export class OrderService {
  constructor(private readonly repo: OrderRepository) {}

  async confirm(id: string): Promise<void> {
    const order = await this.repo.findById(id)
    if (!order) throw new OrderNotFoundError(id)
    order.confirm()
    await this.repo.save(order)
  }
}
```

## Handler HTTP (Express/Fastify-style)

```typescript
// handler/order/confirm.ts
import type { Request, Response } from 'express'
import type { OrderService } from '../../application/order/service.js'
import { OrderNotFoundError } from '../../domain/order/errors.js'
import { InvalidTransitionError } from '../../domain/order/errors.js'

export function makeConfirmHandler(service: OrderService) {
  return async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params
    try {
      await service.confirm(id)
      res.status(204).send()
    } catch (err) {
      if (err instanceof OrderNotFoundError) {
        res.status(404).json({ error: err.message })
        return
      }
      if (err instanceof InvalidTransitionError) {
        res.status(409).json({ error: err.message })
        return
      }
      res.status(500).json({ error: 'internal server error' })
    }
  }
}
```

## Teste unitário do use case

```typescript
// application/order/__tests__/service.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { OrderService } from '../service.js'
import { Order } from '../../../domain/order/order.js'
import { OrderNotFoundError } from '../../../domain/order/errors.js'

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
    expect(repo.save).toHaveBeenCalledWith(order)
  })

  it('throws OrderNotFoundError when order does not exist', async () => {
    repo.findById.mockResolvedValue(null)
    await expect(service.confirm('missing')).rejects.toThrow(OrderNotFoundError)
  })
})
```
