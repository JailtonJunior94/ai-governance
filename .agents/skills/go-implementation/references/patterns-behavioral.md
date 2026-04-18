# Behavioral Patterns

## Strategy
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

type Service struct {
    pricer pricer
}
```

## Chain of Responsibility (Middleware Chain)
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

## Observer (Event/Callback)
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

## State
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

## Template Method
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
