#!/usr/bin/env bats
# Mutation testing: viola regras de governanca intencionalmente e verifica
# se hooks e validators detectam a violacao.
# Formato: bats (TAP output nativo)

setup_file() {
  export TESTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  export ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
  export MUTATION_TMPDIR="$(mktemp -d)"

  mkdir -p "$MUTATION_TMPDIR/project"
  cat > "$MUTATION_TMPDIR/project/go.mod" <<'GOMOD'
module github.com/example/mutation-test
go 1.22
GOMOD

  bash "$ROOT_DIR/install.sh" --tools claude --langs go "$MUTATION_TMPDIR/project" < /dev/null 2>/dev/null
}

teardown_file() {
  rm -rf "$MUTATION_TMPDIR"
}

# ---------- Mutantes: governance hook ----------

@test "mutant: hook bloqueia edicao em SKILL.md" {
  run bash -c "echo '{\"tool_input\":{\"file_path\":\"$MUTATION_TMPDIR/project/.agents/skills/agent-governance/SKILL.md\"}}' | GOVERNANCE_HOOK_MODE=fail bash '$MUTATION_TMPDIR/project/.claude/hooks/validate-governance.sh' 2>/dev/null"
  [ "$status" -ne 0 ]
}

@test "mutant: hook bloqueia edicao em AGENTS.md" {
  run bash -c "echo '{\"tool_input\":{\"file_path\":\"$MUTATION_TMPDIR/project/AGENTS.md\"}}' | GOVERNANCE_HOOK_MODE=fail bash '$MUTATION_TMPDIR/project/.claude/hooks/validate-governance.sh' 2>/dev/null"
  [ "$status" -ne 0 ]
}

@test "mutant: hook bloqueia edicao em references/*.md" {
  run bash -c "echo '{\"tool_input\":{\"file_path\":\"$MUTATION_TMPDIR/project/.agents/skills/agent-governance/references/security.md\"}}' | GOVERNANCE_HOOK_MODE=fail bash '$MUTATION_TMPDIR/project/.claude/hooks/validate-governance.sh' 2>/dev/null"
  [ "$status" -ne 0 ]
}

# ---------- Mutantes: preload hook ----------

@test "mutant: preload bloqueia edicao .go sem contrato" {
  run bash -c "echo '{\"tool_input\":{\"file_path\":\"$MUTATION_TMPDIR/project/main.go\"}}' | GOVERNANCE_PRELOAD_MODE=fail GOVERNANCE_PRELOAD_CONFIRMED=0 bash '$MUTATION_TMPDIR/project/.claude/hooks/validate-preload.sh' 2>/dev/null"
  [ "$status" -ne 0 ]
}

@test "control: preload permite edicao com contrato confirmado" {
  run bash -c "echo '{\"tool_input\":{\"file_path\":\"$MUTATION_TMPDIR/project/main.go\"}}' | GOVERNANCE_PRELOAD_MODE=fail GOVERNANCE_PRELOAD_CONFIRMED=1 bash '$MUTATION_TMPDIR/project/.claude/hooks/validate-preload.sh' 2>/dev/null"
  [ "$status" -eq 0 ]
}

# ---------- Mutantes: depth control ----------

@test "control: profundidade 0 aceita" {
  run bash -c "AI_INVOCATION_DEPTH=0 bash '$ROOT_DIR/scripts/lib/check-invocation-depth.sh' 2>/dev/null"
  [ "$status" -eq 0 ]
}

@test "control: profundidade 1 aceita" {
  run bash -c "AI_INVOCATION_DEPTH=1 bash '$ROOT_DIR/scripts/lib/check-invocation-depth.sh' 2>/dev/null"
  [ "$status" -eq 0 ]
}

@test "mutant: profundidade 2 bloqueada (limite default)" {
  run bash -c "AI_INVOCATION_DEPTH=2 bash '$ROOT_DIR/scripts/lib/check-invocation-depth.sh' 2>/dev/null"
  [ "$status" -ne 0 ]
}

@test "mutant: profundidade 5 bloqueada" {
  run bash -c "AI_INVOCATION_DEPTH=5 bash '$ROOT_DIR/scripts/lib/check-invocation-depth.sh' 2>/dev/null"
  [ "$status" -ne 0 ]
}

# ---------- Mutantes: evidence validator ----------

@test "mutant: rejeita relatorio sem Comandos Executados" {
  cat > "$MUTATION_TMPDIR/task-no-cmds.md" <<'EOF'
# Contexto Carregado

PRD: tasks/prd-test/prd.md
TechSpec: tasks/prd-test/techspec.md

# Arquivos Alterados

- file.go

# Resultados de Validacao

Testes: pass
Lint: pass
RF-01 validado.

# Suposicoes

Nenhuma.

# Riscos Residuais

Nenhum.

Estado: done
Veredito do Revisor: APPROVED
EOF
  run bash "$ROOT_DIR/.claude/scripts/validate-task-evidence.sh" "$MUTATION_TMPDIR/task-no-cmds.md"
  [ "$status" -ne 0 ]
}

