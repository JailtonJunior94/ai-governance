# Arquitetura Node/TypeScript

Principios gerais de arquitetura, DI e sinais de excesso estao em `shared-architecture.md` (agent-governance). Este arquivo cobre apenas especificidades Node/TypeScript.

## DI em Node/TypeScript
- Preferir construtores e factory functions. Usar `tsyringe`, `inversify` ou NestJS modules apenas quando justificado.

## Estrutura de Diretorios

### Projeto novo — layouts recomendados

#### API HTTP/gRPC
```
src/
  domain/<aggregate>/         # entidades, value objects, regras
  application/<usecase>/      # orquestracao, interfaces de porta
  infra/<adapter>/            # repositories, clients, messaging
  http/                       # controllers, DTOs, middlewares
```

#### Worker / Consumer
```
src/
  domain/
  application/
  infra/
  workers/                    # consumers, job handlers
```

### Regras Node/TypeScript
- `src/` contem codigo; `test/` ou `__tests__/` contem testes.
- Evitar `utils/` ou `helpers/` que misturem responsabilidades.
- Profundidade maxima: `src/<camada>/<modulo>/`.
