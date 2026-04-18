# Interfaces

## Quando usar
- Quando existir mais de uma implementação real ou um ponto claro de substituição.
- Quando um consumidor depender apenas de um comportamento pequeno e estável.
- Quando a interface reduzir acoplamento em uma fronteira real (repository, client externo, clock, ID generator).

## Quando evitar
- Para "facilitar testes" sem necessidade real de substituição.
- Antes de existir consumidor ou segunda implementação.
- Quando um tipo concreto simples resolve o problema.
- Quando a interface espelha 1:1 o tipo concreto sem abstrair nada.

## Diretrizes
- Definir a interface no lado consumidor (accept interfaces, return structs).
- Manter interfaces pequenas e focadas — 1 a 3 métodos é o ideal.
- Nomear pelo comportamento, não pela implementação: `Reader`, não `FileReader`.
- Compor interfaces pequenas em vez de criar uma grande: `ReadWriter` = `Reader` + `Writer`.
- Interface não exportada (minúscula) quando o consumidor for interno ao pacote.
- Exportar interface apenas quando consumidores externos precisarem implementá-la.

## Padrões de aplicação

### Fronteira de IO (repository, client)
```go
// application/order/service.go — interface no consumidor
type orderRepository interface {
    Save(ctx context.Context, order *domain.Order) error
    FindByID(ctx context.Context, id string) (*domain.Order, error)
}
```

### Abstração de infraestrutura (clock, ID)
```go
// application/order/service.go
type clock interface {
    Now() time.Time
}

type idGenerator interface {
    New() string
}
```

### Composição de interfaces
```go
type Reader interface {
    Read(ctx context.Context, id string) (*Entity, error)
}

type Writer interface {
    Save(ctx context.Context, entity *Entity) error
}

type ReadWriter interface {
    Reader
    Writer
}
```

## Riscos Comuns
- Interface com 5+ métodos que nenhum consumidor usa inteiramente.
- Interface definida no pacote do implementador em vez do consumidor.
- Interface prematura que precisa mudar a cada nova funcionalidade.

## Proibido
- Interface sem consumidor real.
- Interface que replica a struct pública método a método sem abstrair.
- `interface{}` / `any` como substituto de modelagem de domínio.
