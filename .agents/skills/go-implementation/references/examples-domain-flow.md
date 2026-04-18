# Exemplos: Fluxo End-to-End

## Sentinel errors e entidade de dominio
```go
// domain/order/errors.go
var (
    ErrOrderNotFound     = errors.New("order not found")
    ErrInvalidTransition = errors.New("invalid status transition")
)

// domain/order/order.go
type Order struct {
    id     string
    status Status
    total  Money
}

func New(id string, total Money) (*Order, error) {
    if id == "" {
        return nil, errors.New("order id is required")
    }
    return &Order{id: id, status: StatusPending, total: total}, nil
}

func (o *Order) Confirm() error {
    if o.status != StatusPending {
        return fmt.Errorf("%w: cannot confirm order in status %s", ErrInvalidTransition, o.status)
    }
    o.status = StatusConfirmed
    return nil
}
```

## Service com interface no consumidor + handler fino
```go
// application/order/service.go
type orderRepository interface {
    Save(ctx context.Context, order *domain.Order) error
    FindByID(ctx context.Context, id string) (*domain.Order, error)
}

type Service struct {
    repo orderRepository
    log  *slog.Logger
}

func NewService(repo orderRepository, log *slog.Logger) *Service {
    return &Service{repo: repo, log: log}
}

func (s *Service) Confirm(ctx context.Context, id string) error {
    order, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return fmt.Errorf("finding order %s: %w", id, err)
    }
    if err := order.Confirm(); err != nil {
        return err
    }
    if err := s.repo.Save(ctx, order); err != nil {
        return fmt.Errorf("saving order %s: %w", id, err)
    }
    s.log.InfoContext(ctx, "order confirmed", slog.String("order_id", id))
    return nil
}

// handler/order/confirm.go
func (h *Handler) Confirm(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id")
    if id == "" {
        http.Error(w, `{"error":"order id is required"}`, http.StatusBadRequest)
        return
    }
    if err := h.service.Confirm(r.Context(), id); err != nil {
        h.handleError(w, err)
        return
    }
    w.WriteHeader(http.StatusNoContent)
}
```

## Mockery config + teste com suite
```yaml
# .mockery.yml
with-expecter: true
dir: "{{.InterfaceDir}}/mocks"
outpkg: "mocks"
filename: "{{.InterfaceName}}.go"
mockname: "{{.InterfaceName}}Mock"
packages:
  github.com/example/app/internal/application/order:
    interfaces:
      orderRepository:
```

```go
// application/order/service_test.go
type ServiceSuite struct {
    suite.Suite
    repo *mocks.OrderRepositoryMock
    svc  *Service
}

func TestServiceSuite(t *testing.T)      { suite.Run(t, new(ServiceSuite)) }
func (s *ServiceSuite) SetupTest() {
    s.repo = mocks.NewOrderRepositoryMock(s.T())
    s.svc = NewService(s.repo, slog.Default())
}

func (s *ServiceSuite) TestConfirm_PendingOrder() {
    order, _ := domain.New("order-1", domain.NewMoney(100))
    s.repo.EXPECT().FindByID(mock.Anything, "order-1").Return(order, nil)
    s.repo.EXPECT().Save(mock.Anything, order).Return(nil)
    s.NoError(s.svc.Confirm(context.Background(), "order-1"))
}

func (s *ServiceSuite) TestConfirm_OrderNotFound() {
    s.repo.EXPECT().FindByID(mock.Anything, "missing").Return(nil, domain.ErrOrderNotFound)
    err := s.svc.Confirm(context.Background(), "missing")
    s.ErrorIs(err, domain.ErrOrderNotFound)
    s.repo.AssertNotCalled(s.T(), "Save")
}

func (s *ServiceSuite) TestConfirm_SaveError() {
    order, _ := domain.New("order-1", domain.NewMoney(100))
    s.repo.EXPECT().FindByID(mock.Anything, "order-1").Return(order, nil)
    s.repo.EXPECT().Save(mock.Anything, order).Return(errors.New("db error"))
    err := s.svc.Confirm(context.Background(), "order-1")
    s.Error(err)
    s.Contains(err.Error(), "saving order")
}
```
