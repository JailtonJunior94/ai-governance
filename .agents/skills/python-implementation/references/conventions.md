# Convencoes Python

## Objetivo
Preservar consistencia, fronteiras e legibilidade em projetos Python.

## Diretrizes
- Seguir PEP 8 como baseline; respeitar desvios locais documentados.
- Preferir funcoes puras e composicao sobre heranca profunda.
- Usar type hints em funcoes publicas e retornos.
- Nomear modulos e pacotes em snake_case.
- Manter imports organizados: stdlib, dependencias externas, imports internos (isort/ruff cuida disso).

## Estrutura
- Seguir o layout ja adotado pelo projeto.
- Em projetos novos, usar `src/` layout quando houver distribuicao de pacote.
- Separar `tests/` do codigo de producao.
- `__init__.py` apenas quando necessario para o import; evitar barrel exports pesados.

## Tipagem
- Preferir `typing` moderno (Python 3.10+: `X | Y` em vez de `Union[X, Y]`).
- Usar `Protocol` para duck typing tipado em fronteiras.
- Evitar `Any`; usar `object` ou `Unknown` quando o tipo nao puder ser inferido.

## Proibido
- Assumir versao de Python sem verificar `pyproject.toml`, `.python-version` ou `Pipfile`.
- Instalar dependencias sem verificar se ja existem alternativas no projeto.
- Usar `exec()` ou `eval()` sem justificativa de seguranca.
