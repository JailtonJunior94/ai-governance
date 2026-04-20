# Seguranca de Aplicacao

<!-- @lang: go, node, python -->

## Input Validation
- Usar schema validation (Node: zod, joi, class-validator; Python: pydantic, marshmallow, attrs) em vez de validacao manual.
- Usar allowlist em vez de denylist quando possivel.

## Autenticacao e Autorizacao
- Autenticacao em middleware ou dependency, autorizacao no use case ou handler.
- Validar tokens (JWT, opaque) em cada request — nao cachear decisao de autenticacao entre requests.
- Verificar claims relevantes: expiracao, audience, issuer.

## HTTP
- Configurar CORS com origins explicitos — nao usar `*` em producao.
- Aplicar rate limiting em endpoints publicos.
- Em Node: usar `helmet` ou headers de seguranca equivalentes.

## SQL e Persistencia
- Usar queries parametrizadas ou ORM — nunca concatenar input em SQL.

## Dependencias
- Rodar auditoria de dependencias periodicamente ou em CI (Node: `npm audit`/`pnpm audit`; Python: `pip-audit`/`safety check`).
- Em Python: rodar `bandit` como linter de seguranca estatica em CI.
- Nao instalar pacotes sem verificar manutencao ativa e historico de seguranca.

## Riscos Comuns
- Node: prototype pollution via merge de objetos com input nao sanitizado.
- Python: `pickle.loads()` com input nao confiavel.
- HTTP client usado sem timeout em chamadas externas.
- Rate limiting ausente em endpoint de login ou signup.

## Proibido
- SQL por concatenacao de string com input externo.
- Response de erro expondo stack trace, query SQL ou path interno.
- `eval()`, `exec()`, `new Function()` ou `pickle.loads()` com input externo.
