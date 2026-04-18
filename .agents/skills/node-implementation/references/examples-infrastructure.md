# Exemplos: Infraestrutura

## Graceful Shutdown (Express)
```typescript
// src/main.ts
import http from 'node:http'
import { app } from './app.js'
import { db } from './infra/db.js'

const server = http.createServer(app)

server.listen(3000, () => {
  console.log('server started on :3000')
})

const shutdown = async (signal: string) => {
  console.log(`${signal} received, shutting down`)
  server.close(async () => {
    await db.end()
    console.log('shutdown complete')
    process.exit(0)
  })
  setTimeout(() => {
    console.error('forced shutdown after timeout')
    process.exit(1)
  }, 15_000).unref()
}

process.on('SIGTERM', () => shutdown('SIGTERM'))
process.on('SIGINT', () => shutdown('SIGINT'))
```

## Pagination — Cursor-based
```typescript
// infra/order/repository.ts
interface PaginatedResult<T> {
  items: T[]
  nextCursor?: string
  hasMore: boolean
}

async function listOrders(cursor: string | undefined, limit = 20): Promise<PaginatedResult<Order>> {
  const query = cursor
    ? `SELECT id, status, total FROM orders WHERE id > $1 ORDER BY id ASC LIMIT $2`
    : `SELECT id, status, total FROM orders ORDER BY id ASC LIMIT $1`

  const params = cursor ? [cursor, limit + 1] : [limit + 1]
  const rows = await db.query(query, params)

  const hasMore = rows.length > limit
  const items = hasMore ? rows.slice(0, limit) : rows
  const nextCursor = hasMore ? items[items.length - 1].id : undefined

  return { items, nextCursor, hasMore }
}
```

## Versionamento de API por path (Express)
```typescript
// src/routes.ts
import { Router } from 'express'
import { orderV1 } from './http/v1/order.js'
import { orderV2 } from './http/v2/order.js'

const router = Router()

router.use('/v1/orders', orderV1)
router.use('/v2/orders', orderV2)

export { router }
```
