# English Translations (i18n/en)

This directory contains English translations of the core governance files.

## Available Translations

| File | Original (PT-BR) |
|------|-------------------|
| `AGENTS.md` | Root `AGENTS.md` |
| `agent-governance-SKILL.md` | `.agents/skills/agent-governance/SKILL.md` |

## Usage

These translations serve as reference for international teams. The canonical source of truth remains the Portuguese originals in `.agents/skills/`.

To use English governance in a target project, set `GOVERNANCE_LOCALE=en` when running `install.sh`:

```bash
GOVERNANCE_LOCALE=en bash install.sh --tools claude --langs go /path/to/project
```

When this environment variable is not set, Portuguese (default) is used.

## Contributing Translations

1. Translate the original file maintaining the same structure and section order.
2. Use the naming convention: `<skill-name>-SKILL.md` for skill files.
3. Do not alter Rule IDs, severity levels, or procedural step numbers.
4. Keep inline code examples unchanged (they are language-agnostic).
