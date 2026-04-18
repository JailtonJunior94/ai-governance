# Arquitetura Python

Principios gerais de arquitetura, DI e sinais de excesso estao em `shared-architecture.md` (agent-governance). Este arquivo cobre apenas especificidades Python.

## DI em Python
- Preferir factory functions e construtores. Usar `dependency-injector` ou `FastAPI Depends` apenas quando justificado.

## Estrutura de Diretorios

### Projeto novo — layouts recomendados

#### API HTTP
```
src/
  domain/<aggregate>/         # entidades, value objects, regras
  application/<usecase>/      # orquestracao, interfaces de porta
  infra/<adapter>/            # repositories, clients, messaging
  api/                        # routers, DTOs, middlewares
```

#### Worker / Consumer
```
src/
  domain/
  application/
  infra/
  workers/                    # consumers, job handlers
```

### Regras Python
- `src/` contem codigo de aplicacao; `tests/` contem testes.
- Evitar `utils/` ou `helpers/` que misturem responsabilidades.
- `__init__.py` apenas quando necessario para o import.
- Profundidade maxima: `src/<camada>/<modulo>/`.
