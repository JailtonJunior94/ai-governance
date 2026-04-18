# Padroes Python

## Objetivo
Orientar a escolha de padroes recorrentes, evitando abstracao prematura e complexidade desnecessaria.

## Diretrizes

### Dependency Injection
- Preferir injecao via construtor ou parametros de funcao.
- Em FastAPI, usar `Depends()` como mecanismo de injecao nativo.
- Em Django, usar injecao explicita no service layer.
- Depender de Protocol ou ABC em fronteiras de IO, nao de implementacoes concretas.

### Repository Pattern
- Usar repositories para encapsular acesso a dados e queries.
- Interface do repository deve expor operacoes de dominio, nao primitivas SQL.
- Nao retornar instancias ORM diretamente — mapear para entidades de dominio quando houver separacao de camadas.

### Dataclasses e Attrs
- Preferir `dataclass` ou `attrs` para value objects e DTOs.
- Usar `frozen=True` para imutabilidade quando o objeto nao precisar de mutacao.
- Usar `__post_init__` ou validators para invariantes de construcao.

### Strategy
- Usar strategy para variar comportamento sem branching extenso.
- Registrar strategies em dicionario ou mapa explicito.

### Module Organization
- Agrupar por dominio ou funcionalidade, nao por tipo tecnico.
- Dependencias entre modulos devem ser unidirecionais.
- Usar `__init__.py` para definir interface publica do modulo.

### Composicao vs Heranca
- Preferir composicao e funcoes sobre heranca profunda.
- Heranca e aceitavel para exception classes e integracao com frameworks.
- Usar mixins com moderacao — preferir composicao explicita.

## Proibido
- Singleton mutavel sem justificativa (estado global oculto).
- Import circular entre modulos.
- Abstracao prematura — tres usos reais antes de extrair um pattern.
