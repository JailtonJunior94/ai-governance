#!/usr/bin/env python3
"""Reporta metricas simples de contexto para governanca e perfis de carga."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def estimate_tokens(text: str) -> int:
    """Estimate token count using tiktoken (cl100k_base) when available, falling back to chars/3.5."""
    try:
        import tiktoken
        enc = tiktoken.get_encoding("cl100k_base")
        return len(enc.encode(text))
    except (ImportError, Exception):
        return round(len(text) / 3.5)


def file_metrics(path: Path) -> dict[str, int | str]:
    text = path.read_text(encoding="utf-8")
    return {
        "path": str(path.relative_to(ROOT)),
        "words": len(text.split()),
        "chars": len(text),
        "tokens_est": estimate_tokens(text),
    }


def baseline_metrics() -> dict[str, dict[str, int | list[str]]]:
    shared = [
        ROOT / "AGENTS.md",
        ROOT / ".agents/skills/agent-governance/SKILL.md",
    ]
    per_stack = {
        "go": shared
        + [
            ROOT / ".agents/skills/go-implementation/SKILL.md",
            ROOT / ".agents/skills/go-implementation/references/architecture.md",
        ],
        "node": shared
        + [
            ROOT / ".agents/skills/node-implementation/SKILL.md",
            ROOT / ".agents/skills/node-implementation/references/architecture.md",
        ],
        "python": shared
        + [
            ROOT / ".agents/skills/python-implementation/SKILL.md",
            ROOT / ".agents/skills/python-implementation/references/architecture.md",
        ],
    }
    result: dict[str, dict[str, int | list[str]]] = {}
    for name, files in per_stack.items():
        total_words = 0
        total_chars = 0
        total_tokens = 0
        for file in files:
            metrics = file_metrics(file)
            total_words += int(metrics["words"])
            total_chars += int(metrics["chars"])
            total_tokens += int(metrics["tokens_est"])
        result[name] = {
            "files": [str(file.relative_to(ROOT)) for file in files],
            "words": total_words,
            "chars": total_chars,
            "tokens_est": total_tokens,
        }
    return result


def flow_metrics() -> dict[str, dict[str, int | list[str]]]:
    """Estimate token cost for common operational flows (baseline + skill(s))."""
    flows = {
        "execute-task (Go)": [
            ROOT / "AGENTS.md",
            ROOT / ".agents/skills/agent-governance/SKILL.md",
            ROOT / ".agents/skills/go-implementation/SKILL.md",
            ROOT / ".agents/skills/go-implementation/references/architecture.md",
            ROOT / ".agents/skills/execute-task/SKILL.md",
            ROOT / ".agents/skills/review/SKILL.md",
        ],
        "execute-task (Node)": [
            ROOT / "AGENTS.md",
            ROOT / ".agents/skills/agent-governance/SKILL.md",
            ROOT / ".agents/skills/node-implementation/SKILL.md",
            ROOT / ".agents/skills/node-implementation/references/architecture.md",
            ROOT / ".agents/skills/execute-task/SKILL.md",
            ROOT / ".agents/skills/review/SKILL.md",
        ],
        "execute-task (Python)": [
            ROOT / "AGENTS.md",
            ROOT / ".agents/skills/agent-governance/SKILL.md",
            ROOT / ".agents/skills/python-implementation/SKILL.md",
            ROOT / ".agents/skills/python-implementation/references/architecture.md",
            ROOT / ".agents/skills/execute-task/SKILL.md",
            ROOT / ".agents/skills/review/SKILL.md",
        ],
        "review": [
            ROOT / "AGENTS.md",
            ROOT / ".agents/skills/agent-governance/SKILL.md",
            ROOT / ".agents/skills/review/SKILL.md",
        ],
        "bugfix (Go)": [
            ROOT / "AGENTS.md",
            ROOT / ".agents/skills/agent-governance/SKILL.md",
            ROOT / ".agents/skills/go-implementation/SKILL.md",
            ROOT / ".agents/skills/go-implementation/references/architecture.md",
            ROOT / ".agents/skills/bugfix/SKILL.md",
        ],
        "bugfix (Node)": [
            ROOT / "AGENTS.md",
            ROOT / ".agents/skills/agent-governance/SKILL.md",
            ROOT / ".agents/skills/node-implementation/SKILL.md",
            ROOT / ".agents/skills/node-implementation/references/architecture.md",
            ROOT / ".agents/skills/bugfix/SKILL.md",
        ],
        "bugfix (Python)": [
            ROOT / "AGENTS.md",
            ROOT / ".agents/skills/agent-governance/SKILL.md",
            ROOT / ".agents/skills/python-implementation/SKILL.md",
            ROOT / ".agents/skills/python-implementation/references/architecture.md",
            ROOT / ".agents/skills/bugfix/SKILL.md",
        ],
        "refactor (Go)": [
            ROOT / "AGENTS.md",
            ROOT / ".agents/skills/agent-governance/SKILL.md",
            ROOT / ".agents/skills/go-implementation/SKILL.md",
            ROOT / ".agents/skills/go-implementation/references/architecture.md",
            ROOT / ".agents/skills/refactor/SKILL.md",
            ROOT / ".agents/skills/review/SKILL.md",
        ],
        "refactor (Node)": [
            ROOT / "AGENTS.md",
            ROOT / ".agents/skills/agent-governance/SKILL.md",
            ROOT / ".agents/skills/node-implementation/SKILL.md",
            ROOT / ".agents/skills/node-implementation/references/architecture.md",
            ROOT / ".agents/skills/refactor/SKILL.md",
            ROOT / ".agents/skills/review/SKILL.md",
        ],
        "refactor (Python)": [
            ROOT / "AGENTS.md",
            ROOT / ".agents/skills/agent-governance/SKILL.md",
            ROOT / ".agents/skills/python-implementation/SKILL.md",
            ROOT / ".agents/skills/python-implementation/references/architecture.md",
            ROOT / ".agents/skills/refactor/SKILL.md",
            ROOT / ".agents/skills/review/SKILL.md",
        ],
    }
    result: dict[str, dict[str, int | list[str]]] = {}
    for name, files in flows.items():
        existing = [f for f in files if f.exists()]
        total_tokens = sum(int(file_metrics(f)["tokens_est"]) for f in existing)
        result[name] = {
            "files": [str(f.relative_to(ROOT)) for f in existing],
            "tokens_est": total_tokens,
        }
    return result


def codex_skills() -> list[str]:
    skills: list[str] = []
    config_path = ROOT / ".codex/config.toml"
    for line in config_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line.startswith('path = "'):
            continue
        path = line.split('"', 2)[1]
        skills.append(path.rsplit("/", 1)[-1])
    return skills


def tool_totals() -> dict[str, dict[str, int]]:
    """Total tokens installed per tool (skills + refs + wrappers)."""
    tools: dict[str, dict[str, int]] = {}

    # Claude Code: .claude/agents + .claude/skills (symlinks to .agents/skills)
    claude_files: list[Path] = []
    claude_files += sorted((ROOT / ".claude/agents").glob("*.md"))
    claude_files += sorted((ROOT / ".claude/rules").glob("*.md"))
    for skill_dir in sorted((ROOT / ".agents/skills").iterdir()):
        if skill_dir.is_dir():
            for md in sorted(skill_dir.rglob("*.md")):
                claude_files.append(md)
    tools["claude"] = {"tokens_est": sum(int(file_metrics(f)["tokens_est"]) for f in claude_files if f.exists())}

    # Gemini CLI: .gemini/commands + .agents/skills (read at runtime)
    gemini_files: list[Path] = sorted((ROOT / ".gemini/commands").glob("*.toml"))
    tools["gemini"] = {"tokens_est": sum(int(file_metrics(f)["tokens_est"]) for f in gemini_files if f.exists())}

    # Codex: only skills listed in .codex/config.toml
    codex_tokens = 0
    for skill_name in codex_skills():
        skill_dir = ROOT / ".agents/skills" / skill_name
        if skill_dir.is_dir():
            for md in sorted(skill_dir.rglob("*.md")):
                codex_tokens += int(file_metrics(md)["tokens_est"])
    tools["codex"] = {"tokens_est": codex_tokens}

    # Copilot: .github/agents + .github/skills (symlinks)
    copilot_files: list[Path] = sorted((ROOT / ".github/agents").glob("*.md"))
    tools["copilot"] = {"tokens_est": sum(int(file_metrics(f)["tokens_est"]) for f in copilot_files if f.exists())}

    return tools


def gather_metrics() -> dict[str, object]:
    skill_files = sorted((ROOT / ".agents/skills").glob("*/SKILL.md"))
    reference_files = sorted((ROOT / ".agents/skills").glob("*/references/*.md"))
    wrapper_files = sorted((ROOT / ".claude/agents").glob("*.md"))
    wrapper_files += sorted((ROOT / ".github/agents").glob("*.md"))
    wrapper_files += sorted((ROOT / ".gemini/commands").glob("*.toml"))

    return {
        "baselines": baseline_metrics(),
        "flows": flow_metrics(),
        "tool_totals": tool_totals(),
        "skills": [file_metrics(path) for path in skill_files],
        "references": [file_metrics(path) for path in reference_files],
        "wrappers": [file_metrics(path) for path in wrapper_files],
        "codex": {
          "skills": codex_skills(),
          "count": len(codex_skills()),
        },
    }


def render_table(metrics: dict[str, object]) -> str:
    lines = ["Baselines:"]
    baselines = metrics["baselines"]
    assert isinstance(baselines, dict)
    for stack, payload in baselines.items():
        assert isinstance(payload, dict)
        lines.append(
            f"- {stack}: words={payload['words']} chars={payload['chars']} est_tokens={payload['tokens_est']}"
        )

    lines.append("")
    lines.append("Flows:")
    flows = metrics["flows"]
    assert isinstance(flows, dict)
    for flow_name, payload in flows.items():
        assert isinstance(payload, dict)
        lines.append(
            f"- {flow_name}: est_tokens={payload['tokens_est']}"
        )

    lines.append("")
    lines.append("Tool Totals:")
    totals = metrics["tool_totals"]
    assert isinstance(totals, dict)
    for tool_name, payload in totals.items():
        assert isinstance(payload, dict)
        lines.append(f"- {tool_name}: est_tokens={payload['tokens_est']}")

    lines.append("")
    lines.append("Codex:")
    codex = metrics["codex"]
    assert isinstance(codex, dict)
    lines.append(f"- count={codex['count']} skills={', '.join(codex['skills'])}")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--format", choices=("json", "table"), default="table")
    args = parser.parse_args()

    metrics = gather_metrics()
    if args.format == "json":
        print(json.dumps(metrics, indent=2, ensure_ascii=False))
    else:
        print(render_table(metrics))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
