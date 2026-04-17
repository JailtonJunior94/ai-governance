# Design Patterns

## Objetivo
Aplicar patterns apenas quando reduzirem complexidade real — nunca como cerimônia.

## Princípios
- Preferir composição a hierarquias profundas.
- Preferir função, método ou tipo concreto antes de factory, strategy ou decorator.
- Usar pattern quando houver variação recorrente de comportamento ou dependência externa que exija adaptação clara.
- Escolher no máximo um pattern principal por problema.
- Go não tem herança — patterns que dependem dela devem ser adaptados com interfaces e composição.

## Sinais de uso indevido
- Mais tipos e indireção sem melhora de teste ou legibilidade.
- Pattern introduzido para "seguir boas práticas" sem pressão concreta do contexto.
- Pattern que exige explicação para o leitor entender um fluxo simples.

---

## Creational Patterns

### Factory Function
**Quando usar:** Construção envolve validação de invariantes, valores default ou dependências que não devem ser expostas.
**Em Go:** Funções `New*` que retornam `(T, error)` ou `*T`. Não usar factory abstrata a menos que exista família de objetos variante.

```go
func NewOrder(id string, total Money) (*Order, error) {
    if id == "" {
        return nil, errors.New("order id is required")
    }
    return &Order{id: id, status: StatusPending, total: total}, nil
}
```

### Builder
**Quando usar:** Objeto com muitos campos opcionais onde construtores com N parâmetros ficam ilegíveis.
**Em Go:** Functional options é o idioma preferido sobre builder fluente.

```go
type ServerOption func(*Server)

func WithTimeout(d time.Duration) ServerOption {
    return func(s *Server) { s.timeout = d }
}

func WithLogger(l *slog.Logger) ServerOption {
    return func(s *Server) { s.logger = l }
}

func NewServer(addr string, opts ...ServerOption) *Server {
    s := &Server{addr: addr, timeout: 30 * time.Second, logger: slog.Default()}
    for _, opt := range opts {
        opt(s)
    }
    return s
}
```

### Singleton
**Quando usar:** Quase nunca. Usar apenas para recursos genuinamente únicos (pool de conexão inicializado uma vez).
**Em Go:** `sync.Once` quando inevitável. Preferir injeção explícita via construtor.

```go
var (
    dbOnce sync.Once
    dbPool *sql.DB
)

func DB(dsn string) *sql.DB {
    dbOnce.Do(func() {
        dbPool, _ = sql.Open("postgres", dsn)
    })
    return dbPool
}
// Preferir: criar pool no main e injetar via construtor.
```

---

## Structural Patterns

### Adapter
**Quando usar:** Integrar interface externa incompatível com contrato interno.
**Em Go:** Struct que implementa interface do consumidor e delega para o tipo externo.

```go
// Adaptando client HTTP externo para interface interna
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

### Decorator (Middleware)
**Quando usar:** Adicionar comportamento transversal (logging, métricas, retry) sem modificar a implementação original.
**Em Go:** Função ou struct que wrapa uma interface e adiciona comportamento.

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

### Facade
**Quando usar:** Simplificar interação com subsistema complexo expondo operação de alto nível.
**Em Go:** Service ou use case que orquestra múltiplas dependências.

```go
// application/checkout/service.go — facade para fluxo de checkout
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

---

## Behavioral Patterns

### Strategy
**Quando usar:** Algoritmo varia em runtime e o chamador precisa trocar a implementação sem alterar o fluxo.
**Em Go:** Interface pequena + implementações concretas injetadas via construtor.

```go
type pricer interface {
    Calculate(order *Order) Money
}

type standardPricer struct{}
func (p *standardPricer) Calculate(order *Order) Money { return order.subtotal }

type discountPricer struct{ pct float64 }
func (p *discountPricer) Calculate(order *Order) Money {
    return order.subtotal.Multiply(1 - p.pct)
}

type Service struct {
    pricer pricer
}
```

