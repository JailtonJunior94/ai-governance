# API (HTTP/GraphQL)

## Objetivo
Manter handlers finos, contratos explicitos e separacao clara entre transporte e logica.

## Diretrizes

### Handlers/Controllers
- Handlers devem apenas: extrair input do request, chamar use case, formatar response.
- Nao colocar regra de negocio, validacao de dominio ou orquestracao em handlers.
- Retornar status HTTP correto: 400 (input invalido), 404 (nao encontrado), 409 (conflito), 422 (regra de negocio), 500 (erro interno).
- Usar tipagem forte para request e response DTOs.

### Middlewares
- Usar middlewares para concerns transversais: autenticacao, logging, rate limiting, CORS, request ID.
- Manter middlewares pequenos e compostos em ordem explicita.
- Nao colocar logica de negocio em middleware.
- Tratar erros nao capturados em middleware de erro global — nao em cada handler.

### DTOs e Validacao
- Manter DTOs de request/response separados de entidades de dominio.
- Validar estrutura na camada de transporte com zod, joi ou class-validator.
- Nao expor entidades de dominio diretamente como JSON.

### Versionamento
- Preferir versionamento por path (`/v1/`, `/v2/`) quando necessario.
- Cada versao deve ter seu proprio adapter de DTO, reusando o mesmo use case.
- Nao introduzir breaking changes sem versionamento.

### Paginacao
- Preferir cursor-based para datasets grandes; offset para datasets pequenos e estaveis.
- Definir `limit` com default e maximo explicito.
- Retornar `nextCursor` e `hasMore` na response.

## Proibido
- Regra de dominio em handler ou middleware.
- Expor stack trace ou detalhes internos em resposta de erro.
- Handler que cresce para centenas de linhas com logica misturada.
- Ignorar cancelamento de request (abort signal) em operacoes longas.
