# Persistencia

## Objetivo
Manter acesso a dados explicito, testavel e isolado do dominio.

## Diretrizes

### Repository
- Repository encapsula acesso a dados e expoe operacoes do dominio, nao queries genericas.
- Definir interface de repository no lado consumidor (use case ou dominio) quando houver necessidade real de substituicao.
- Repository concreto pertence a camada de infraestrutura.
- Nao vazar abstracoes de banco (SQL, ORM, driver) para fora do repository.

### Transactions
- Gerenciar transacoes na camada de aplicacao (use case), nao no repository individual.
- Usar padrao explicito para Unit of Work quando multiplos repositories participarem da mesma transacao.
- Nao abrir transacao para leitura simples sem necessidade de consistencia.

### Connection Management
- Configurar pool de conexoes com limites explicitos quando o driver suportar.
- Fechar conexoes e cursores de forma deterministica (using, try/finally, dispose).
- Usar timeout em todas as operacoes de banco.

### Migrations
- Migrations devem ser versionadas, idempotentes e auditaveis.
- Usar ferramenta do ecossistema: Prisma Migrate, TypeORM migrations, Knex migrations, Drizzle Kit.
- Separar migrations de esquema (DDL) de migrations de dados (DML) quando possivel.
- Nao rodar migrations destrutivas automaticamente em producao.
- Sempre escrever migration de rollback quando possivel.

### Queries
- Preferir queries explicitas ou query builder tipado a queries raw quando o ORM suportar.
- Usar queries parametrizadas para evitar SQL injection.
- Nao construir queries por concatenacao de strings com input externo.

## Riscos Comuns
- Repository que retorna modelos do ORM em vez de entidades de dominio.
- Transacao aberta sem tratamento de erro para rollback.
- Connection leak por cursor ou client nao fechado.
- Migration destrutiva sem rollback possivel.
- N+1 queries por lazy loading nao controlado.

## Proibido
- SQL injection por concatenacao de input.
- Dominio importando pacote de driver ou ORM.
- Transacao sem timeout.
