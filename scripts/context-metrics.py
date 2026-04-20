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


def committed_files() -> set[Path]:
    """Return set of absolute paths tracked by git (committed + staged).

    Falls back to returning None on error so callers can decide whether to filter.
    Uses subprocess to call ``git ls-files`` in ROOT.
    """
    import subprocess

    try:
        result = subprocess.run(
            ["git", "ls-files"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        return {(ROOT / p.strip()).resolve() for p in result.stdout.splitlines() if p.strip()}
    except Exception:
        return set()


def tool_totals(tracked: set[Path] | None = None) -> dict[str, dict[str, int]]:
    """Total tokens installed per tool (skills + refs + wrappers).

    When *tracked* is provided (a set of absolute resolved paths from
    ``committed_files()``), only files present in that set are counted.
    This ensures local metrics match CI behaviour when untracked files exist.
    """

    def _keep(p: Path) -> bool:
        return tracked is None or p.resolve() in tracked

    tools: dict[str, dict[str, int]] = {}

    # Claude Code: wrappers + rules + all skill content (SKILL.md + references).
    # References are on-demand at runtime but are counted here as total installed footprint.
    claude_files: list[Path] = []
    claude_files += [f for f in sorted((ROOT / ".claude/agents").glob("*.md")) if _keep(f)]
    claude_files += [f for f in sorted((ROOT / ".claude/rules").glob("*.md")) if _keep(f)]
    for skill_dir in sorted((ROOT / ".agents/skills").iterdir()):
        if skill_dir.is_dir():
            for md in sorted(skill_dir.rglob("*.md")):
                if _keep(md):
                    claude_files.append(md)
    tools["claude"] = {"tokens_est": sum(int(file_metrics(f)["tokens_est"]) for f in claude_files if f.exists())}

    # Gemini CLI: .gemini/commands (adapters only; skills are read at runtime).
    gemini_files = [f for f in sorted((ROOT / ".gemini/commands").glob("*.toml")) if _keep(f)]
    tools["gemini"] = {"tokens_est": sum(int(file_metrics(f)["tokens_est"]) for f in gemini_files if f.exists())}

    # Codex: only the enabled SKILL.md files are preloaded from config.
    # References and assets are read on demand after the skill is selected.
    codex_tokens = 0
    for skill_name in codex_skills():
        skill_dir = ROOT / ".agents/skills" / skill_name
        skill_file = skill_dir / "SKILL.md"
        if skill_file.is_file() and _keep(skill_file):
            codex_tokens += int(file_metrics(skill_file)["tokens_est"])
    tools["codex"] = {"tokens_est": codex_tokens}

    # Copilot: .github/agents
    copilot_files = [f for f in sorted((ROOT / ".github/agents").glob("*.md")) if _keep(f)]
    tools["copilot"] = {"tokens_est": sum(int(file_metrics(f)["tokens_est"]) for f in copilot_files if f.exists())}

    return tools


def effective_session_tokens() -> dict[str, dict[str, int]]:
    """Typical session cost per tool: adapter loaded at startup + one operational skill at runtime.

    This metric answers "what does a real session cost?" rather than
    "what is the total installed footprint?".  It uses execute-task (Go)
    as the representative operational flow.
    """
    base = [ROOT / "AGENTS.md", ROOT / ".agents/skills/agent-governance/SKILL.md"]
    go_skill = ROOT / ".agents/skills/go-implementation/SKILL.md"
    go_arch = ROOT / ".agents/skills/go-implementation/references/architecture.md"
    execute_task = ROOT / ".agents/skills/execute-task/SKILL.md"
    review_skill = ROOT / ".agents/skills/review/SKILL.md"

    def _sum(*paths: Path) -> int:
        return sum(int(file_metrics(p)["tokens_est"]) for p in paths if p.exists())

    # Claude: AGENTS.md + agent-governance + go-implementation (arch) + execute-task + review
    claude_session = _sum(*base, go_skill, go_arch, execute_task, review_skill)

    # Gemini: one .toml adapter loaded at command dispatch + same runtime skills
    sample_toml = ROOT / ".gemini/commands/execute-task.toml"
    gemini_session = _sum(sample_toml) + _sum(*base, go_skill, go_arch, execute_task, review_skill)

    # Codex: config entry (no runtime adapter token cost) + same runtime skills
    codex_session = _sum(*base, go_skill, go_arch, execute_task)

    # Copilot: one agent wrapper + AGENTS.md (agents load AGENTS.md as base)
    copilot_wrapper = ROOT / ".github/agents/task-executor.agent.md"
    copilot_session = _sum(copilot_wrapper) + _sum(*base)

    return {
        "claude": {"tokens_est": claude_session},
        "gemini": {"tokens_est": gemini_session},
        "codex": {"tokens_est": codex_session},
        "copilot": {"tokens_est": copilot_session},
    }


def gather_metrics(committed_only: bool = False) -> dict[str, object]:
    tracked: set[Path] | None = committed_files() if committed_only else None

    def _keep(p: Path) -> bool:
        return tracked is None or p.resolve() in tracked

    skill_files = [p for p in sorted((ROOT / ".agents/skills").glob("*/SKILL.md")) if _keep(p)]
    reference_files = [p for p in sorted((ROOT / ".agents/skills").glob("*/references/*.md")) if _keep(p)]
    wrapper_files = [p for p in sorted((ROOT / ".claude/agents").glob("*.md")) if _keep(p)]
    wrapper_files += [p for p in sorted((ROOT / ".github/agents").glob("*.md")) if _keep(p)]
    wrapper_files += [p for p in sorted((ROOT / ".gemini/commands").glob("*.toml")) if _keep(p)]

    return {
        "baselines": baseline_metrics(),
        "flows": flow_metrics(),
        "tool_totals": tool_totals(tracked),
        "effective_session_tokens": effective_session_tokens(),
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
    lines.append("Effective Session Tokens (representative execute-task/Go flow):")
    session = metrics.get("effective_session_tokens", {})
    assert isinstance(session, dict)
    for tool_name, payload in session.items():
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
    parser.add_argument(
        "--committed-only",
        action="store_true",
        help=(
            "Count only files tracked by git (excludes untracked/new files). "
            "Use this flag to get metrics that match CI behaviour when working "
            "with in-progress skill directories that are not yet committed."
        ),
    )
    args = parser.parse_args()

    metrics = gather_metrics(committed_only=args.committed_only)
    if args.format == "json":
        print(json.dumps(metrics, indent=2, ensure_ascii=False))
    else:
        print(render_table(metrics))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
