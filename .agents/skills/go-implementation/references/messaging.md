# Messaging e Eventos

## Objetivo
Manter comunicação assíncrona confiável, rastreável e desacoplada do domínio.

## Diretrizes

### Produção de Mensagens
- Publicar eventos após a transação de domínio ser confirmada — não dentro da transação (salvo outbox pattern).
- Usar outbox pattern quando a garantia de at-least-once delivery com consistência transacional for necessária.
- Serializar mensagens com schema explícito (JSON com contrato documentado, protobuf ou Avro).
- Incluir metadata: event type, timestamp, correlation ID, source.

### Consumo de Mensagens
- Consumidores devem ser idempotentes — processar a mesma mensagem mais de uma vez sem efeito colateral.
- Usar deduplicação por ID quando idempotência natural não for possível.
- Processar mensagens dentro de timeout explícito — não segurar offset/ack indefinidamente.
- Commitar offset/ack somente após processamento bem-sucedido.

### Dead-Letter e Retry
- Encaminhar mensagens que falharam após N tentativas para dead-letter queue (DLQ).
- Logar contexto suficiente na DLQ para diagnóstico sem precisar do payload original.
- Definir política de retry com backoff antes de mover para DLQ.
- Monitorar tamanho da DLQ com alerta.

### Ordering
- Não depender de ordenação global — usar partition key quando ordem importar dentro de um aggregate.
- Documentar garantias de ordenação assumidas pelo consumidor.

### Schema Evolution
- Definir formato de serialização com schema explícito desde o primeiro evento: protobuf, Avro ou JSON Schema.
- Usar schema registry (Confluent Schema Registry, Buf Schema Registry ou equivalente) quando houver múltiplos producers ou consumers com deploy independente.
- Aplicar apenas mudanças backward-compatible por padrão: adicionar campos opcionais, não remover ou renomear campos existentes.
- Para breaking changes, criar novo tópico ou novo event type versionado (`OrderCreatedV2`) — não alterar o schema existente.
- Consumidores devem ignorar campos desconhecidos (forward compatibility) para tolerar evolução do producer.
- Versionar schemas com número sequencial ou hash — manter histórico auditável.
- Validar compatibilidade de schema em CI antes de merge (ex: `buf breaking`, compatibilidade do schema registry).
- Documentar o contrato de cada evento: campos obrigatórios, opcionais, tipos, valores válidos e regras de deprecação.

### Observabilidade
- Propagar trace context nas mensagens para manter tracing distribuído entre producer e consumer.
- Expor métricas de consumer lag, taxa de processamento e taxa de erro por tópico.

## Riscos Comuns
- Publicar evento antes do commit — mensagem fantasma se a transação falhar.
- Consumidor não-idempotente com at-least-once delivery causando duplicação de efeito.
- Consumer lag crescendo silenciosamente sem alerta.
- Mensagem sem schema versionado quebrando consumidores em deploy independente.
- Breaking change em schema sem versionamento causando falha silenciosa em consumers.

## Proibido
- Publicar evento dentro de transação de banco sem outbox pattern.
- Consumidor que ignora falha e commita offset.
- Mensagem sem correlation ID ou trace context.
