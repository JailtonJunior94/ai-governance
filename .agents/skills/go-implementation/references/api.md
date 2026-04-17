# API (HTTP/gRPC)

## Objetivo
Manter handlers finos, contratos explícitos e separação clara entre transporte e lógica.

## Diretrizes

### Handlers
- Handlers devem apenas: decodificar request, chamar use case, codificar response.
- Não colocar regra de negócio, validação de domínio ou orquestração em handlers.
- Retornar status HTTP/gRPC code correto para cada cenário: 400 para input inválido, 404 para recurso inexistente, 409 para conflito, 422 para regra de negócio, 500 para erro interno.
- Usar `context.Context` do request para propagação de cancelamento e tracing.

### Middlewares
- Usar middlewares para concerns transversais: autenticação, logging, métricas, recovery, CORS, request ID.
- Manter middlewares pequenos e compostos em ordem explícita.
- Não colocar lógica de negócio em middleware.

### Validação de Request
- Validar estrutura e tipos na camada de transporte (handler ou DTO).
- Validar regras de negócio no domínio ou use case, não no handler.
- Falhar cedo com mensagem clara indicando o campo e a restrição violada.

### Serialização
- Manter DTOs de request/response separados de structs de domínio.
- Não expor entidades de domínio diretamente como JSON/protobuf.
- Usar tags de serialização explícitas (`json:"field_name"`).

### Versionamento
- Preferir versionamento por path (`/v1/`, `/v2/`) quando necessário.
- Evitar breaking changes em contratos publicados sem versionamento.
- Documentar contratos com OpenAPI ou protobuf como fonte de verdade quando o projeto adotar essa prática.
- Manter versão anterior ativa até que consumidores migrem — deprecar com prazo comunicado.
- Cada versão deve ter seu próprio handler ou adapter de DTO, reusando o mesmo use case.

### Pagination
- Preferir cursor-based pagination para datasets grandes ou com inserções frequentes — offset pagination é aceitável para datasets pequenos e estáveis.
- Definir `limit` com default (ex: 20) e máximo (ex: 100) — rejeitar valores fora do range.
- Retornar `next_cursor` e `has_more` na response para que o cliente saiba se há mais páginas.
- Cursor deve ser opaco para o cliente (base64 de ID ou timestamp).
- Não usar `OFFSET` com valores altos em SQL — performance degrada linearmente.

### Bulk Operations
- Limitar tamanho de batch com máximo explícito (ex: 100 itens por request).
- Retornar resultado individual por item quando operações puderem falhar parcialmente.
- Usar transação quando atomicidade do batch for requisito de negócio.
- Retornar 207 (Multi-Status) quando o resultado for misto (alguns itens ok, outros com erro).

### Graceful Shutdown
- Capturar sinais de encerramento (SIGTERM, SIGINT) e drenar conexões ativas.
- Definir timeout de shutdown explícito.
- Fechar dependências (banco, filas, cache) na ordem inversa de inicialização.

## Riscos Comuns
- Handler que cresce para centenas de linhas com lógica misturada.
- DTO reusado entre request, response e domínio causando acoplamento.
- Middleware que engole erro e retorna 200.
- Shutdown abrupto causando requests cortados.

## Proibido
- Regra de domínio em handler ou middleware.
- Expor stack trace ou detalhes internos em response de erro para o cliente.
- Ignorar cancelamento de context em operações longas.
