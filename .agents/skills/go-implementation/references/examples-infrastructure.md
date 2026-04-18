# Exemplos: Infraestrutura

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
    Cursor string // opaque cursor (base64 do ultimo ID ou timestamp)
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

    v1 := order.NewHandlerV1(svc)
    mux.HandleFunc("GET /v1/orders/{id}", v1.Get)
    mux.HandleFunc("POST /v1/orders/{id}/confirm", v1.Confirm)

    v2 := order.NewHandlerV2(svc)
    mux.HandleFunc("GET /v2/orders/{id}", v2.Get)
    mux.HandleFunc("POST /v2/orders/{id}/confirm", v2.Confirm)

    return mux
}
```
