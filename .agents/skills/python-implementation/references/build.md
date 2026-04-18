# Build e Packaging Python

## Objetivo
Orientar criacao de Dockerfiles, pipelines de build e empacotamento de projetos Python.

## Dockerfile Multi-Stage
- Usar multi-stage para separar build de runtime e reduzir tamanho da imagem.
- Padrao recomendado:
  ```dockerfile
  # --- Build ---
  FROM python:3.12-slim AS builder
  WORKDIR /app
  RUN pip install --no-cache-dir uv
  COPY pyproject.toml uv.lock* ./
  RUN uv pip install --system --no-cache -r pyproject.toml
  COPY . .

  # --- Runtime ---
  FROM python:3.12-slim
  WORKDIR /app
  RUN groupadd -r app && useradd -r -g app app
  COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
  COPY --from=builder /usr/local/bin /usr/local/bin
  COPY --from=builder /app .
  USER app
  EXPOSE 8000
  CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
  ```
- Alternativa com pip: `pip install --no-cache-dir -r requirements.txt`.
- Usar imagem `slim` ou `alpine` — evitar imagem full.
- Nao instalar compiladores ou dev headers no runtime stage.

## .dockerignore
- Incluir: `.git`, `__pycache__`, `.venv`, `*.pyc`, `.env*`, `dist/`, `*.egg-info`, `coverage/`, `.mypy_cache/`.

## Gerenciamento de Dependencias
- Preferir `pyproject.toml` como manifesto unico (PEP 621).
- Lockfile: `uv.lock`, `poetry.lock` ou `pip-compile` output para builds reprodutiveis.
- Separar dependencias de producao e desenvolvimento.
- Nao usar `pip install` sem versao fixa em CI/producao.

## Package Managers
- `uv`: mais rapido, compativel com pip, recomendado para projetos novos.
- `poetry`: maduro, gerencia virtualenv e lockfile.
- `pip` + `pip-tools`: minimalista, sem overhead de ferramenta.
- Respeitar a escolha do projeto — nao trocar sem motivo.

## Estrutura de Build
- `src/` layout quando o pacote for distribuido:
  ```
  src/
    mypackage/
      __init__.py
      ...
  tests/
  pyproject.toml
  ```
- Flat layout para servicos/APIs que nao serao distribuidos como pacote.
- Nao commitar `dist/`, `*.egg-info`, ou `__pycache__`.

## CI Pipeline
- Ordem recomendada: install -> lint -> typecheck -> test -> build.
- Cachear `.venv` ou cache do pip entre runs.
- `ruff check .` e `ruff format --check .` como gates rapidos.
- `mypy .` ou `pyright .` para typecheck quando o projeto adotar.
- `pytest --tb=short -q` para output limpo em CI.

## Proibido
- `pip install` sem lockfile em producao (versoes nao-deterministicas).
- Container rodando como root em producao.
- Commitar `__pycache__`, `.pyc`, `dist/` ou `*.egg-info`.
- Misturar package managers no mesmo projeto (ex: poetry + pip no mesmo pyproject).
