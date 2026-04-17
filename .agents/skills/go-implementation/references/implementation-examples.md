# Exemplos de Implementação

## Construtor com invariantes
```go
type Config struct {
    timeout time.Duration
}

func NewConfig(timeout time.Duration) (Config, error) {
    if timeout <= 0 {
        return Config{}, fmt.Errorf("timeout must be positive")
    }
    return Config{timeout: timeout}, nil
}
```

## Interface no consumidor
```go
type clock interface {
    Now() time.Time
}
```

## Fuzz test para parser/validador
```go
// domain/order/money_test.go
func FuzzParseMoney(f *testing.F) {
    f.Add("100.00")
    f.Add("0")
    f.Add("-1")
    f.Add("")
    f.Add("99999999.99")
    f.Add("not-a-number")

    f.Fuzz(func(t *testing.T, input string) {
        result, err := ParseMoney(input)
        if err != nil {
            return // input inválido é esperado — apenas não deve panic
        }
        // round-trip: valor parseado deve ser re-serializável
        assert.Equal(t, result.String(), ParseMoney(result.String()))
    })
}
```

## Table-driven test com testify
```go
func TestNormalize(t *testing.T) {
    tests := []struct {
        name string
        in   string
        want string
    }{
        {name: "trim", in: " a ", want: "a"},
        {name: "empty", in: "", want: ""},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Normalize(tt.in)
            assert.Equal(t, tt.want, got)
        })
    }
}
```

## Fluxo end-to-end: Handler → Use Case → Repository → Domínio

### Sentinel errors do domínio
```go
// domain/order/errors.go
var (
    ErrOrderNotFound     = errors.New("order not found")
    ErrInvalidTransition = errors.New("invalid status transition")
)
```

### Entidade de domínio
```go
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

### Interface de repository (definida no consumidor)
```go
// application/order/service.go
type orderRepository interface {
    Save(ctx context.Context, order *domain.Order) error
    FindByID(ctx context.Context, id string) (*domain.Order, error) // retorna domain.ErrOrderNotFound quando não encontrar
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
```

### Handler fino
```go
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

### Configuração do mockery (`.mockery.yml` na raiz do projeto)
```yaml
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

Gerar mocks com `mockery` a partir da raiz do projeto:
```bash
mockery
```

### Teste com suite e mockery
```go
// application/order/service_test.go
type ServiceSuite struct {
    suite.Suite
    repo *mocks.OrderRepositoryMock
    svc  *Service
}

func TestServiceSuite(t *testing.T) {
    suite.Run(t, new(ServiceSuite))
}

func (s *ServiceSuite) SetupTest() {
    s.repo = mocks.NewOrderRepositoryMock(s.T())
    s.svc = NewService(s.repo, slog.Default())
}

func (s *ServiceSuite) TestConfirm_PendingOrder() {
    order, _ := domain.New("order-1", domain.NewMoney(100))

    s.repo.EXPECT().FindByID(mock.Anything, "order-1").Return(order, nil)
    s.repo.EXPECT().Save(mock.Anything, order).Return(nil)

    err := s.svc.Confirm(context.Background(), "order-1")

    s.NoError(err)
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

## Graceful Shutdown
```go
// cmd/server/main.go
func main() {
    ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
    defer stop()

    db := mustOpenDB(cfg.DSN)
    defer db.Close()

    srv := &http.Server{
        Addr:    cfg.Addr,
        Handler: newRouter(db),
    }

    go func() {
        if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
            slog.Error("server error", slog.String("error", err.Error()))
        }
    }()

    slog.Info("server started", slog.String("addr", cfg.Addr))
    <-ctx.Done()

    slog.Info("shutting down")
    shutdownCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
    defer cancel()

    // Fechar na ordem inversa de inicialização
    if err := srv.Shutdown(shutdownCtx); err != nil {
        slog.Error("server shutdown error", slog.String("error", err.Error()))
    }
    if err := db.Close(); err != nil {
        slog.Error("db close error", slog.String("error", err.Error()))
    }
    slog.Info("shutdown complete")
}
```

## Pagination — Cursor-based
```go
// handler/order/list.go
type ListRequest struct {
    Cursor string // opaque cursor (base64 do último ID ou timestamp)
    Limit  int    // default 20, max 100
}

type ListResponse[T any] struct {
    Items      []T    `json:"items"`
    NextCursor string `json:"next_cursor,omitempty"`
    HasMore    bool   `json:"has_more"`
}

func parseListRequest(r *http.Request) ListRequest {
    cursor := r.URL.Query().Get("cursor")
    limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
    if limit <= 0 || limit > 100 {
        limit = 20
    }
    return ListRequest{Cursor: cursor, Limit: limit}
}
```

```go
// infra/repository/order_postgres.go
func (r *OrderRepository) List(ctx context.Context, cursor string, limit int) ([]domain.Order, string, error) {
    // Buscar limit+1 para determinar hasMore
    query := `SELECT id, status, total FROM orders WHERE id > $1 ORDER BY id ASC LIMIT $2`
    rows, err := r.db.QueryContext(ctx, query, cursor, limit+1)
    if err != nil {
        return nil, "", fmt.Errorf("listing orders: %w", err)
    }
    defer rows.Close()

    orders := make([]domain.Order, 0, limit)
    var lastID string
    for rows.Next() {
        var o domain.Order
        if err := rows.Scan(&o.ID, &o.Status, &o.Total); err != nil {
            return nil, "", fmt.Errorf("scanning order: %w", err)
        }
        orders = append(orders, o)
        lastID = o.ID
    }

    hasMore := len(orders) > limit
    if hasMore {
        orders = orders[:limit]
        lastID = orders[limit-1].ID
    }

    var nextCursor string
    if hasMore {
        nextCursor = lastID
    }
    return orders, nextCursor, rows.Err()
}
```

## Versionamento de API por path
```go
// cmd/server/router.go
func newRouter(svc *order.Service) http.Handler {
    mux := http.NewServeMux()

    // v1
    v1 := order.NewHandlerV1(svc)
    mux.HandleFunc("GET /v1/orders/{id}", v1.Get)
    mux.HandleFunc("POST /v1/orders/{id}/confirm", v1.Confirm)

    // v2 — contrato alterado, v1 mantido para compatibilidade
    v2 := order.NewHandlerV2(svc)
    mux.HandleFunc("GET /v2/orders/{id}", v2.Get)
    mux.HandleFunc("POST /v2/orders/{id}/confirm", v2.Confirm)

    return mux
}
```
