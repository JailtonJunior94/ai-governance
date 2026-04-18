# Principios de Lifecycle (Cross-Linguagem)

## Inicializacao
- Ordem explicita: config -> logger -> telemetry -> database -> cache -> messaging -> server.
- Fail fast se dependencia obrigatoria indisponivel na inicializacao.
- Logar versao e config nao-sensivel no startup. Readiness probe antes de servir trafego.

## Shutdown
- Capturar SIGTERM e SIGINT. Propagar cancelamento para todas as operacoes de longa duracao.
- Timeout de shutdown < `terminationGracePeriodSeconds` do orquestrador (k8s default: 30s).
- Parar de aceitar novas conexoes/mensagens; drenar in-flight ate o timeout.
- Fechar dependencias na ordem inversa de inicializacao.
- Flush de telemetry (traces, metrics) antes de fechar exporter.
- Commitar offset/ack apenas de mensagens processadas com sucesso.

## Riscos Universais
- Shutdown abrupto = 502 no load balancer.
- Timeout > terminationGracePeriodSeconds = kill forcado.
- Leak de goroutines/tasks/threads sem cancelamento.
- Telemetry perdida por falta de flush.
- Consumer commitando offset de mensagem nao-processada.

## Proibido
- Processo sem handler de sinal.
- Operacao de longa duracao sem mecanismo de cancelamento.
- Exit abrupto (os.Exit/sys.exit/process.exit) fora do ponto de entrada principal.
- Ignorar erro de shutdown. Servir trafego antes de ready.
