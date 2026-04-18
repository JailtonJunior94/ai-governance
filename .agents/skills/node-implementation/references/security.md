> **Carregar quando:** autenticacao, autorizacao, validacao de input, rate limiting, CORS, tratamento de segredos — **Escopo:** seguranca Node/TypeScript — **~500tk**
> **Base transversal:** `.agents/skills/agent-governance/references/security.md` (segredos, filesystem, execucao de comandos, input externo, dependencias). Este arquivo contem apenas o delta idiomatico Node/TypeScript.

# Seguranca Node/TypeScript

## Input Validation
- Usar schema validation (zod, joi, class-validator) em vez de validacao manual.
- Usar allowlist em vez de denylist quando possivel.

## Autenticacao e Autorizacao
- Autenticacao em middleware, autorizacao no use case ou handler.
- Validar tokens (JWT, opaque) em cada request — nao cachear decisao de autenticacao entre requests.
- Verificar claims relevantes: expiracao, audience, issuer.

## HTTP
- Usar `helmet` ou headers de seguranca equivalentes: `Content-Type`, `X-Content-Type-Options`, `Strict-Transport-Security`.
- Configurar CORS com origins explicitos — nao usar `*` em producao.
- Aplicar rate limiting em endpoints publicos (express-rate-limit, fastify-rate-limit).

## SQL e Persistencia
- Usar queries parametrizadas ou ORM — nunca concatenar input em SQL.

## Dependencias
- Rodar `npm audit` ou `pnpm audit` periodicamente ou em CI.
- Nao instalar pacotes sem verificar manutencao ativa e historico de seguranca.

## Riscos Comuns
- Prototype pollution via merge de objetos com input nao sanitizado.
- `node-fetch` ou `axios` usado sem timeout em chamadas externas.
- Rate limiting ausente em endpoint de login ou signup.

## Proibido
- SQL por concatenacao de string com input externo.
- Response de erro expondo stack trace, query SQL ou path interno.
- `eval()` ou `new Function()` com input externo.
