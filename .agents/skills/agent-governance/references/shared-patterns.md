# Patterns Compartilhados (Cross-Linguagem)

Patterns recorrentes aplicaveis a Go, Node/TypeScript e Python. Cada stack adapta a sintaxe mas preserva a intencao.

## Repository

- Interface/port define operacoes de dominio (FindByID, Save, Delete), nao SQL.
- Implementacao concreta vive em camada de infraestrutura.
- Repositorio recebe conexao/client via construtor, nao via global.
- Nomear pelo agregado: `OrderRepository`, nao `DatabaseHelper`.
- Retornar erros tipados de dominio, nao erros de driver.

## Factory Function

- Construtor explicito que recebe dependencias como parametros e retorna instancia configurada.
- Validar invariantes no construtor; nao permitir instancia em estado invalido.
- Retornar erro quando pre-condicoes nao forem satisfeitas (Go: `New(...) (*T, error)`; Node/Python: throw/raise).
- Preferir factory function a builder quando o objeto tiver <= 5 parametros.

## Dependency Injection

- DI manual via construtores como padrao em todas as stacks.
- Container de DI (Wire, tsyringe, dependency-injector) apenas quando arvore de dependencias justificar (> 10 raizes).
- Construtor recebe interfaces/ports, nao implementacoes concretas, quando polimorfismo for necessario.
- Service locator e antipattern — evitar em todas as stacks.

## Error Handling Cross-Stack

- Erros de dominio tipados: criar tipos/classes de erro especificos (Go: sentinel + wrap; Node: classes Error; Python: exception classes).
- Nao capturar erro generico para silenciar — propagar ou tratar com intencao.
- Boundary de erro: converter erros de infraestrutura em erros de dominio na camada de adapter.
- Log no ponto de decisao, nao em cada camada.

## Value Objects

- Encapsular primitivos que carregam invariante de dominio (Email, OrderID, Money).
- Nao encapsular primitivos sem regra de validacao (string simples, contadores sem limite).
- Imutaveis: Go (struct sem setter), Node (readonly/Object.freeze), Python (frozen dataclass).
- Igualdade por valor, nao por referencia.
