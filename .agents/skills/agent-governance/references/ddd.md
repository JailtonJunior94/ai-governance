# Modelagem de Domínio

- Rule ID: R-DDD-001
- Severidade: hard
- Escopo: camadas de domínio e aplicação.

## Objetivo
Garantir um domínio explícito com invariantes protegidas, evitando structs anêmicas e regras espalhadas.

## Requisitos

### Entidades
- Entidades devem proteger invariantes no construtor e nos métodos.
- Entidades devem expor comportamento de domínio, não apenas dados.
- Campos sensíveis do domínio devem permanecer não exportados.

### Value Objects
- Modelar como VO conceitos com regra própria e identidade por valor.
- VOs devem se autovalidar.
- VOs devem ser imutáveis por design.

### Aggregate Roots
- Alterações em entidades filhas devem ocorrer por métodos do aggregate root quando influenciarem o estado global.
- Transições de estado devem ser centralizadas no aggregate root ou em um state object explícito.

### Application Layer
- Use cases devem orquestrar leitura, resolução de input, chamada de serviços e persistência.
- Parsing de formatos externos não pertence ao domínio.
- Application não deve conter regra de transição de estado que pertence ao domínio.

### Domain Services
- Usar domain services para regras que combinam múltiplas entidades ou VOs.
- Domain services devem ser stateless.

### Fail Fast
- Input inválido deve falhar na validação antes de iniciar execução.
- Referência a recurso inexistente ou configuração inválida deve ser rejeitada cedo.

### State Pattern
- Estados devem ter transições permitidas de forma explícita.
- Não usar strings soltas espalhadas pelo código para comparar estado.

## Proibido
- Struct literal de entidade fora de testes e factories.
- Regras de transição espalhadas em handlers, comandos ou adapters.
- Domínio conhecendo detalhes de infraestrutura, serialização ou IO.
