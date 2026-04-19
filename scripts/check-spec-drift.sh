#!/usr/bin/env bash
# Detecta drift entre artefatos de spec (prd.md, techspec.md) e tasks.md.
#
# Estrategia de deteccao (em ordem de precisao):
#   1. Semantica: extrai RF-nn/REQ-nn do PRD e verifica cobertura em tasks.md.
#      Reporta quais IDs estao ausentes — drift real de conteudo.
#   2. Hash: compara SHA-256 dos blocos de requisitos em prd.md e techspec.md
#      contra um hash registrado em tasks.md (frontmatter <!-- spec-hash: ... -->).
#   3. Fallback: se nenhuma das estrategias anteriores se aplicar, retorna OK.
#
# Retorna 0 quando nao ha drift, 1 quando drift e detectado.
#
# Uso:
#   bash scripts/check-spec-drift.sh <tasks-file>
#
# Exemplo:
#   bash scripts/check-spec-drift.sh tasks/prd-minha-feature/tasks.md
#
# Integrado em CI via test-spec-drift.sh e pode ser invocado por pre-commit hooks.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <tasks.md>" >&2
  exit 2
fi

tasks_file="$1"

if [[ ! -f "$tasks_file" ]]; then
  echo "ERRO: arquivo de tasks nao encontrado: $tasks_file" >&2
  exit 2
fi

tasks_dir="$(dirname "$tasks_file")"
prd_file="$tasks_dir/prd.md"
techspec_file="$tasks_dir/techspec.md"

drift=0

# ---------------------------------------------------------------------------
# Estrategia 1: cobertura semantica de RF IDs
# Extrai todos os IDs RF-nn / REQ-nn do arquivo de spec e verifica se cada
# um aparece em tasks.md. IDs ausentes indicam requisitos nao decompostos.
# ---------------------------------------------------------------------------
check_rf_coverage() {
  local spec_file="$1"
  local spec_label="$2"

  [[ -f "$spec_file" ]] || return 0

  # Extrair IDs (case-insensitive, deduplicar)
  local ids
  ids="$(grep -Eohi '(RF-?[0-9]+|REQ-?[0-9]+)' "$spec_file" 2>/dev/null | tr '[:lower:]' '[:upper:]' | sort -u || true)"

  [[ -n "$ids" ]] || return 0

  local missing_count=0
  while IFS= read -r req_id; do
    [[ -n "$req_id" ]] || continue
    if ! grep -Fiq "$req_id" "$tasks_file" 2>/dev/null; then
      echo "DRIFT: requisito $req_id presente em $spec_label mas ausente em tasks.md" >&2
      missing_count=$((missing_count + 1))
      drift=1
    fi
  done <<< "$ids"

  if [[ "$missing_count" -gt 0 ]]; then
    echo "  Recomendacao: revisar tasks.md para cobrir os $missing_count requisito(s) ausente(s) de $spec_label." >&2
  fi
}

# ---------------------------------------------------------------------------
# Estrategia 2: hash de conteudo de spec
# Se tasks.md contiver um comentario HTML <!-- spec-hash: <sha256> -->, compara
# contra o hash atual dos arquivos de spec para detectar mudancas estruturais
# que nao alteraram IDs mas mudaram o conteudo.
# ---------------------------------------------------------------------------
check_spec_hash() {
  local spec_file="$1"
  local spec_label="$2"

  [[ -f "$spec_file" ]] || return 0

  # Ler hash registrado no tasks.md (formato: <!-- spec-hash-prd: abc123 -->)
  local hash_key
  hash_key="spec-hash-$(basename "$spec_file" .md)"
  local recorded_hash
  recorded_hash="$(grep -Eo "<!-- ${hash_key}: [a-f0-9]+ -->" "$tasks_file" 2>/dev/null | grep -Eo '[a-f0-9]{8,}' | head -1 || true)"

  [[ -n "$recorded_hash" ]] || return 0

  # Calcular hash atual do spec
  local current_hash
  if command -v sha256sum >/dev/null 2>&1; then
    current_hash="$(sha256sum "$spec_file" | cut -d' ' -f1)"
  elif command -v shasum >/dev/null 2>&1; then
    current_hash="$(shasum -a 256 "$spec_file" | cut -d' ' -f1)"
  else
    return 0  # sha nao disponivel, pular
  fi

  # Comparar prefixo de 8 chars (suficiente para detectar mudancas)
  local recorded_prefix="${recorded_hash:0:8}"
  local current_prefix="${current_hash:0:8}"

  if [[ "$recorded_prefix" != "$current_prefix" ]]; then
    echo "DRIFT: hash de $spec_label mudou (registrado: ${recorded_prefix}, atual: ${current_prefix})" >&2
    echo "  Recomendacao: atualizar tasks.md com <!-- ${hash_key}: ${current_hash:0:8} --> ou regenerar tasks." >&2
    drift=1
  fi
}

# ---------------------------------------------------------------------------
# Estrategia 3: spec-version incremental
# Se o PRD contiver <!-- spec-version: N --> e tasks.md contiver
# <!-- prd-version: M -->, compara N > M para detectar evolucao nao refletida.
# ---------------------------------------------------------------------------
check_spec_version() {
  local spec_file="$1"

  [[ -f "$spec_file" ]] || return 0

  local spec_ver
  spec_ver="$(grep -Eo '<!-- spec-version: [0-9]+ -->' "$spec_file" 2>/dev/null | grep -Eo '[0-9]+' | head -1 || true)"

  [[ -n "$spec_ver" ]] || return 0

  local tasks_ver
  tasks_ver="$(grep -Eo '<!-- prd-version: [0-9]+ -->' "$tasks_file" 2>/dev/null | grep -Eo '[0-9]+' | head -1 || true)"

  if [[ -z "$tasks_ver" ]]; then
    echo "AVISO: PRD tem spec-version ($spec_ver) mas tasks.md nao tem prd-version. Considere adicionar <!-- prd-version: $spec_ver -->." >&2
    return 0
  fi

  if [[ "$spec_ver" -gt "$tasks_ver" ]]; then
    echo "DRIFT: spec-version do PRD ($spec_ver) maior que prd-version em tasks.md ($tasks_ver)" >&2
    echo "  Recomendacao: atualizar tasks.md com <!-- prd-version: $spec_ver --> e revisar tarefas." >&2
    drift=1
  fi
}

check_rf_coverage "$prd_file"      "prd.md"
check_rf_coverage "$techspec_file" "techspec.md"
check_spec_hash   "$prd_file"      "prd.md"
check_spec_hash   "$techspec_file" "techspec.md"
check_spec_version "$prd_file"

if [[ "$drift" -eq 0 ]]; then
  echo "OK: sem drift detectado entre spec e tasks.md"
  exit 0
else
  exit 1
fi