### Chain of Responsibility (Middleware Chain)
**Quando usar:** Request precisa passar por série de handlers onde cada um decide processar ou delegar.
**Em Go:** Padrão de middleware HTTP é o exemplo canônico.

```go
func recoveryMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        defer func() {
            if err := recover(); err != nil {
                slog.Error("panic recovered", slog.Any("error", err))
                http.Error(w, "internal error", http.StatusInternalServerError)
            }
        }()
        next.ServeHTTP(w, r)
    })
}

// Composição: recoveryMiddleware(authMiddleware(handler))
```

### Observer (Event/Callback)
**Quando usar:** Componente precisa reagir a evento sem acoplamento direto com o emissor.
**Em Go:** Channel, callback function ou event dispatcher simples. Evitar frameworks de pub/sub in-process para casos simples.

```go
type EventHandler func(ctx context.Context, event any) error

type Dispatcher struct {
    handlers map[string][]EventHandler
}

func (d *Dispatcher) On(eventType string, h EventHandler) {
    d.handlers[eventType] = append(d.handlers[eventType], h)
}

func (d *Dispatcher) Dispatch(ctx context.Context, eventType string, event any) error {
    for _, h := range d.handlers[eventType] {
        if err := h(ctx, event); err != nil {
            return err
        }
    }
    return nil
}
```

### State
**Quando usar:** Objeto muda de comportamento conforme seu estado e as transições precisam ser explícitas.
**Em Go:** Enum + método que valida transição. Para máquinas de estado complexas, interface por estado.

```go
// Abordagem simples com enum (preferida quando o número de estados é pequeno)
type Status string

const (
    StatusPending   Status = "pending"
    StatusConfirmed Status = "confirmed"
    StatusShipped   Status = "shipped"
)

var validTransitions = map[Status][]Status{
    StatusPending:   {StatusConfirmed},
    StatusConfirmed: {StatusShipped},
}

func (o *Order) TransitionTo(next Status) error {
    for _, valid := range validTransitions[o.status] {
        if valid == next {
            o.status = next
            return nil
        }
    }
    return fmt.Errorf("%w: %s -> %s", ErrInvalidTransition, o.status, next)
}
```

### Template Method
**Quando usar:** Algoritmo tem estrutura fixa mas passos variáveis.
**Em Go:** Sem herança, usar interface com steps + função orquestradora.

```go
type DataImporter interface {
    Fetch(ctx context.Context) ([]byte, error)
    Parse(data []byte) ([]Record, error)
    Validate(records []Record) error
    Save(ctx context.Context, records []Record) error
}

func RunImport(ctx context.Context, imp DataImporter) error {
    data, err := imp.Fetch(ctx)
    if err != nil {
        return fmt.Errorf("fetching: %w", err)
    }
    records, err := imp.Parse(data)
    if err != nil {
        return fmt.Errorf("parsing: %w", err)
    }
    if err := imp.Validate(records); err != nil {
        return fmt.Errorf("validating: %w", err)
    }
    return imp.Save(ctx, records)
}
```

---

## Patterns Raramente Úteis em Go

| Pattern | Por que evitar | Alternativa Go |
|---------|---------------|----------------|
| Abstract Factory | Go não tem herança; over-abstraction | Factory function + interface no consumidor |
| Prototype | Clone é raro em Go; valor semântico resolve | Copiar struct por atribuição |
| Flyweight | Premature optimization na maioria dos casos | `sync.Pool` quando medição justificar |
| Mediator | Tendência a virar god object | Injetar dependências explícitas |
| Memento | Raro em backends | Persistir estado em banco |
| Visitor | Complexidade alta para ganho marginal | Type switch quando os tipos forem fechados |
| Command | Útil em UIs, raro em backends Go | Função ou closure |
| Iterator | Go tem `range` nativo | `range` + funções de transformação |

## Proibido
- Pattern introduzido sem problema recorrente que o justifique.
- Mais de um pattern para o mesmo problema.
- Pattern que exige `reflect` para funcionar quando tipagem estática resolveria.
- Factory abstrata para um único tipo concreto.
