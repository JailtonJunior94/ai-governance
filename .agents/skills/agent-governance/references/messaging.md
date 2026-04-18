# Messaging e Eventos

## Objetivo
Manter comunicacao assincrona confiavel, rastreavel e desacoplada do dominio.

## Diretrizes

### Producao de Mensagens
- Publicar eventos apos a transacao de dominio ser confirmada — nao dentro da transacao (salvo outbox pattern).
- Usar outbox pattern quando a garantia de at-least-once delivery com consistencia transacional for necessaria.
- Serializar mensagens com schema explicito (JSON com contrato documentado, protobuf ou Avro).
- Incluir metadata: event type, timestamp, correlation ID, source.

### Consumo de Mensagens
- Consumidores devem ser idempotentes — processar a mesma mensagem mais de uma vez sem efeito colateral.
- Usar deduplicacao por ID quando idempotencia natural nao for possivel.
- Processar mensagens dentro de timeout explicito — nao segurar offset/ack indefinidamente.
- Commitar offset/ack somente apos processamento bem-sucedido.

### Dead-Letter e Retry
- Encaminhar mensagens que falharam apos N tentativas para dead-letter queue (DLQ).
- Definir politica de retry com backoff antes de mover para DLQ.
- Monitorar tamanho da DLQ com alerta.

### Schema Evolution
- Aplicar apenas mudancas backward-compatible por padrao: adicionar campos opcionais, nao remover ou renomear.
- Para breaking changes, criar novo topico ou novo event type versionado.
- Consumidores devem ignorar campos desconhecidos (forward compatibility).

### Observabilidade
- Propagar trace context nas mensagens para manter tracing distribuido.
- Expor metricas de consumer lag, taxa de processamento e taxa de erro por topico.

## Riscos Comuns
- Publicar evento antes do commit — mensagem fantasma se a transacao falhar.
- Consumidor nao-idempotente com at-least-once delivery causando duplicacao.
- Consumer lag crescendo silenciosamente sem alerta.

## Proibido
- Publicar evento dentro de transacao de banco sem outbox pattern.
- Consumidor que ignora falha e commita offset.
- Mensagem sem correlation ID ou trace context.
