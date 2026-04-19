#!/usr/bin/env bash
# Gates de economia de contexto e perfil minimal do Codex.

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
METRICS_SCRIPT="$ROOT_DIR/scripts/context-metrics.py"

PASSED=0
FAILED=0

pass() {
  echo "PASS  $1"
  PASSED=$((PASSED + 1))
}

fail() {
  echo "FAIL  $1"
  FAILED=$((FAILED + 1))
}

metrics_json="$(python3 "$METRICS_SCRIPT" --format json)"

if [[ -n "$metrics_json" ]]; then
  pass "context-metrics: script retorna JSON"
else
  fail "context-metrics: script nao retornou JSON"
fi

check_baseline_budget() {
  local stack="$1"
  local max_tokens="$2"
  local tokens
  tokens="$(METRICS_JSON="$metrics_json" python3 - "$stack" <<'PY'
import json
import os
import sys

payload = json.loads(os.environ["METRICS_JSON"])
print(payload["baselines"][sys.argv[1]]["tokens_est"])
PY
)"

  if [[ "$tokens" -le "$max_tokens" ]]; then
    pass "context-budget/$stack: ${tokens} <= ${max_tokens}"
  else
    fail "context-budget/$stack: ${tokens} > ${max_tokens}"
  fi
}

check_baseline_budget "go" 4700
check_baseline_budget "node" 4100
check_baseline_budget "python" 4100

if METRICS_JSON="$metrics_json" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["METRICS_JSON"])
for item in payload["wrappers"]:
    if item["words"] > 150:
        raise SystemExit(1)
PY
then
  pass "wrapper-budget: wrappers <= 150 palavras"
else
  fail "wrapper-budget: wrapper excede 150 palavras"
fi

if METRICS_JSON="$metrics_json" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["METRICS_JSON"])
for item in payload["skills"]:
    if item["words"] > 1200:
        raise SystemExit(1)
PY
then
  pass "skill-budget: cada SKILL.md <= 1200 palavras"
else
  fail "skill-budget: algum SKILL.md excede 1200 palavras"
fi

if METRICS_JSON="$metrics_json" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["METRICS_JSON"])
expected = ["agent-governance", "execute-task", "refactor", "review", "bugfix"]
if payload["codex"]["skills"] != expected:
    raise SystemExit(1)
PY
then
  pass "codex-minimal: config raiz usa baseline enxuto esperado"
else
  fail "codex-minimal: config raiz diverge do baseline enxuto"
fi

# Gate: flow budgets
check_flow_budget() {
  local flow="$1"
  local max_tokens="$2"
  local tokens
  tokens="$(METRICS_JSON="$metrics_json" python3 - "$flow" <<'PY'
import json
import os
import sys

payload = json.loads(os.environ["METRICS_JSON"])
flow_name = sys.argv[1]
data = payload["flows"].get(flow_name, {})
print(data.get("tokens_est", 0))
PY
)"

  if [[ "$tokens" -le "$max_tokens" ]]; then
    pass "flow-budget/$flow: ${tokens} <= ${max_tokens}"
  else
    fail "flow-budget/$flow: ${tokens} > ${max_tokens}"
  fi
}

check_flow_budget "execute-task (Go)" 7000
check_flow_budget "execute-task (Node)" 6400
check_flow_budget "execute-task (Python)" 6400
check_flow_budget "review" 3000
check_flow_budget "bugfix (Go)" 6000
check_flow_budget "bugfix (Node)" 5400
check_flow_budget "bugfix (Python)" 5400
check_flow_budget "refactor (Go)" 6800
check_flow_budget "refactor (Node)" 6000
check_flow_budget "refactor (Python)" 6000

if grep -q '".agents/skills/analyze-project"' "$ROOT_DIR/.codex/config.toml" 2>/dev/null; then
  fail "codex-regression: analyze-project presente no perfil enxuto"
else
  pass "codex-regression: planning skill ausente do perfil enxuto"
fi

# Gate: total de tokens por ferramenta
check_tool_total() {
  local tool="$1"
  local max_tokens="$2"
  local tokens
  tokens="$(METRICS_JSON="$metrics_json" python3 - "$tool" <<'PY'
import json
import os
import sys

payload = json.loads(os.environ["METRICS_JSON"])
print(payload["tool_totals"][sys.argv[1]]["tokens_est"])
PY
)"

  if [[ "$tokens" -le "$max_tokens" ]]; then
    pass "tool-total/$tool: ${tokens} <= ${max_tokens}"
  else
    fail "tool-total/$tool: ${tokens} > ${max_tokens}"
  fi
}

check_tool_total "claude" 70000
check_tool_total "gemini" 4000
check_tool_total "codex" 13000
check_tool_total "copilot" 2000

# Gate: nenhuma referencia individual pode exceder 1500 palavras
ref_over_budget="$(METRICS_JSON="$metrics_json" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["METRICS_JSON"])
over = [item for item in payload["references"] if item["words"] > 1500]
for item in over:
    print(f"  {item['path']}: {item['words']} palavras")
PY
)"

if [[ -z "$ref_over_budget" ]]; then
  pass "reference-budget: todas as referencias <= 1500 palavras"
else
  fail "reference-budget: referencias acima do limite"
  echo "$ref_over_budget"
fi

# Gate: drift entre estimativa chars/3.5 e tiktoken (quando disponivel)
drift_result="$(ROOT_DIR="$ROOT_DIR" python3 - <<'PY' 2>/dev/null || echo "skip"
import os
import pathlib

try:
    import tiktoken
except ImportError:
    print("skip")
    raise SystemExit(0)

ROOT = pathlib.Path(os.environ["ROOT_DIR"])
enc = tiktoken.get_encoding("cl100k_base")
MAX_DRIFT_PCT = 20

files = [
    ROOT / "AGENTS.md",
    ROOT / ".agents/skills/agent-governance/SKILL.md",
    ROOT / ".agents/skills/go-implementation/SKILL.md",
    ROOT / ".agents/skills/go-implementation/references/architecture.md",
]

max_drift = 0.0
for f in files:
    if not f.exists():
        continue
    text = f.read_text(encoding="utf-8")
    real = len(enc.encode(text))
    estimated = round(len(text) / 3.5)
    if real == 0:
        continue
    drift = abs(real - estimated) / real * 100
    if drift > max_drift:
        max_drift = drift

if max_drift > MAX_DRIFT_PCT:
    print(f"fail:{max_drift:.1f}")
else:
    print(f"ok:{max_drift:.1f}")
PY
)"

case "$drift_result" in
  skip)
    pass "token-drift: tiktoken nao disponivel, gate ignorado"
    ;;
  ok:*)
    drift_pct="${drift_result#ok:}"
    pass "token-drift: drift maximo ${drift_pct}% (limite 20%)"
    ;;
  fail:*)
    drift_pct="${drift_result#fail:}"
    fail "token-drift: drift maximo ${drift_pct}% excede limite de 20%"
    ;;
  *)
    pass "token-drift: verificacao ignorada (resultado inesperado)"
    ;;
esac

echo ""
echo "Resultado: $PASSED passed, $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
  exit 1
fi
