#!/usr/bin/env bash
# Verifica se o custo total de tokens dos arquivos carregados esta dentro do budget.
#
# Uso:
#   bash scripts/check-token-budget.sh [--max <tokens>] <arquivo1> [arquivo2 ...]
#
# Opcoes:
#   --max <N>  Limite maximo de tokens (default: 15000)
#
# Retorna:
#   0 — dentro do budget
#   1 — budget excedido
#   2 — uso incorreto
#
# Estimativa: usa tiktoken (cl100k_base) quando disponivel, senao chars/3.5.
#
# Exemplo:
#   bash scripts/check-token-budget.sh --max 10000 AGENTS.md .agents/skills/agent-governance/SKILL.md

set -euo pipefail

MAX_TOKENS="${AI_TOKEN_BUDGET:-15000}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max)
      if [[ $# -lt 2 ]]; then
        echo "ERRO: --max requer um argumento numerico" >&2
        exit 2
      fi
      MAX_TOKENS="$2"
      shift 2
      ;;
    -*)
      echo "Opcao desconhecida: $1" >&2
      echo "Uso: $0 [--max <tokens>] <arquivo1> [arquivo2 ...]" >&2
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -eq 0 ]]; then
  echo "Uso: $0 [--max <tokens>] <arquivo1> [arquivo2 ...]" >&2
  exit 2
fi

# Estimar tokens de um arquivo
estimate_tokens() {
  local file="$1"
  if ! [[ -f "$file" ]]; then
    echo 0
    return
  fi

  # Tentar tiktoken via python
  if command -v python3 >/dev/null 2>&1; then
    local result
    result="$(python3 -c "
import sys
try:
    import tiktoken
    enc = tiktoken.get_encoding('cl100k_base')
    text = open(sys.argv[1], encoding='utf-8').read()
    print(len(enc.encode(text)))
except Exception:
    text = open(sys.argv[1], encoding='utf-8').read()
    print(round(len(text) / 3.5))
" "$file" 2>/dev/null || true)"
    if [[ -n "$result" ]]; then
      echo "$result"
      return
    fi
  fi

  # Fallback: chars / 3.5
  local chars
  chars="$(wc -c < "$file" | tr -d '[:space:]')"
  echo $(( (chars * 10 + 17) / 35 ))  # round(chars / 3.5)
}

total=0
file_details=""

for file in "$@"; do
  if [[ ! -f "$file" ]]; then
    echo "AVISO: arquivo nao encontrado, ignorado: $file" >&2
    continue
  fi
  tokens="$(estimate_tokens "$file")"
  total=$((total + tokens))
  file_details="${file_details}  ${tokens} tokens  ${file}\n"
done

printf '%b' "$file_details"
echo "Total: ${total} tokens (budget: ${MAX_TOKENS})"

if [[ "$total" -gt "$MAX_TOKENS" ]]; then
  echo "BUDGET EXCEDIDO: ${total} > ${MAX_TOKENS} tokens" >&2
  echo "Recomendacao: reduzir referencias carregadas ou aumentar AI_TOKEN_BUDGET." >&2
  exit 1
fi

echo "OK: dentro do budget"
exit 0
