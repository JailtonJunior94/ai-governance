# Tratamento de Erros Node/TypeScript

## Modelagem
- Criar classes de erro tipadas que estendam `Error` com propriedades estaveis (`code`, `statusCode`, `cause`).
- Separar erros operacionais (input invalido, timeout, recurso inexistente) de erros de programacao (null reference, type error).
- Usar `cause` nativo (ES2022+) para encadear erros preservando stack original.

## Async/Await
- Preferir `try/catch` sobre `.catch()` em fluxos com multiplas etapas.
- Nunca deixar promise sem handler — toda promise deve ter `await` ou `.catch()` explicito.
- Capturar `unhandledRejection` e `uncaughtException` no entrypoint para log e shutdown controlado.

## Apresentacao
- A camada de transporte (handler/controller) traduz erro interno em resposta HTTP adequada.
- Retornar estrutura consistente: `{ error: { code, message } }`.

## Validacao
- Preferir bibliotecas de schema (zod, joi, class-validator) sobre validacao manual.
- Validar na fronteira de entrada (handler), nao dentro de logica de negocio.

## Proibido
- Usar `throw` para controle de fluxo nao excepcional.
- Comparar erro por mensagem string quando existir `code` ou `instanceof`.
- Expor stack trace em resposta HTTP de producao.
