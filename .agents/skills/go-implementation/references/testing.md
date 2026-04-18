# Testes

## Objetivo
Garantir correção, prevenir regressão e documentar comportamento com custo proporcional ao risco.

## Unit Tests (obrigatorio)
- Todo comportamento de dominio, use case e logica pura deve ter unit test.
- Table-driven tests para variacoes de input/output.
- `testify/assert`, `testify/require` para assercoes. `testify/suite` quando setup compartilhado justificar.
- `testify/mock` ou `mockery` para substituir dependencias em fronteiras.
- Nomear pelo cenario: `TestConfirm_OrderAlreadyShipped`, nao `TestConfirm3`.
- Testes deterministicos — sem sleep, sem estado global. Usar `t.Parallel()` quando possivel.
- Fuzz tests para parsers e validadores com input arbitrario.
- Arquivo de teste ao lado do testado: `service.go` -> `service_test.go`.
- Mocks em `mocks/` do pacote consumidor. Helpers em `_test.go` do mesmo pacote.
- Nao testar glue code sem logica nem interacao real com banco/fila (isso e integration test).

## Integration Tests (opcional — decisao por projeto)
Adotar quando: fronteiras de IO criticas onde mocks nao garantem correcao, ou incidente previo de divergencia mock/prod.

- Usar [testcontainers-go](https://golang.testcontainers.org/) para containers efemeros.
- Build tag `//go:build integration` para separar de `go test ./...`.
- Cada suite provisiona e destroi seu container. Usar `t.Cleanup`/`defer` para teardown.

```go
//go:build integration

type RepositorySuite struct {
    suite.Suite
    container *postgres.PostgresContainer
    dsn       string
}

func TestRepositorySuite(t *testing.T) { suite.Run(t, new(RepositorySuite)) }

func (s *RepositorySuite) SetupSuite() {
    ctx := context.Background()
    container, err := postgres.Run(ctx, "postgres:16-alpine",
        postgres.WithDatabase("testdb"), postgres.WithUsername("test"), postgres.WithPassword("test"),
        testcontainers.WithWaitStrategy(wait.ForLog("database system is ready to accept connections").WithOccurrence(2)),
    )
    s.Require().NoError(err)
    dsn, err := container.ConnectionString(ctx, "sslmode=disable")
    s.Require().NoError(err)
    s.container = container
    s.dsn = dsn
}

func (s *RepositorySuite) TearDownSuite() {
    if s.container != nil { s.Require().NoError(s.container.Terminate(context.Background())) }
}
```

Modulos disponiveis: postgres, mysql, redis, kafka, mongodb, rabbitmq, localstack.

## Riscos Comuns
- Mock que não reflete o contrato real da dependência — teste passa, produção falha.
- Integration test sem build tag rodando em CI rápido e quebrando por falta de Docker.
- Test helper com lógica complexa que precisa de seus próprios testes.
- Teste que valida implementação interna em vez de comportamento observável.

## Proibido
- Teste que depende de serviço externo real (banco de dev, API de staging).
- `time.Sleep` para sincronização em teste.
- Teste que passa sozinho mas falha quando rodado com `./...`.
- Ignorar `t.Helper()` em funções auxiliares de teste.
