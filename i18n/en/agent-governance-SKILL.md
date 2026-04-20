---
name: agent-governance
version: 1.0.0
description: Orchestrates governance rules, DDD, error handling, security, and testing for AI agent tasks. Use when the task requires applying mandatory patterns before analyzing, editing, or validating code. Do not use for casual tasks without code changes or to replace language-specific skills.
---

# Agent Governance

## Procedures

**Step 1: Load base context**
1. Confirm that the base load contract defined in `AGENTS.md` has been fulfilled.
2. Identify if the task affects domain modeling, error flow, security, validation, or tests.
3. Apply the smallest safe change that preserves existing architecture, conventions, and boundaries.

**Reference index** (consult before loading — avoids unnecessary reads)
| File | Description |
|------|-------------|
| `references/ddd.md` | Entities, value objects, aggregate roots, state transitions, application rules |
| `references/error-handling.md` | Wrapping, sentinel errors, custom types, error propagation |
| `references/security.md` | Filesystem, subprocesses, secrets, runtime, external input, dependencies |
| `references/security-app.md` | Authentication, authorization, validation, rate limiting, CORS |
| `references/testing.md` | Unit and integration test strategy, mocking, coverage |
| `references/shared-lifecycle.md` | Init, shutdown, signal handling, drain — universal principles |
| `references/shared-testing.md` | Cross-language test principles: determinism, testcontainers |
| `references/shared-architecture.md` | DI, module organization, over-engineering signals — cross-language |
| `references/shared-patterns.md` | Repository, Factory, DI, Value Objects, Error Handling — cross-language |
| `references/persistence.md` | Repositories, transactions, migrations, connection management |
| `references/observability.md` | Logging, tracing, metrics, health checks |
| `references/messaging.md` | Events, queues, topics, outbox pattern, idempotency |
| `references/enforcement-matrix.md` | Capability table per tool (Claude, Gemini, Codex, Copilot) |
| `references/bug-schema.json` | Canonical JSON schema for bug format |

**Step 2: Load references on demand**
1. Read `references/ddd.md` when the task modifies entities, value objects, aggregate roots, state transitions, or application rules.
2. Read `references/error-handling.md` when the task creates, propagates, wraps, compares, or presents errors.
3. Read `references/security.md` when the task involves filesystem, subprocesses, secrets, configuration, runtime, external input, or dependencies.
4. Read `references/testing.md` when the task modifies behavior, validators, runtime, adapters, persistence, or validation gates.
5. Read `references/shared-lifecycle.md` when the task involves initialization, shutdown, signal handling, or connection drain — universal principles applicable to any language.
6. Read `references/shared-testing.md` when the task involves cross-language test strategy — unit/integration test principles applicable to any stack.
7. Read `references/shared-architecture.md` when the task involves cross-language architectural decisions — DI, module organization, over-engineering signals.
8. Read `references/shared-patterns.md` when the task involves recurring cross-language patterns — Repository, Factory, DI, Value Objects, Error Handling.

**Step 3: Execute with control**
1. Preserve existing public behavior unless the change explicitly alters it.
2. Do not invent missing context, language version, framework, or runtime without local verification.
3. Do not introduce abstractions, layers, or dependencies without concrete demand.
4. Update or add tests when behavior changes.

**Step 4: Validate proportionally**
1. Run formatter on changed files when the stack offers this step.
2. Run targeted tests first for affected packages or modules.
3. Run broader tests and lint when the cost is proportional to the risk.
4. Record failures with the exact command and a short diagnosis.
5. If the project offers `detect-toolchain.sh`, use the returned commands instead of guessing.

## Invocation Depth Control

When a skill invokes another (e.g., execute-task -> review -> bugfix), increment `AI_INVOCATION_DEPTH` and check the limit before proceeding:

```bash
source scripts/lib/check-invocation-depth.sh || { echo "failed: depth limit exceeded"; exit 1; }
```

If `AI_INVOCATION_DEPTH` exceeds 2 (the default `AI_INVOCATION_MAX` limit), stop the chain and return `failed` with diagnosis: "invocation depth limit reached". This prevents loops between review and bugfix.

## Error Handling
* If the task doesn't make clear which references to load, apply `AGENTS.md` as baseline and read only the thematic files directly linked to the changed surface.
* If there's a conflict between identified local convention and a generic rule from this skill, prioritize the existing architecture and contracts in the analyzed context and record the assumption.
* If a validation command doesn't exist in the analyzed context, do not invent substitutes; explicitly record the absence.
* If the invocation depth limit is reached, do not try to circumvent it; record the cycle and return the blocking state.
