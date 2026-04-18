# Persistencia

## Objetivo
Manter acesso a dados explicito, testavel e isolado do dominio.

## Diretrizes

### Repository
- Repository encapsula acesso a dados e expoe operacoes do dominio, nao queries genericas.
- Definir interface (Protocol/ABC) de repository no lado consumidor quando houver necessidade real de substituicao.
- Repository concreto pertence a camada de infraestrutura.
- Nao vazar abstracoes de banco (SQL, ORM, driver) para fora do repository.

### Transactions
- Gerenciar transacoes na camada de aplicacao (use case), nao no repository individual.
- Usar padrao explicito para Unit of Work quando multiplos repositories participarem da mesma transacao.
- Nao abrir transacao para leitura simples sem necessidade de consistencia.

### Connection Management
- Configurar pool de conexoes com limites explicitos (SQLAlchemy pool_size, max_overflow).
- Fechar sessoes e conexoes de forma deterministica (context manager, dependency cleanup).
- Usar timeout em todas as operacoes de banco.

### Migrations
- Migrations devem ser versionadas, idempotentes e auditaveis.
- Usar ferramenta do ecossistema: Alembic, Django migrations, piccolo migrations.
- Separar migrations de esquema (DDL) de migrations de dados (DML) quando possivel.
- Nao rodar migrations destrutivas automaticamente em producao.
- Sempre escrever migration de rollback (downgrade) quando possivel.

### Queries
- Preferir ORM ou query builder tipado a queries raw quando a complexidade for baixa.
- Usar queries parametrizadas para evitar SQL injection.
- Nao construir queries por concatenacao de strings com input externo.

## Riscos Comuns
- Repository que retorna modelos do ORM em vez de entidades de dominio.
- Sessao aberta sem tratamento de erro para rollback.
- Connection leak por sessao nao fechada.
- Migration destrutiva sem rollback possivel.
- N+1 queries por lazy loading nao controlado.

## Proibido
- SQL injection por concatenacao de input.
- Dominio importando pacote de driver ou ORM.
- Sessao/transacao sem timeout.
