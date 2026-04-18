# Tratamento de Erros Python

## Modelagem
- Criar hierarquia de excecoes a partir de uma base do projeto (ex: `AppError(Exception)`).
- Separar excecoes de dominio (ex: `OrderAlreadyShipped`) de excecoes de infraestrutura (ex: `DatabaseConnectionError`).
- Usar `raise ... from err` para preservar cadeia de excecao (PEP 3134).

## Captura
- Capturar excecoes especificas — nunca `except Exception` generico sem re-raise.
- Usar context managers (`with`) para garantir cleanup de recursos (arquivos, conexoes, locks).
- Capturar na fronteira mais externa relevante (handler, command, entrypoint).

## Apresentacao
- A camada de transporte (view/handler) traduz excecao interna em resposta HTTP adequada.
- Retornar estrutura consistente: `{"error": {"code": "...", "message": "..."}}`.

## Validacao
- Preferir pydantic, attrs ou marshmallow sobre validacao manual.
- Validar na fronteira de entrada, nao dentro da logica de negocio.

## Logging de Erros
- Logar excecao com `logger.exception()` ou `logger.error(..., exc_info=True)` para preservar traceback.
- Nao logar e re-raise na mesma camada — logar uma vez na fronteira mais externa.

## Proibido
- `except: pass` ou `except Exception: pass` silencioso.
- Usar `assert` para validacao de input em producao (desativado com `-O`).
- Comparar excecao por mensagem string quando existir tipo tipado.
- Expor traceback em resposta HTTP de producao.
