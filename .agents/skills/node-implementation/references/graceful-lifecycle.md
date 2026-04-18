# Graceful Lifecycle Node.js

## Objetivo
Garantir que o processo encerre de forma ordenada: drena conexões, fecha dependências e sai com código correto.

## Diretrizes

### Signal Handling
- Capturar SIGTERM/SIGINT uma vez com `process.once()`. Drenar antes de `process.exit()`.

### Bootstrap com shutdown coordenado

```typescript
async function main(): Promise<void> {
  await connectDb()
  const app = buildApp()
  const shutdownServer = startServer(app, 3000)

  const shutdown = async (signal: string): Promise<void> => {
    const timer = setTimeout(() => process.exit(1), 15_000)
    timer.unref()
    try {
      await shutdownServer()
      await closeDb()
      clearTimeout(timer)
      process.exit(0)
    } catch (err) {
      console.error('shutdown error', err)
      process.exit(1)
    }
  }

  process.once('SIGTERM', () => shutdown('SIGTERM'))
  process.once('SIGINT',  () => shutdown('SIGINT'))
}
```

### Workers e Streams
- `worker.terminate()` + aguardar `exit`. `stream.destroy()` antes de encerrar.
- Limpar timers/intervalos no shutdown.

### Keep-alive
- Configurar `server.keepAliveTimeout` e `server.headersTimeout` explicitamente.
- `Connection: close` nas respostas in-flight ao receber shutdown.

## Riscos Comuns
- `server.close()` nao fecha keep-alive abertas. Shutdown sem timeout = hang.
- `process.exit()` antes de flush de logs async.

## Proibido
- `process.exit()` sem drenar. Handlers de sinal duplicados.
- Ignorar erros de `server.close()` ou `db.end()`.
