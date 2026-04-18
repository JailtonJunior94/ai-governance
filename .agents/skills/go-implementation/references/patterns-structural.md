# Structural Patterns

## Adapter
**Quando usar:** Integrar interface externa incompativel com contrato interno.
**Em Go:** Struct que implementa interface do consumidor e delega para o tipo externo.

```go
type paymentGateway interface {
    Charge(ctx context.Context, amount Money) error
}

type stripeAdapter struct {
    client *stripe.Client
}

func (a *stripeAdapter) Charge(ctx context.Context, amount Money) error {
    _, err := a.client.Charges.New(&stripe.ChargeParams{
        Amount:   stripe.Int64(amount.Cents()),
        Currency: stripe.String("brl"),
    })
    return err
}
```

## Decorator (Middleware)
**Quando usar:** Adicionar comportamento transversal (logging, metricas, retry) sem modificar a implementacao original.
**Em Go:** Funcao ou struct que wrapa uma interface e adiciona comportamento.

```go
type loggingRepository struct {
    next orderRepository
    log  *slog.Logger
}

func (r *loggingRepository) FindByID(ctx context.Context, id string) (*Order, error) {
    r.log.InfoContext(ctx, "finding order", slog.String("id", id))
    order, err := r.next.FindByID(ctx, id)
    if err != nil {
        r.log.ErrorContext(ctx, "find order failed", slog.String("id", id), slog.String("error", err.Error()))
    }
    return order, err
}
```

## Facade
**Quando usar:** Simplificar interacao com subsistema complexo expondo operacao de alto nivel.
**Em Go:** Service ou use case que orquestra multiplas dependencias.

```go
type Service struct {
    orders   orderRepository
    payments paymentGateway
    notify   notificationSender
}

func (s *Service) Checkout(ctx context.Context, orderID string) error {
    order, err := s.orders.FindByID(ctx, orderID)
    if err != nil {
        return err
    }
    if err := s.payments.Charge(ctx, order.Total()); err != nil {
        return fmt.Errorf("charging order %s: %w", orderID, err)
    }
    if err := order.Confirm(); err != nil {
        return err
    }
    if err := s.orders.Save(ctx, order); err != nil {
        return fmt.Errorf("saving order %s: %w", orderID, err)
    }
    _ = s.notify.Send(ctx, order.CustomerID(), "Order confirmed")
    return nil
}
```
