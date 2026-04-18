# Design Patterns — Structural e Creational

## Principios Gerais
- Composicao sobre hierarquias. Funcao/tipo concreto antes de pattern.
- Pattern apenas com variacao recorrente ou dependencia externa que exija adaptacao.
- No maximo um pattern principal por problema.
- Go nao tem heranca — adaptar com interfaces e composicao.

## Sinais de uso indevido
- Mais tipos sem melhora de teste ou legibilidade.
- Pattern sem pressao concreta do contexto.

---

## Creational

### Factory Function
Funcoes `New*` que retornam `(T, error)` ou `*T` quando construcao exige validacao ou dependencias.

```go
func NewOrder(id string, total Money) (*Order, error) {
    if id == "" {
        return nil, errors.New("order id is required")
    }
    return &Order{id: id, status: StatusPending, total: total}, nil
}
```

### Builder (Functional Options)
Idioma preferido sobre builder fluente para objetos com muitos campos opcionais.

```go
type ServerOption func(*Server)

func WithTimeout(d time.Duration) ServerOption { return func(s *Server) { s.timeout = d } }
func WithLogger(l *slog.Logger) ServerOption   { return func(s *Server) { s.logger = l } }

func NewServer(addr string, opts ...ServerOption) *Server {
    s := &Server{addr: addr, timeout: 30 * time.Second, logger: slog.Default()}
    for _, opt := range opts { opt(s) }
    return s
}
```

### Singleton
Quase nunca. `sync.Once` quando inevitavel. Preferir injecao via construtor.

---

## Structural

### Adapter
Struct que implementa interface do consumidor e delega para tipo externo incompativel.

```go
type stripeAdapter struct{ client *stripe.Client }

func (a *stripeAdapter) Charge(ctx context.Context, amount Money) error {
    _, err := a.client.Charges.New(&stripe.ChargeParams{
        Amount: stripe.Int64(amount.Cents()), Currency: stripe.String("brl"),
    })
    return err
}
```

### Decorator (Middleware)
Struct/funcao que wrapa interface e adiciona comportamento transversal (logging, metricas, retry).

```go
type loggingRepository struct {
    next orderRepository
    log  *slog.Logger
}

func (r *loggingRepository) FindByID(ctx context.Context, id string) (*Order, error) {
    r.log.InfoContext(ctx, "finding order", slog.String("id", id))
    return r.next.FindByID(ctx, id)
}
```

### Facade
Service/use case que orquestra multiplas dependencias em operacao de alto nivel.

```go
func (s *Service) Checkout(ctx context.Context, orderID string) error {
    order, err := s.orders.FindByID(ctx, orderID)
    if err != nil { return err }
    if err := s.payments.Charge(ctx, order.Total()); err != nil {
        return fmt.Errorf("charging order %s: %w", orderID, err)
    }
    if err := order.Confirm(); err != nil { return err }
    if err := s.orders.Save(ctx, order); err != nil {
        return fmt.Errorf("saving order %s: %w", orderID, err)
    }
    _ = s.notify.Send(ctx, order.CustomerID(), "Order confirmed")
    return nil
}
```

---

## Patterns Raramente Uteis

| Pattern | Alternativa Go |
|---------|----------------|
| Abstract Factory | Factory function + interface no consumidor |
| Prototype | Copiar struct por atribuicao |
| Flyweight | `sync.Pool` quando medicao justificar |

## Proibido
- Pattern sem problema recorrente que o justifique.
- Mais de um pattern para o mesmo problema.
- Pattern que exige `reflect` quando tipagem estatica resolveria.
