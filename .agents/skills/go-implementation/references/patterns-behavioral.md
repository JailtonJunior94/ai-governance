# Design Patterns — Behavioral

## Principios Gerais
- Composicao sobre hierarquias. Funcao/tipo concreto antes de pattern.
- Pattern apenas com variacao recorrente. No maximo um por problema.

---

### Strategy
Interface pequena + implementacoes concretas injetadas via construtor quando algoritmo varia em runtime.

```go
type pricer interface { Calculate(order *Order) Money }

type standardPricer struct{}
func (p *standardPricer) Calculate(order *Order) Money { return order.subtotal }

type discountPricer struct{ pct float64 }
func (p *discountPricer) Calculate(order *Order) Money {
    return order.subtotal.Multiply(1 - p.pct)
}
```

### Chain of Responsibility (Middleware)
Serie de handlers onde cada um processa ou delega. Padrao canonico em middleware HTTP.

```go
func recoveryMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        defer func() {
            if err := recover(); err != nil {
                http.Error(w, "internal error", http.StatusInternalServerError)
            }
        }()
        next.ServeHTTP(w, r)
    })
}
```

### Observer (Event/Callback)
Channel, callback ou dispatcher simples para reagir a eventos sem acoplamento direto.

```go
type EventHandler func(ctx context.Context, event any) error

type Dispatcher struct{ handlers map[string][]EventHandler }

func (d *Dispatcher) On(t string, h EventHandler) { d.handlers[t] = append(d.handlers[t], h) }

func (d *Dispatcher) Dispatch(ctx context.Context, t string, e any) error {
    for _, h := range d.handlers[t] {
        if err := h(ctx, e); err != nil { return err }
    }
    return nil
}
```

### State
Enum + metodo que valida transicao. Interface por estado apenas para maquinas complexas.

```go
var validTransitions = map[Status][]Status{
    StatusPending: {StatusConfirmed}, StatusConfirmed: {StatusShipped},
}

func (o *Order) TransitionTo(next Status) error {
    for _, v := range validTransitions[o.status] {
        if v == next { o.status = next; return nil }
    }
    return fmt.Errorf("%w: %s -> %s", ErrInvalidTransition, o.status, next)
}
```

### Template Method
Interface com steps + funcao orquestradora (sem heranca).

```go
type DataImporter interface {
    Fetch(ctx context.Context) ([]byte, error)
    Parse(data []byte) ([]Record, error)
    Validate(records []Record) error
    Save(ctx context.Context, records []Record) error
}

func RunImport(ctx context.Context, imp DataImporter) error {
    data, err := imp.Fetch(ctx)
    if err != nil { return fmt.Errorf("fetching: %w", err) }
    records, err := imp.Parse(data)
    if err != nil { return fmt.Errorf("parsing: %w", err) }
    if err := imp.Validate(records); err != nil { return fmt.Errorf("validating: %w", err) }
    return imp.Save(ctx, records)
}
```

---

## Patterns Raramente Uteis

| Pattern | Alternativa Go |
|---------|----------------|
| Mediator | Injetar dependencias explicitas |
| Memento | Persistir estado em banco |
| Visitor | Type switch para tipos fechados |
| Command | Funcao ou closure |
| Iterator | `range` + funcoes de transformacao |

## Proibido
- Pattern sem problema recorrente que o justifique.
- Mais de um pattern para o mesmo problema.
- Pattern que exige `reflect` quando tipagem estatica resolveria.
