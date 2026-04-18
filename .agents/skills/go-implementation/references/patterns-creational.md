# Creational Patterns

## Principios Gerais de Design Patterns em Go
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

## Factory Function
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

## Builder
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

## Singleton
**Quando usar:** Quase nunca. Usar apenas para recursos genuinamente unicos (pool de conexao inicializado uma vez).
**Em Go:** `sync.Once` quando inevitavel. Preferir injecao explicita via construtor.

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

## Proibido
- Pattern introduzido sem problema recorrente que o justifique.
- Mais de um pattern para o mesmo problema.
- Pattern que exige `reflect` para funcionar quando tipagem estatica resolveria.
- Factory abstrata para um unico tipo concreto.
