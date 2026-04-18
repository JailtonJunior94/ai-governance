# Arquitetura Go

Principios gerais de arquitetura, DI e sinais de excesso estao em `shared-architecture.md` (agent-governance). Este arquivo cobre apenas especificidades Go.

## DI em Go
- DI manual via construtores. Wire/fx apenas quando arvore de dependencias justificar.

## Estrutura de Diretorios

### Projeto novo — layouts recomendados

#### Serviço HTTP/gRPC
```
cmd/<service>/main.go
internal/
  domain/<aggregate>/         # entidades, value objects, regras
  application/<usecase>/      # orquestração, interfaces de porta
  infra/<adapter>/            # repositórios, clients, messaging
  handler/                    # HTTP/gRPC handlers, DTOs, middlewares
```

#### Worker / Consumer
```
cmd/<worker>/main.go
internal/
  domain/
  application/
  infra/
```

#### Monolito modular
```
cmd/server/main.go
internal/
  <module>/
    domain/
    application/
    infra/
    handler/
```

#### CLI
```
cmd/<cli>/main.go              # bootstrap, root command
internal/
  cmd/                         # subcommands (cada arquivo = um comando)
  config/                      # flags, env, config file parsing
  output/                      # formatação de saída (table, JSON, text)
  domain/                      # lógica de negócio quando houver
  infra/                       # clients, filesystem, IO
```
- Root command em `main.go` com wiring de subcommands.
- Cada subcommand em arquivo separado dentro de `internal/cmd/`.
- Flags e args validados no command, lógica delegada para camada interna.
- Saída formatada em camada própria — não misturar `fmt.Println` com lógica.
- Usar `cobra` ou stdlib `flag` conforme complexidade; não impor framework para CLI de 2 comandos.

### Regras Go
- `cmd/` apenas bootstrap. `internal/` como default. `pkg/` apenas se genuinamente reutilizavel.
- Profundidade maxima: `internal/<camada>/<pacote>/`.
