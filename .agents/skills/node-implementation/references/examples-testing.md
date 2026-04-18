# Exemplos: Testes e Validacao

## Factory de mock para fronteira
```typescript
const makeRepo = () => ({
  save: vi.fn<[Order], Promise<void>>().mockResolvedValue(undefined),
  findById: vi.fn<[string], Promise<Order | null>>(),
})
```

## Parametrized test (Vitest)
```typescript
import { describe, it, expect } from 'vitest'
import { normalize } from '../normalize.js'

describe.each([
  { name: 'trim', input: ' a ', expected: 'a' },
  { name: 'empty', input: '', expected: '' },
  { name: 'lower', input: 'ABC', expected: 'abc' },
])('normalize($name)', ({ input, expected }) => {
  it(`returns "${expected}"`, () => {
    expect(normalize(input)).toBe(expected)
  })
})
```

## DTO validation test (zod)
```typescript
import { describe, it, expect } from 'vitest'
import { CreateOrderSchema } from '../schemas.js'

describe('CreateOrderSchema', () => {
  it('accepts valid input', () => {
    const result = CreateOrderSchema.safeParse({ customerId: 'c-1', total: 5000 })
    expect(result.success).toBe(true)
  })

  it('rejects negative total', () => {
    const result = CreateOrderSchema.safeParse({ customerId: 'c-1', total: -1 })
    expect(result.success).toBe(false)
  })

  it('rejects missing customerId', () => {
    const result = CreateOrderSchema.safeParse({ total: 100 })
    expect(result.success).toBe(false)
  })
})
```

## Async error assertion
```typescript
it('throws when order not found', async () => {
  repo.findById.mockResolvedValue(null)
  await expect(service.confirm('x')).rejects.toThrow('not found')
})
```
