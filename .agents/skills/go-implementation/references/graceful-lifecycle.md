> **Carregar quando:** inicialização ordenada, shutdown gracioso, signal handling, drain de conexões, goroutines de longa duração — **Escopo:** lifecycle, signals, encerramento — **~1050tk**

# Graceful Lifecycle

## Objetivo
Unificar padrões de inicialização ordenada e encerramento gracioso para servidores, workers, consumers e CLIs.

## Diretrizes

### Inicialização
- Inicializar dependências em ordem explícita: config → logger → telemetry → database → cache → messaging → server.
- Falhar fast se uma dependência obrigatória não estiver disponível na inicialização — não iniciar parcialmente.
- Logar versão, build info e configuração não-sensível no startup para diagnóstico.
- Usar readiness probe para sinalizar que o serviço está pronto para receber tráfego — não expor o endpoint antes da inicialização completa.

### Sinais e Cancelamento
- Capturar `SIGTERM` e `SIGINT` com `signal.NotifyContext` para obter um `context.Context` cancelável.
- Propagar o context de shutdown para todas as goroutines e operações de longa duração.
- Não usar `os.Exit` diretamente em goroutines — deixar o shutdown coordenado fluir até `main`.

```go
ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
defer stop()
```

### Shutdown de Servidor HTTP/gRPC
- Chamar `server.Shutdown(ctx)` com timeout explícito para drenar conexões ativas.
- Timeout de shutdown deve ser menor que o `terminationGracePeriodSeconds` do orquestrador (Kubernetes: default 30s).
- Parar de aceitar novas conexões imediatamente; aguardar requests em andamento até o timeout.

```go
shutdownCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
defer cancel()
if err := server.Shutdown(shutdownCtx); err != nil {
    slog.Error("server shutdown failed", "error", err)
}
```

### Shutdown de Workers e Consumers
- Toda goroutine de longa duração deve respeitar cancelamento via `context.Context` ou channel de done.
- Usar `select` com `ctx.Done()` em loops de goroutines persistentes.
- Parar de consumir novas mensagens ao receber sinal; processar mensagens em andamento até o timeout.
- Commitar offset/ack apenas de mensagens processadas com sucesso antes do shutdown.

### Shutdown de Dependências
- Fechar dependências na ordem inversa de inicialização: server → messaging → cache → database → telemetry → logger.
- Usar `defer` encadeado ou lista explícita de closers para garantir ordem.
- Flush de telemetry (traces, metrics) antes de fechar o exporter — dados não-flushed são perdidos.

```go
// Padrão com lista de closers
type closer struct {
    name string
    fn   func(context.Context) error
}

closers := []closer{
    {"server", server.Shutdown},
    {"consumer", consumer.Close},
    {"database", db.Close},
    {"telemetry", tp.Shutdown},
}

for _, c := range closers {
    if err := c.fn(shutdownCtx); err != nil {
        slog.Error("shutdown failed", "component", c.name, "error", err)
    }
}
```

### CLIs e Processos Curtos
- CLIs que executam operações de IO (HTTP calls, queries) devem respeitar cancelamento via context.
- Propagar context do sinal para operações internas — não ignorar Ctrl+C.
- Fechar recursos (conexões, arquivos) com `defer` mesmo em processos curtos.

## Riscos Comuns
- Shutdown abrupto cortando requests em andamento e causando erro 502 no load balancer.
- Timeout de shutdown maior que `terminationGracePeriodSeconds` — orquestrador mata o processo antes do drain.
- Goroutine leak por falta de cancelamento — processo encerra mas goroutines continuam executando até OOM.
- Telemetry perdida por falta de flush antes do shutdown.
- Consumer que commita offset de mensagem não-processada durante shutdown.
- `os.Exit(1)` em handler de erro bypassing defers e closers.

## Proibido
- Processo sem handler de sinal — shutdown deve ser sempre coordenado.
- Goroutine de longa duração sem mecanismo de cancelamento.
- `os.Exit` fora de `main` ou em goroutine secundária.
- Ignorar erro de shutdown — logar mesmo que não seja recuperável.
- Iniciar a servir tráfego antes de todas as dependências estarem prontas.
