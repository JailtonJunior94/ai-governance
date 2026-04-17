# Testes

## Objetivo
Garantir correção, prevenir regressão e documentar comportamento com custo proporcional ao risco.

## Unit Tests (obrigatório)

### Diretrizes
- Todo comportamento de domínio, use case e lógica pura deve ter unit test.
- Usar table-driven tests para cobrir variações de input/output.
- Usar `testify/assert` e `testify/require` para asserções claras.
- Usar `testify/suite` quando setup/teardown compartilhado justificar.
- Usar `testify/mock` ou `mockery` para substituir dependências em fronteiras.
- Nomear testes pelo cenário, não pelo método: `TestConfirm_OrderAlreadyShipped` em vez de `TestConfirm3`.
- Manter testes determinísticos — sem sleep, sem dependência de ordem, sem estado global.
- Usar `t.Parallel()` quando o teste não compartilhar estado mutável.
- Fuzz tests para parsers, validadores e funções que aceitam input arbitrário.

### Estrutura
- Arquivo de teste ao lado do arquivo testado: `service.go` → `service_test.go`.
- Mocks gerados no subdiretório `mocks/` do pacote consumidor.
- Test helpers em `_test.go` ou `testutil_test.go` no mesmo pacote — não em pacote compartilhado.

### O que não testar com unit test
- Glue code sem lógica (construtores triviais, DTOs, wiring).
- Interação real com banco, fila ou serviço externo — isso é integration test.

## Integration Tests (opcional — decisão por projeto)

> **Decisão de techspec:** a necessidade de integration tests deve ser avaliada na especificação técnica de cada projeto. Perguntas a responder antes de adotar:
> - O projeto tem fronteiras de IO críticas (banco, fila, cache) onde mocks não garantem correção?
> - Já houve incidente onde unit tests passaram mas a integração real falhou?
> - O custo de manter containers de teste é proporcional ao risco coberto?
>
> Se a resposta for "sim" para pelo menos duas, integration tests são recomendados.

### Diretrizes (quando adotados)
- Usar [testcontainers-go](https://golang.testcontainers.org/) para provisionar dependências reais (Postgres, Redis, Kafka, etc.) em containers efêmeros.
- Separar integration tests com build tag `//go:build integration` para não rodar no `go test ./...` padrão.
- Rodar com comando explícito: `go test -tags=integration ./...`.
- Cada suite de integração deve provisionar e destruir seu container — não depender de infraestrutura pré-existente.
- Usar `t.Cleanup` ou `defer` para garantir teardown mesmo em falha.

### Testcontainers — padrão de uso
```go
//go:build integration

package repository_test

import (
    "context"
    "testing"

    "github.com/stretchr/testify/suite"
    "github.com/testcontainers/testcontainers-go"
    "github.com/testcontainers/testcontainers-go/modules/postgres"
    "github.com/testcontainers/testcontainers-go/wait"
)

type RepositorySuite struct {
    suite.Suite
    container *postgres.PostgresContainer
    dsn       string
}

func TestRepositorySuite(t *testing.T) {
    suite.Run(t, new(RepositorySuite))
}

func (s *RepositorySuite) SetupSuite() {
    ctx := context.Background()
    container, err := postgres.Run(ctx, "postgres:16-alpine",
        postgres.WithDatabase("testdb"),
        postgres.WithUsername("test"),
        postgres.WithPassword("test"),
        testcontainers.WithWaitStrategy(
            wait.ForLog("database system is ready to accept connections").
                WithOccurrence(2),
        ),
    )
    s.Require().NoError(err)

    dsn, err := container.ConnectionString(ctx, "sslmode=disable")
    s.Require().NoError(err)

    s.container = container
    s.dsn = dsn
    // rodar migrations aqui
}

func (s *RepositorySuite) TearDownSuite() {
    if s.container != nil {
        s.Require().NoError(s.container.Terminate(context.Background()))
    }
}

func (s *RepositorySuite) TestSaveAndFindByID() {
    // usar s.dsn para criar repository real e testar
}
```

### Testcontainers — módulos disponíveis
- `testcontainers-go/modules/postgres` — PostgreSQL
- `testcontainers-go/modules/mysql` — MySQL
- `testcontainers-go/modules/redis` — Redis
- `testcontainers-go/modules/kafka` — Kafka (via Redpanda)
- `testcontainers-go/modules/mongodb` — MongoDB
- `testcontainers-go/modules/rabbitmq` — RabbitMQ
- `testcontainers-go/modules/localstack` — AWS services (S3, SQS, SNS, DynamoDB)

Consultar [documentação oficial](https://golang.testcontainers.org/modules/) para lista completa e opções de configuração.

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
