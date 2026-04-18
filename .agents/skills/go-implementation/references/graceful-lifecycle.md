# Graceful Lifecycle

## Objetivo
Unificar padrões de inicialização ordenada e encerramento gracioso para servidores, workers, consumers e CLIs.

## Diretrizes

### Inicializacao
- Ordem explicita: config -> logger -> telemetry -> database -> cache -> messaging -> server.
- Fail fast se dependencia obrigatoria indisponivel. Readiness probe antes de servir trafego.

### Sinais e Cancelamento
- `signal.NotifyContext` para SIGTERM/SIGINT. Propagar context para goroutines.

```go
ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
defer stop()
```

### Shutdown de Servidor
- `server.Shutdown(ctx)` com timeout < `terminationGracePeriodSeconds`.

```go
shutdownCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
defer cancel()
if err := server.Shutdown(shutdownCtx); err != nil {
    slog.Error("server shutdown failed", "error", err)
}
```

### Workers/Consumers
- Goroutines devem respeitar `ctx.Done()`. Parar de consumir ao receber sinal; processar in-flight ate timeout.

### Shutdown de Dependencias
- Fechar na ordem inversa. Flush telemetry antes de fechar exporter.

```go
closers := []struct{ name string; fn func(context.Context) error }{
    {"server", server.Shutdown}, {"consumer", consumer.Close},
    {"database", db.Close}, {"telemetry", tp.Shutdown},
}
for _, c := range closers {
    if err := c.fn(shutdownCtx); err != nil {
        slog.Error("shutdown failed", "component", c.name, "error", err)
    }
}
```

## Riscos Comuns
- Shutdown abrupto = 502. Timeout > terminationGracePeriodSeconds.
- Goroutine leak sem cancelamento. Telemetry perdida sem flush.
- Consumer commitando offset nao-processado. `os.Exit` bypassing defers.

## Proibido
- Processo sem signal handler. Goroutine sem cancelamento. `os.Exit` fora de main.
- Ignorar erro de shutdown. Servir trafego antes de ready.