@test "mutant: rejeita relatorio sem Arquivos Alterados" {
  cat > "$MUTATION_TMPDIR/task-no-files.md" <<'EOF'
# Contexto Carregado

PRD: tasks/prd-test/prd.md
TechSpec: tasks/prd-test/techspec.md

# Comandos Executados

go test ./...

# Resultados de Validacao

Testes: pass
Lint: pass
RF-01 validado.

# Suposicoes

Nenhuma.

# Riscos Residuais

Nenhum.

Estado: done
Veredito do Revisor: APPROVED
EOF
  run bash "$ROOT_DIR/.claude/scripts/validate-task-evidence.sh" "$MUTATION_TMPDIR/task-no-files.md"
  [ "$status" -ne 0 ]
}

# ---------- Mutantes: spec drift ----------

@test "control: sem drift com hash correto" {
  mkdir -p "$MUTATION_TMPDIR/drift-test"
  cat > "$MUTATION_TMPDIR/drift-test/prd.md" <<'EOF'
# PRD Test
## Requisitos
- RF-01: Requisito um
- RF-02: Requisito dois
EOF

  if command -v sha256sum >/dev/null 2>&1; then
    real_hash="$(sha256sum "$MUTATION_TMPDIR/drift-test/prd.md" | cut -c1-8)"
  elif command -v shasum >/dev/null 2>&1; then
    real_hash="$(shasum -a 256 "$MUTATION_TMPDIR/drift-test/prd.md" | cut -c1-8)"
  else
    real_hash="abcd1234"
  fi

  cat > "$MUTATION_TMPDIR/drift-test/tasks.md" <<EOF
<!-- spec-hash-prd: ${real_hash} -->
# Tasks
- RF-01: Tarefa 1
- RF-02: Tarefa 2
EOF

  run bash "$ROOT_DIR/scripts/check-spec-drift.sh" "$MUTATION_TMPDIR/drift-test/tasks.md"
  [ "$status" -eq 0 ]
}

@test "mutant: detecta drift apos mutacao do PRD" {
  mkdir -p "$MUTATION_TMPDIR/drift-test2"
  cat > "$MUTATION_TMPDIR/drift-test2/prd.md" <<'EOF'
# PRD Test
## Requisitos
- RF-01: Requisito um
- RF-02: Requisito dois
EOF

  if command -v sha256sum >/dev/null 2>&1; then
    real_hash="$(sha256sum "$MUTATION_TMPDIR/drift-test2/prd.md" | cut -c1-8)"
  elif command -v shasum >/dev/null 2>&1; then
    real_hash="$(shasum -a 256 "$MUTATION_TMPDIR/drift-test2/prd.md" | cut -c1-8)"
  else
    real_hash="abcd1234"
  fi

  cat > "$MUTATION_TMPDIR/drift-test2/tasks.md" <<EOF
<!-- spec-hash-prd: ${real_hash} -->
# Tasks
- RF-01: Tarefa 1
- RF-02: Tarefa 2
EOF

  # Mutar o PRD
  cat > "$MUTATION_TMPDIR/drift-test2/prd.md" <<'EOF'
# PRD Test MUTADO
## Requisitos
- RF-01: Requisito um ALTERADO
- RF-02: Requisito dois
- RF-03: Requisito tres NOVO
EOF

  run bash "$ROOT_DIR/scripts/check-spec-drift.sh" "$MUTATION_TMPDIR/drift-test2/tasks.md"
  [ "$status" -ne 0 ]
}

# ---------- Mutantes: token budget ----------

@test "mutant: bloqueia arquivo que excede budget" {
  python3 -c "print('x ' * 50000)" > "$MUTATION_TMPDIR/large-file.md"
  run bash "$ROOT_DIR/scripts/check-token-budget.sh" --max 100 "$MUTATION_TMPDIR/large-file.md"
  [ "$status" -ne 0 ]
}

@test "control: aceita arquivo dentro do budget" {
  echo "small file" > "$MUTATION_TMPDIR/small-file.md"
  run bash "$ROOT_DIR/scripts/check-token-budget.sh" --max 1000 "$MUTATION_TMPDIR/small-file.md"
  [ "$status" -eq 0 ]
}

# ---------- Mutantes: pre-dispatch prerequisites ----------

@test "mutant: rejeita go-implementation sem go.mod" {
  mkdir -p "$MUTATION_TMPDIR/empty-project/.agents/skills/agent-governance"
  echo -e "---\n---" > "$MUTATION_TMPDIR/empty-project/.agents/skills/agent-governance/SKILL.md"
  echo "# Agents" > "$MUTATION_TMPDIR/empty-project/AGENTS.md"

  run bash -c "cd '$MUTATION_TMPDIR/empty-project' && bash '$ROOT_DIR/scripts/check-skill-prerequisites.sh' go-implementation . 2>/dev/null"
  [ "$status" -ne 0 ]
}
