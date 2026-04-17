# Concorrência

## Objetivo
Usar concorrência apenas quando ela resolver um problema real de latência, throughput ou isolamento.

## Diretrizes

### Princípios
- Preferir execução sequencial por padrão — concorrência é otimização, não estilo.
- Usar `context.Context` para cancelamento e timeout em toda goroutine.
- Fechar channels no produtor quando isso fizer parte do contrato.
- Proteger estado compartilhado explicitamente com `sync.Mutex`, `sync.RWMutex` ou channels.
- Garantir que testes sejam determinísticos e não dependam de `sleep`.

### errgroup (padrão preferido para fan-out)
- Usar `golang.org/x/sync/errgroup` para lançar goroutines com propagação de erro e cancelamento automático.
- Limitar paralelismo com `g.SetLimit(n)` quando o fan-out puder sobrecarregar a dependência.
- Sempre verificar o erro retornado por `g.Wait()`.
```go
g, ctx := errgroup.WithContext(ctx)
g.SetLimit(10)
for _, item := range items {
    g.Go(func() error {
        return process(ctx, item)
    })
}
if err := g.Wait(); err != nil {
    return fmt.Errorf("processing items: %w", err)
}
```

### Worker Pool
- Usar worker pool quando o volume de trabalho for grande e o paralelismo precisar de controle fino.
- Padrão: N goroutines consumindo de um channel de trabalho, resultado coletado em channel de saída ou errgroup.
- Fechar o channel de entrada após enviar todo o trabalho.
- Drenar workers antes de retornar — não deixar goroutines órfãs.

### sync primitives
- `sync.Once` para inicialização lazy thread-safe (conexão, cache, singleton).
- `sync.Pool` para reutilização de objetos alocados frequentemente em hot paths (buffers, encoders).
- `sync.WaitGroup` quando não há erro a propagar — preferir errgroup quando houver.
- `sync.Map` apenas quando o padrão de acesso for append-only ou read-heavy com chaves disjuntas — na dúvida, usar `sync.RWMutex` com map regular.

### Channels
- Preferir channels unbuffered para sincronização e buffered para desacoplamento de velocidade.
- Não usar channel quando mutex resolve o problema de forma mais simples.
- Definir claramente quem é produtor e quem é consumidor — owner do channel é quem fecha.

### Graceful Shutdown de Goroutines
- Toda goroutine de longa duração deve respeitar cancelamento via `context.Context` ou channel de done.
- Usar `select` com `ctx.Done()` em loops de goroutines persistentes.
- Drenar goroutines com `sync.WaitGroup` ou errgroup antes de encerrar o processo.

## Riscos Comuns
- Goroutine sem encerramento claro (goroutine leak).
- Deadlock por contrato implícito de channels.
- Data race por estado compartilhado sem sincronização — rodar `go test -race` regularmente.
- Fan-out sem limite explodindo conexões de banco ou rede.
- `sync.Pool` usado para objetos com estado que não é resetado antes de reutilizar.

## Proibido
- Goroutine lançada sem mecanismo de encerramento.
- `go func()` com captura de variável de loop sem rebind (Go < 1.22).
- Mutex com lock/unlock sem `defer` quando o fluxo tiver retornos intermediários.
- Ignorar `ctx.Done()` em loops de longa duração.
