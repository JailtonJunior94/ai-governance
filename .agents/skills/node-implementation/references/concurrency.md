# Concorrencia Node/TypeScript

## Objetivo
Orientar uso correto de assincronia, paralelismo e controle de fluxo em Node.js.

## Event Loop
- Node e single-threaded para JS; operacoes de IO sao nao-bloqueantes via libuv.
- Nunca bloquear o event loop com computacao sincrona pesada (loops CPU-bound, `JSON.parse` em payloads gigantes, crypto sincrono).
- Usar `setImmediate` ou `process.nextTick` com criterio; preferir `setImmediate` para ceder controle ao event loop.

## Promises e async/await
- Preferir `async/await` sobre `.then()` chains para legibilidade.
- Sempre tratar rejeicoes: `try/catch` em funcoes async ou `.catch()` em promises nao-awaited.
- Evitar `Promise` constructor quando `async function` resolve o caso.
- Usar `Promise.all()` para operacoes independentes em paralelo.
- Usar `Promise.allSettled()` quando falha parcial for aceitavel.
- Nao usar `Promise.all()` para volume ilimitado; usar controle de concorrencia (ver abaixo).

## Controle de Concorrencia
- Para operacoes em lote (ex: processar 1000 itens com chamada HTTP cada), limitar concorrencia com libs como `p-limit`, `p-map` ou `async.mapLimit`.
- Padrao simples sem dependencia externa:
  ```typescript
  async function mapWithLimit<T, R>(items: T[], limit: number, fn: (item: T) => Promise<R>): Promise<R[]> {
    const results: R[] = [];
    const executing: Promise<void>[] = [];
    for (const item of items) {
      const p = fn(item).then(r => { results.push(r); });
      executing.push(p);
      if (executing.length >= limit) {
        await Promise.race(executing);
        executing.splice(executing.findIndex(e => e === p), 1);
      }
    }
    await Promise.all(executing);
    return results;
  }
  ```
- Default seguro: 5-10 operacoes concorrentes para chamadas externas.

## Worker Threads
- Usar `worker_threads` apenas para computacao CPU-bound genuina (compressao, hashing pesado, processamento de imagem).
- Nao usar worker threads para IO — o event loop ja e nao-bloqueante para isso.
- Comunicacao entre main thread e worker via `postMessage` (serializado); evitar objetos grandes.
- Preferir `SharedArrayBuffer` quando throughput de dados for critico e o overhead de copia for medido.

## Streams
- Preferir streams para processar dados grandes (arquivos, HTTP bodies, CSVs) em vez de carregar tudo em memoria.
- Usar `pipeline()` de `stream/promises` em vez de `.pipe()` manual — gerencia backpressure e cleanup.
- Em Transform streams, sempre chamar `callback()` — nao chamar causa deadlock silencioso.

## Sinais de Excesso
- Worker thread para uma operacao que leva menos de 50ms.
- `Promise.all` sem limite em array de tamanho dinamico.
- Microtask starvation: loop infinito de `process.nextTick` impedindo IO callbacks.
- Stream pipeline sem tratamento de erro.
