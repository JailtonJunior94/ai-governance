> **Carregar quando:** autenticacao, autorizacao, validacao de input, rate limiting, CORS, tratamento de segredos — **Escopo:** seguranca Python — **~500tk**
> **Base transversal:** `.agents/skills/agent-governance/references/security.md` (segredos, filesystem, execucao de comandos, input externo, dependencias). Este arquivo contem apenas o delta idiomatico Python.

# Seguranca Python

## Input Validation
- Usar schema validation (pydantic, marshmallow, attrs) em vez de validacao manual.
- Usar allowlist em vez de denylist quando possivel.

## Autenticacao e Autorizacao
- Autenticacao em middleware ou dependency, autorizacao no use case ou handler.
- Validar tokens (JWT, opaque) em cada request — nao cachear decisao de autenticacao entre requests.
- Verificar claims relevantes: expiracao, audience, issuer.

## HTTP
- Configurar CORS com origins explicitos — nao usar `*` em producao.
- Aplicar rate limiting em endpoints publicos (slowapi, django-ratelimit).

## SQL e Persistencia
- Usar queries parametrizadas ou ORM — nunca concatenar input em SQL.

## Dependencias
- Rodar `pip-audit` ou `safety check` periodicamente ou em CI.
- Rodar `bandit` como linter de seguranca estatica em CI.

## Riscos Comuns
- `requests` ou `httpx` usado sem timeout em chamadas externas.
- `pickle.loads()` com input nao confiavel.
- Rate limiting ausente em endpoint de login ou signup.

## Proibido
- SQL por concatenacao de string com input externo.
- Response de erro expondo stack trace, query SQL ou path interno.
- `eval()`, `exec()` ou `pickle.loads()` com input externo.
