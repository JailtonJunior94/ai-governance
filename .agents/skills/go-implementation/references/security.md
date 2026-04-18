# Segurança

## Objetivo
Proteger o sistema contra vulnerabilidades comuns em backends Go.

## Diretrizes

### Input Validation
- Validar e sanitizar todo input externo (request body, query params, headers, path params).
- Usar allowlist em vez de denylist quando possível.
- Limitar tamanho de request body com `http.MaxBytesReader`.
- Não confiar em input do cliente para decisões de autorização.

### Autenticação e Autorização
- Autenticação em middleware, autorização no use case ou handler.
- Validar tokens (JWT, opaque) em cada request — não cachear decisão de autenticação entre requests.
- Verificar claims relevantes: expiração, audience, issuer.
- Aplicar princípio de menor privilégio em permissões e roles.

### Segredos
- Carregar segredos de variáveis de ambiente ou secret manager — nunca hardcoded.
- Não logar segredos, tokens ou credenciais em nenhum nível de log.
- Não expor segredos em mensagens de erro ou responses.

### HTTP
- Configurar headers de segurança: `Content-Type`, `X-Content-Type-Options`, `Strict-Transport-Security`.
- Configurar CORS com origins explícitos — não usar `*` em produção.
- Aplicar rate limiting em endpoints públicos.
- Usar TLS em produção.

### SQL e Persistência
- Usar queries parametrizadas — nunca concatenar input em SQL.
- Validar e escapar input antes de usar em queries dinâmicas quando parametrização não for possível.

### CSRF
- APIs stateless com Bearer token não precisam de proteção CSRF.
- APIs que usam cookies de sessão devem aplicar token CSRF (double submit cookie ou synchronizer token).

### Criptografia e Rotação de Chaves
- Versionar chaves de assinatura (JWT `kid` header) para permitir rotação sem downtime.
- Não implementar criptografia própria — usar `crypto/*` da stdlib ou bibliotecas auditadas.
- Usar algoritmos assimétricos (RS256, ES256) quando múltiplos serviços validam tokens; simétricos (HS256) apenas quando emissor e verificador são o mesmo serviço.

### Dependências
- Rodar `govulncheck` periodicamente ou em CI para detectar vulnerabilidades conhecidas.
- Rodar `gosec` como linter de segurança estática em CI.
- Manter dependências atualizadas com `go get -u` de forma controlada.

## Riscos Comuns
- JWT validado apenas por assinatura sem verificar expiração ou audience.
- Rate limiting ausente em endpoint de login ou signup.
- CORS permissivo expondo API a origens não autorizadas.
- `http.DefaultClient` usado sem timeout em chamadas externas.

## Proibido
- Segredo hardcoded em código ou arquivo commitado.
- SQL por concatenação de string com input externo.
- Response de erro expondo stack trace, query SQL ou path interno.
- Desabilitar verificação de TLS (`InsecureSkipVerify: true`) em produção.
