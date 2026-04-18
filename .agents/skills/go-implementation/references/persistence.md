# Persistência

## Objetivo
Manter acesso a dados explícito, testável e isolado do domínio.

## Diretrizes

### Repository
- Repository encapsula acesso a dados e expõe operações do domínio, não queries genéricas.
- Definir interface de repository no lado consumidor (use case ou domínio) quando houver necessidade real de substituição.
- Repository concreto pertence à camada de infraestrutura.
- Não vazar abstrações de banco (SQL, ORM, driver) para fora do repository.

### Transactions
- Gerenciar transações na camada de aplicação (use case), não no repository individual.
- Usar padrão explícito para Unit of Work quando múltiplos repositories participarem da mesma transação.
- Não abrir transação para leitura simples sem necessidade de consistência.

### Connection Management
- Configurar pool de conexões com limites explícitos: max open, max idle, lifetime.
- Usar `context.Context` em todas as operações de banco para propagação de cancelamento e timeout.
- Fechar conexões e statements de forma determinística.

### Migrations
- Migrations devem ser versionadas, idempotentes e auditáveis.
- Separar migrations de esquema (DDL) de migrations de dados (DML) quando possível.
- Não rodar migrations destrutivas automaticamente em produção.

### Migrations (golang-migrate)
- Usar [golang-migrate](https://github.com/golang-migrate/migrate) como ferramenta padrão para migrations versionadas.
- Migrations ficam em diretório dedicado: `migrations/` na raiz ou `internal/infra/<adapter>/migrations/`.
- Cada migration é um par de arquivos: `NNNNNN_description.up.sql` e `NNNNNN_description.down.sql`.
- Numerar migrations sequencialmente ou com timestamp — manter consistência dentro do projeto.
- Rodar migrations na inicialização do serviço (dev/staging) ou via CI/CD (produção).
- Sempre escrever migration de rollback (`down.sql`) para DDL reversível.
- Não misturar DDL e DML na mesma migration quando possível.

```bash
# Criar nova migration
migrate create -ext sql -dir migrations -seq add_orders_table

# Aplicar migrations
migrate -path migrations -database "$DATABASE_URL" up

# Rollback da última migration
migrate -path migrations -database "$DATABASE_URL" down 1

# Ver versão atual
migrate -path migrations -database "$DATABASE_URL" version
```

```go
// cmd/server/main.go — migrations programáticas na inicialização
import (
    "github.com/golang-migrate/migrate/v4"
    _ "github.com/golang-migrate/migrate/v4/database/postgres"
    _ "github.com/golang-migrate/migrate/v4/source/file"
)

func runMigrations(dsn string) error {
    m, err := migrate.New("file://migrations", dsn)
    if err != nil {
        return fmt.Errorf("creating migrator: %w", err)
    }
    defer m.Close()

    if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
        return fmt.Errorf("running migrations: %w", err)
    }
    return nil
}
```

### Queries
- Preferir queries explícitas a query builders genéricos quando a complexidade for baixa.
- Usar prepared statements ou parametrização para evitar SQL injection.
- Não construir queries por concatenação de strings com input externo.

## Riscos Comuns
- Repository que retorna structs do ORM em vez de entidades de domínio.
- Transação aberta sem defer de rollback.
- Connection leak por statement ou rows não fechados.
- Migration destrutiva sem rollback possível.

## Proibido
- SQL injection por concatenação de input.
- Domínio importando pacote de driver ou ORM.
- Transação sem timeout ou cancelamento.
