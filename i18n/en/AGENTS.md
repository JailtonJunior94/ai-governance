# Rules for AI Agents

This directory centralizes rules for use with AI agents in real-world tasks of analysis, modification, and validation of code.

## Objective

Use these instructions to maintain consistency, security, and quality when working with code, configuration, validation, and system evolution.

## Working Mode

1. Understand the context before editing any file.
2. Prefer the smallest safe change that addresses the root cause.
3. Preserve existing architecture, conventions, and boundaries in the analyzed context.
4. Do not introduce abstractions, layers, or dependencies without concrete demand.
5. Update or add tests when behavior changes.
6. Run validations proportional to the change.
7. Explicitly record blockers and assumptions when context is incomplete.

## Structure Guidelines

1. Prioritize understanding the code and current context before proposing refactorings.
2. Respect existing patterns of naming, organization, and error handling.
3. Define simple, evolutionary structure with explicit defaults.
4. Avoid wide rewrites when a localized change solves the problem.
5. Establish contracts, tests, and validation commands early when they don't yet exist.
6. Consider regression risk as the main constraint.
7. Avoid overengineering disguised as future architecture.

## Base Load Contract

Every skill that modifies code must load, as its first step, the following mandatory base — this instruction is reinforced in each SKILL.md as a defensive measure:

1. Read this `AGENTS.md`.
2. Read `.agents/skills/agent-governance/SKILL.md`.

This base defines governance for analysis, modification, and validation, on-demand loading of DDD, error, security, and testing rules, and minimum criteria for architectural preservation, risk, and proportional validation.

Individual skills should declare only additional loads specific to their context.

## Language-Specific Rules

For tasks that modify Go code, also load:

- `.agents/skills/go-implementation/SKILL.md`

For tasks that modify Node/TypeScript code, also load:

- `.agents/skills/node-implementation/SKILL.md`

For tasks that modify Python code, also load:

- `.agents/skills/python-implementation/SKILL.md`

For Go review or incremental design refactoring tasks guided by object calisthenics heuristics, also load:

- `.agents/skills/object-calisthenics-go/SKILL.md`

For bug fix tasks with remediation and regression testing, also load:

- `.agents/skills/bugfix/SKILL.md`

## References

Each skill lists its own references in `references/` with loading triggers in its respective `SKILL.md`. Do not duplicate the listing here — consult the active skill's SKILL.md to know which references to load and under what conditions.

## Validation

Before completing a change, follow Step 4 of `.agents/skills/agent-governance/SKILL.md`.

## Restrictions

1. Do not invent missing context.
2. Do not assume language version, framework, or runtime without verification.
3. Do not change public behavior without making it explicit.
4. Do not use examples as blind copies; adapt to the real context.
