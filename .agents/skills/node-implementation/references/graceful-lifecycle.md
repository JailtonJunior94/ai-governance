# Graceful Lifecycle Node.js

## Objetivo
Garantir que o processo encerre de forma ordenada: drena conexões, fecha dependências e sai com código correto.

## Diretrizes

### Signal Handling
- Capturar `SIGTERM` (encerramento por orquestrador) e `SIGINT` (Ctrl-C local).
- Registrar handlers uma vez — não re-registrar em loops ou hot paths.
- Evitar `process.exit()` imediato dentro de handlers de sinal — drenar primeiro.

### Drain de Servidor HTTP

```typescript
// src/server.ts
import { createServer } from 'node:http'
import type { Application } from 'express'

export function startServer(app: Application, port: number): () => Promise<void> {
  const server = createServer(app)

  server.listen(port, () => {
    console.log(`server listening on :${port}`)
  })

  const shutdown = (): Promise<void> =>
    new Promise((resolve, reject) => {
      server.close((err) => {
        if (err) reject(err)
        else resolve()
      })
    })

  return shutdown
}
```

### Bootstrap com shutdown coordenado

```typescript
// src/main.ts
import process from 'node:process'
import { startServer } from './server.js'
import { buildApp } from './app.js'
import { connectDb, closeDb } from './infra/db.js'

async function main(): Promise<void> {
  await connectDb()
  const app = buildApp()
  const shutdownServer = startServer(app, 3000)

  const shutdown = async (signal: string): Promise<void> => {
    console.log(`received ${signal}, shutting down`)
    try {
      await shutdownServer()        // drain de conexões HTTP
      await closeDb()               // fechar pool de banco
      console.log('shutdown complete')
      process.exit(0)
    } catch (err) {
      console.error('shutdown error', err)
      process.exit(1)
    }
  }

  process.once('SIGTERM', () => shutdown('SIGTERM'))
  process.once('SIGINT',  () => shutdown('SIGINT'))
}

main().catch((err) => {
  console.error('startup error', err)
  process.exit(1)
})
```

### Workers e Streams
- Worker threads: usar `worker.terminate()` e aguardar evento `exit` antes de encerrar o processo principal.
- Streams: chamar `stream.destroy()` ou aguardar `finish`/`end` antes de encerrar.
- Timers e intervalos: limpar com `clearTimeout`/`clearInterval` no shutdown para não bloquear o event loop.

### Keep-alive e conexões longas
- Configurar `server.keepAliveTimeout` e `server.headersTimeout` explicitamente — defaults do Node.js podem causar comportamento inesperado atrás de load balancers.
- Ao receber sinal de shutdown, definir `Connection: close` nas respostas in-flight para que clientes reconectem.

## Riscos Comuns
- `server.close()` não fecha conexões keep-alive abertas — process fica pendurado.
- Shutdown sem timeout causa hang indefinido se dependência não responder.
- `process.exit()` chamado antes de flush de logs assíncronos.

## Padrão recomendado com timeout de segurança

```typescript
const SHUTDOWN_TIMEOUT_MS = 15_000

process.once('SIGTERM', async () => {
  const timer = setTimeout(() => {
    console.error('shutdown timeout — forcing exit')
    process.exit(1)
  }, SHUTDOWN_TIMEOUT_MS)
  timer.unref() // não impede o event loop de encerrar normalmente

  try {
    await shutdownServer()
    await closeDb()
    clearTimeout(timer)
    process.exit(0)
  } catch (err) {
    console.error('shutdown error', err)
    process.exit(1)
  }
})
```

## Proibido
- `process.exit()` sem drenar servidor e dependências.
- Registrar handlers de sinal múltiplas vezes sem remover os anteriores.
- Ignorar erros de `server.close()` ou `db.end()`.
