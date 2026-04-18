# API (HTTP) Python

## Objetivo
Manter handlers finos, contratos explicitos e separacao clara entre transporte e logica.

## Diretrizes

### Handlers/Views
- Handlers devem apenas: extrair input do request, chamar use case, formatar response.
- Nao colocar regra de negocio, validacao de dominio ou orquestracao em handlers.
- Retornar status HTTP correto: 400, 404, 409, 422, 500 conforme o cenario.
- Usar tipagem forte para request e response schemas.

### Frameworks
- FastAPI: usar Pydantic models para request/response, `Depends()` para injecao.
- Django: usar serializers para validacao, views/viewsets finos, logica no service layer.
- Flask: usar blueprints para organizacao, marshmallow para validacao.
- Respeitar as convencoes do framework ja adotado no projeto.

### Middlewares
- Usar middlewares para concerns transversais: autenticacao, logging, CORS, request ID.
- Nao colocar logica de negocio em middleware.
- Tratar excecoes nao capturadas em exception handler global.

### DTOs e Validacao
- Manter schemas de request/response separados de entidades de dominio.
- Validar estrutura na camada de transporte com pydantic, marshmallow ou serializers.
- Nao expor modelos ORM diretamente como resposta JSON.

### Paginacao
- Preferir cursor-based para datasets grandes; offset para datasets pequenos.
- Definir `limit` com default e maximo explicito.
- Retornar `next_cursor` e `has_more` na response.

## Proibido
- Regra de dominio em handler ou middleware.
- Expor traceback ou detalhes internos em resposta de erro.
- Queries SQL diretas em handlers — usar repository ou ORM layer.
