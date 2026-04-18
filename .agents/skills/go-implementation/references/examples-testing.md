# Exemplos: Testes e Validacao

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
            return // input invalido e esperado — apenas nao deve panic
        }
        // round-trip: valor parseado deve ser re-serializavel
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
