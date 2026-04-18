# Design Patterns

## Principios Gerais
- Preferir composicao a hierarquias profundas.
- Preferir funcao, metodo ou tipo concreto antes de factory, strategy ou decorator.
- Usar pattern quando houver variacao recorrente de comportamento ou dependencia externa que exija adaptacao clara.
- Escolher no maximo um pattern principal por problema.
- Go nao tem heranca — patterns que dependem dela devem ser adaptados com interfaces e composicao.

## Sinais de uso indevido
- Mais tipos e indirecao sem melhora de teste ou legibilidade.
- Pattern introduzido para "seguir boas praticas" sem pressao concreta do contexto.
- Pattern que exige explicacao para o leitor entender um fluxo simples.

---

## Creational

### Factory Function
**Quando usar:** Construcao envolve validacao de invariantes, valores default ou dependencias que nao devem ser expostas.
**Em Go:** Funcoes `New*` que retornam `(T, error)` ou `*T`. Nao usar factory abstrata a menos que exista familia de objetos variante.

```go
func NewOrder(id string, total Money) (*Order, error) {
    if id == "" {
        return nil, errors.New("order id is required")
    }
    return &Order{id: id, status: StatusPending, total: total}, nil
}
```

### Builder (Functional Options)
**Quando usar:** Objeto com muitos campos opcionais onde construtores com N parametros ficam ilegiveis.
**Em Go:** Functional options e o idioma preferido sobre builder fluente.

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
**Quando usar:** Quase nunca. Usar apenas para recursos genuinamente unicos (pool de conexao inicializado uma vez).
**Em Go:** `sync.Once` quando inevitavel. Preferir injecao explicita via construtor.

---

## Structural

### Adapter
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

### Decorator (Middleware)
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

### Facade
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

---

## Behavioral

### Strategy
**Quando usar:** Algoritmo varia em runtime e o chamador precisa trocar a implementacao sem alterar o fluxo.
**Em Go:** Interface pequena + implementacoes concretas injetadas via construtor.

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
```

### Chain of Responsibility (Middleware Chain)
**Quando usar:** Request precisa passar por serie de handlers onde cada um decide processar ou delegar.
**Em Go:** Padrao de middleware HTTP e o exemplo canonico.

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
**Quando usar:** Objeto muda de comportamento conforme seu estado e as transicoes precisam ser explicitas.
**Em Go:** Enum + metodo que valida transicao. Para maquinas de estado complexas, interface por estado.

```go
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
**Quando usar:** Algoritmo tem estrutura fixa mas passos variaveis.
**Em Go:** Sem heranca, usar interface com steps + funcao orquestradora.

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

## Patterns Raramente Uteis em Go

| Pattern | Por que evitar | Alternativa Go |
|---------|---------------|----------------|
| Abstract Factory | Go nao tem heranca; over-abstraction | Factory function + interface no consumidor |
| Prototype | Clone e raro em Go; valor semantico resolve | Copiar struct por atribuicao |
| Flyweight | Premature optimization na maioria dos casos | `sync.Pool` quando medicao justificar |
| Mediator | Tendencia a virar god object | Injetar dependencias explicitas |
| Memento | Raro em backends | Persistir estado em banco |
| Visitor | Complexidade alta para ganho marginal | Type switch quando os tipos forem fechados |
| Command | Util em UIs, raro em backends Go | Funcao ou closure |
| Iterator | Go tem `range` nativo | `range` + funcoes de transformacao |

## Proibido
- Pattern introduzido sem problema recorrente que o justifique.
- Mais de um pattern para o mesmo problema.
- Pattern que exige `reflect` para funcionar quando tipagem estatica resolveria.
- Factory abstrata para um unico tipo concreto.
