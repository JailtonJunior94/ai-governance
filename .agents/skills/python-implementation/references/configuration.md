# Configuracao

## Objetivo
Carregar configuracao de forma explicita, validada e sem acoplamento global.

## Diretrizes
- Preferir variaveis de ambiente como fonte primaria para deploys em containers.
- Carregar configuracao uma vez na inicializacao e injetar como dependencia explicita.
- Validar valores obrigatorios e ranges na inicializacao — falhar cedo com mensagem clara.
- Usar modelos tipados (pydantic `BaseSettings`, dataclass, attrs) para configuracao, nao dicionarios ou lookups por string.
- Usar `.env` com `python-dotenv` apenas para desenvolvimento local — nao em producao.
- Separar config de infra (porta, DSN, timeouts) de config de negocio (feature flags, limites).
- Usar defaults explicitos e documentados para valores opcionais.

## Padrao de Uso
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    port: int = 8000
    database_url: str
    log_level: str = "info"

    model_config = {"env_prefix": "", "env_file": ".env", "env_file_encoding": "utf-8"}

settings = Settings()
```

## Riscos Comuns
- Config lida em multiplos pontos com logica de fallback duplicada.
- Segredo carregado de env sem validacao e usado como string vazia silenciosamente.
- Modulo de negocio importando `os.environ` diretamente.

## Proibido
- Hardcode de segredos, DSNs ou endpoints em codigo.
- Config mutavel apos inicializacao sem sincronizacao.
- `os.environ.get()` espalhado em modulos de negocio.
