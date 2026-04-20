# Tratamento de Erros

<!-- @lang: go, node, python -->

- Rule ID: R-ERR-001
- Severidade: hard
- Escopo: Todo codigo com criacao, wrapping, propagacao e apresentacao de erros.

## Objetivo
Padronizar erros com mensagens claras ao usuario e detalhes tecnicos preservados para diagnostico.

## Requisitos

### Modelagem
- Erros de dominio devem ser sentinelas ou tipos bem definidos em seus modulos.
- Erros de infraestrutura podem ser wrapped com contexto adicional.
- Mensagens internas devem ser curtas, em lowercase e estaveis.
- Node: criar classes de erro tipadas que estendam `Error` com propriedades estaveis (`code`, `statusCode`, `cause`).
- Python: criar hierarquia de excecoes a partir de uma base do projeto (ex: `AppError(Exception)`).

### Wrapping
- Preservar cadeia para inspecao programatica (`errors.Is`/`errors.As` em Go; `raise ... from` em Python; `cause` nativo ES2022+ em Node).
- Adapters devem adicionar contexto tecnico util: operacao, componente, path.

### Apresentacao
- A camada de apresentacao deve traduzir erro tecnico em mensagem acionavel.
- Mensagens ao usuario devem dizer o que falhou, onde falhou e qual acao e possivel.
- Retornar estrutura consistente de erro na API: `{"error": {"code": "...", "message": "..."}}`.

### Captura e Propagacao
- Capturar excecoes/erros na fronteira mais externa relevante (handler, command, entrypoint).
- Node: preferir `try/catch` sobre `.catch()` em fluxos async; capturar `unhandledRejection` e `uncaughtException` no entrypoint.
- Python: capturar excecoes especificas — nunca `except Exception` generico sem re-raise; usar context managers para cleanup.
- Python: logar excecao com `logger.exception()` ou `exc_info=True` para preservar traceback; nao logar e re-raise na mesma camada.

### Validacao
- Preferir bibliotecas de schema sobre validacao manual.
- Validar na fronteira de entrada (handler), nao dentro de logica de negocio.

### Retry e Remediacao
- Retry automatico deve ser restrito a falhas transitorias previsiveis.
- Numero maximo padrao de retries automaticos: 2.
- Se remediacao automatica falhar, pausar para intervencao ou encerrar de forma explicita.

### Comparacao
- Usar mecanismos idiomaticos de comparacao de erros da linguagem.
- Nao comparar erro por string quando existir alternativa tipada.

## Proibido
- `panic` (ou equivalente) para erro recuperavel.
- Engolir erro de IO, subprocesso, persistencia ou validacao.
- Exibir stack trace bruto ao usuario final.
- `except: pass` / `catch {}` silencioso.
- `throw`/`raise` para controle de fluxo nao excepcional.
- `assert` para validacao de input em producao (desativado com `-O` em Python).
- Mensagens vagas como `something went wrong`.
