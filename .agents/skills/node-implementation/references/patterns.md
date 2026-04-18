# Padroes Node/TypeScript

## Objetivo
Orientar a escolha de padroes recorrentes, evitando abstracao prematura e complexidade desnecessaria.

## Diretrizes

### Dependency Injection
- Preferir injecao via construtor sobre containers automaticos, salvo quando o projeto ja adotar um container (tsyringe, inversify, NestJS IoC).
- Depender de interfaces/types, nao de implementacoes concretas, em fronteiras de IO.
- Nao introduzir container DI apenas para injetar uma dependencia.

### Repository Pattern
- Usar repositories para encapsular acesso a dados e queries.
- Interface do repository deve expor operacoes de dominio, nao primitivas SQL.
- Nao retornar entidades ORM diretamente — mapear para entidades de dominio.

### Factory Functions
- Preferir factory functions sobre classes quando nao houver estado mutavel.
- Usar factory quando a construcao envolver validacao ou defaults complexos.

### Strategy
- Usar strategy para variar comportamento sem branching extenso.
- Registrar strategies em mapa ou switch explicito — nao em cadeia de `if/else`.

### Module Organization
- Agrupar por dominio ou funcionalidade, nao por tipo tecnico (ex: evitar pasta `controllers/` global).
- Cada modulo exporta sua interface publica via `index.ts` apenas quando o projeto adotar barrel exports.
- Dependencias entre modulos devem ser unidirecionais — nao criar ciclos de import.

### Composicao vs Heranca
- Preferir composicao e funcoes de ordem superior sobre heranca profunda.
- Heranca e aceitavel para error classes e integracao com frameworks que a exigem.

## Proibido
- Singleton mutavel sem justificativa clara (estado global oculto).
- Abstracao prematura — tres usos reais antes de extrair um pattern.
- Import circular entre modulos.
