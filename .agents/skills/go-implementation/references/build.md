# Build, Container e CI

## Objetivo
Manter builds reprodutíveis, imagens mínimas e gates de qualidade no pipeline.

## Diretrizes

### Dockerfile Multi-stage

- Usar multi-stage build para separar compilação de runtime.
- Stage de build: imagem com toolchain Go completo.
- Stage de runtime: `distroless`, `alpine` ou `scratch` — sem shell, package manager ou ferramentas desnecessárias.
- Copiar apenas o binário compilado e assets obrigatórios (migrations, configs) para a imagem final.
- Compilar com `CGO_ENABLED=0` quando não houver dependência de C para permitir `scratch` ou `distroless`.

```dockerfile
FROM golang:1.23-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /bin/server ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /bin/server /server
COPY --from=build /app/migrations /migrations
USER nonroot:nonroot
ENTRYPOINT ["/server"]
```

- Usar `.dockerignore` para excluir `.git`, `docs`, `tmp`, `*.md` e testes do contexto de build.
- Fixar versão da imagem base (tag + digest quando possível) — não usar `latest`.
- Rodar como usuário não-root (`USER nonroot` ou UID numérico).

### Makefile

- Usar Makefile como interface unificada para build, test, lint e run — mesmo que CI use comandos diretos.
- Targets mínimos recomendados:

```makefile
.PHONY: build test lint fmt vet run

build:
	CGO_ENABLED=0 go build -o bin/server ./cmd/server

test:
	go test -race -count=1 ./...

lint:
	golangci-lint run ./...

fmt:
	gofmt -l -w .

vet:
	go vet ./...

run: build
	./bin/server
```

- Não duplicar lógica entre Makefile e Dockerfile — Dockerfile chama `go build` diretamente, Makefile é para uso local e CI.
- Usar variáveis para valores que mudam entre ambientes (versão Go, nome do binário, flags de build).

### CI — Gates de Qualidade

- Pipeline mínimo para PR:
  1. `go vet ./...`
  2. `golangci-lint run ./...`
  3. `go test -race -count=1 ./...`
  4. `govulncheck ./...`
- Rodar testes com `-race` para detectar data races.
- Usar `-count=1` para desabilitar cache de teste em CI.
- Falhar o pipeline em qualquer warning de lint — não usar `--allow-errors`.
- Rodar `govulncheck` para vulnerabilidades conhecidas em dependências.
- Rodar `gosec ./...` como gate de segurança estática quando o projeto adotar.

### Build Flags

- Injetar versão e commit via `-ldflags` para rastreabilidade:

```bash
go build -ldflags "-X main.version=$(git describe --tags) -X main.commit=$(git rev-parse --short HEAD)" -o bin/server ./cmd/server
```

- Não usar `-ldflags` para configuração de runtime — usar variáveis de ambiente ou config files.
- Usar build tags (`//go:build integration`) para separar testes de integração dos unitários.

```bash
# Apenas unitários (default)
go test ./...

# Incluindo integração
go test -tags=integration ./...
```

### Cache em CI

- Cachear `GOMODCACHE` e `GOCACHE` entre builds para reduzir tempo de pipeline.
- Invalidar cache quando `go.sum` mudar.
- Em Docker build, copiar `go.mod` e `go.sum` antes do código-fonte para aproveitar layer cache no `go mod download`.

## Riscos Comuns
- Imagem final com toolchain Go completo expondo superfície de ataque desnecessária.
- Build sem `-race` em CI deixando data races passarem silenciosamente.
- Cache de teste em CI mascarando falhas intermitentes.
- Dockerfile usando `latest` quebrando builds por mudança implícita de versão.
- Binário sem informação de versão dificultando diagnóstico em produção.

## Proibido
- Container rodando como root em produção.
- Segredo passado como build arg ou variável de ambiente no Dockerfile.
- Pipeline de CI sem gate de teste.
- Ignorar falhas de lint com flags de supressão global.
