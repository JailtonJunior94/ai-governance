#!/usr/bin/env bash
# Coleta metricas de eficacia pos-execucao a partir de relatorios de execucao.
#
# Uso:
#   bash scripts/collect-efficacy-metrics.sh <tasks-dir>
#
# Exemplo:
#   bash scripts/collect-efficacy-metrics.sh tasks/prd-feature
#
# Metricas coletadas:
#   - Total de tarefas executadas
#   - Taxa de sucesso (done vs blocked/failed)
#   - Taxa de retrabalho (bugfix invocado apos review)
#   - Vereditos de revisao (APPROVED vs REJECTED vs APPROVED_WITH_REMARKS)
#   - Bugs encontrados em review
#
# Saida: resumo em texto para stdout.
# Exit 0 = sucesso, Exit 2 = uso incorreto.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 <tasks-dir>" >&2
  exit 2
fi

tasks_dir="$1"

if [[ ! -d "$tasks_dir" ]]; then
  echo "ERRO: diretorio nao encontrado: $tasks_dir" >&2
  exit 2
fi

# Contadores
total_reports=0
done_count=0
blocked_count=0
failed_count=0
approved_count=0
rejected_count=0
approved_remarks_count=0
bugfix_count=0
total_bugs_fixed=0

# Processar relatorios de execucao de tarefas
# Collect unique report files matching common naming patterns
report_files=()
for pattern in "$tasks_dir"/task-*-report*.md "$tasks_dir"/*execution_report*.md "$tasks_dir"/*_report.md; do
  for f in $pattern; do
    [[ -f "$f" ]] || continue
    # Deduplicate
    local_dup=0
    for existing in "${report_files[@]+"${report_files[@]}"}"; do
      [[ "$existing" == "$f" ]] && { local_dup=1; break; }
    done
    [[ "$local_dup" -eq 0 ]] && report_files+=("$f")
  done
done

for report in "${report_files[@]+"${report_files[@]}"}"; do
  [[ -f "$report" ]] || continue
  total_reports=$((total_reports + 1))

  # Estado terminal
  if grep -Eiq "estado[[:space:]]*:[[:space:]]*done" "$report" 2>/dev/null; then
    done_count=$((done_count + 1))
  elif grep -Eiq "estado[[:space:]]*:[[:space:]]*blocked" "$report" 2>/dev/null; then
    blocked_count=$((blocked_count + 1))
  elif grep -Eiq "estado[[:space:]]*:[[:space:]]*failed" "$report" 2>/dev/null; then
    failed_count=$((failed_count + 1))
  fi

  # Veredito do revisor
  if grep -Eiq "veredito do revisor[[:space:]]*:[[:space:]]*APPROVED_WITH_REMARKS" "$report" 2>/dev/null; then
    approved_remarks_count=$((approved_remarks_count + 1))
  elif grep -Eiq "veredito do revisor[[:space:]]*:[[:space:]]*APPROVED" "$report" 2>/dev/null; then
    approved_count=$((approved_count + 1))
  elif grep -Eiq "veredito do revisor[[:space:]]*:[[:space:]]*REJECTED" "$report" 2>/dev/null; then
    rejected_count=$((rejected_count + 1))
  fi
done

# Processar relatorios de bugfix (indicador de retrabalho)
for bugfix_report in "$tasks_dir"/bugfix_report*.md "$tasks_dir"/bugfix-report*.md; do
  [[ -f "$bugfix_report" ]] || continue
  bugfix_count=$((bugfix_count + 1))

  # Contar bugs corrigidos
  fixed="$(grep -Eio 'Corrigidos[[:space:]]*:[[:space:]]*([0-9]+)' "$bugfix_report" 2>/dev/null | head -1 | grep -Eo '[0-9]+' || echo 0)"
  total_bugs_fixed=$((total_bugs_fixed + fixed))
done

# Calcular metricas
if [[ "$total_reports" -eq 0 ]]; then
  echo "Nenhum relatorio de execucao encontrado em $tasks_dir"
  exit 0
fi

success_rate=0
rework_rate=0
if [[ "$total_reports" -gt 0 ]]; then
  success_rate=$(( (done_count * 100) / total_reports ))
fi
if [[ "$total_reports" -gt 0 ]]; then
  rework_rate=$(( (bugfix_count * 100) / total_reports ))
fi

total_verdicts=$((approved_count + rejected_count + approved_remarks_count))
approval_rate=0
if [[ "$total_verdicts" -gt 0 ]]; then
  approval_rate=$(( (approved_count * 100) / total_verdicts ))
fi

# Saida
echo "=== Metricas de Eficacia ==="
echo ""
echo "Diretorio: $tasks_dir"
echo ""
echo "--- Execucao ---"
echo "  Total de relatorios:  $total_reports"
echo "  Concluidos (done):    $done_count ($success_rate%)"
echo "  Bloqueados:           $blocked_count"
echo "  Falhados:             $failed_count"
echo ""
echo "--- Revisao ---"
echo "  APPROVED:             $approved_count"
echo "  APPROVED_WITH_REMARKS: $approved_remarks_count"
echo "  REJECTED:             $rejected_count"
if [[ "$total_verdicts" -gt 0 ]]; then
  echo "  Taxa de aprovacao:    $approval_rate%"
fi
echo ""
echo "--- Retrabalho ---"
echo "  Ciclos de bugfix:     $bugfix_count ($rework_rate% das tarefas)"
echo "  Bugs corrigidos:      $total_bugs_fixed"
echo ""
echo "--- Indicadores ---"
if [[ "$success_rate" -ge 80 ]]; then
  echo "  Saude: BOA (taxa de sucesso >= 80%)"
elif [[ "$success_rate" -ge 50 ]]; then
  echo "  Saude: ATENCAO (taxa de sucesso entre 50-80%)"
else
  echo "  Saude: CRITICA (taxa de sucesso < 50%)"
fi
if [[ "$rework_rate" -gt 50 ]]; then
  echo "  Retrabalho: ALTO (>50% das tarefas geraram bugfix)"
elif [[ "$rework_rate" -gt 20 ]]; then
  echo "  Retrabalho: MODERADO (20-50%)"
else
  echo "  Retrabalho: BAIXO (<20%)"
fi
