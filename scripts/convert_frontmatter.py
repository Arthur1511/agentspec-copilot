#!/usr/bin/env python3
"""Convert .agent.md YAML frontmatter from Claude Code to GitHub Copilot CLI format.

Processes all 66 agents in .github/agents/:
  - 58 "overlap" agents: fetches frontmatter values from the external reference repo
    (luanmorenommaciel/agentspec) and applies Copilot CLI conversion rules.
  - 8 "ds-*" agents: already in Copilot CLI format; verifies and self-corrects if needed.

Conversion rules (DEFINE_COPILOT_FRONTMATTER_ADAPTATION.md v1.2):
  name          : frozen — always taken from local file, never the external source
  description   : plain-text examples → <example> XML blocks
  model         : any shorthand (sonnet, etc.) → "Claude Sonnet 4.5"
  tools         : Claude Code inline array → Copilot CLI YAML list with official aliases
  tier, kb_domains, color, anti_pattern_refs,
  stop_conditions, escalation_rules           : retained verbatim from external source
  agent tool    : added automatically when escalation_rules contains a target: field

Usage:
    python3 scripts/convert_frontmatter.py            # live run (writes files)
    python3 scripts/convert_frontmatter.py --dry-run  # preview only (no writes)
"""
from __future__ import annotations

import argparse
import re
import sys
import urllib.request
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parent.parent
AGENTS_DIR = REPO_ROOT / ".github" / "agents"
BASE_URL = "https://raw.githubusercontent.com/luanmorenommaciel/agentspec/main/.claude/agents"

# ---------------------------------------------------------------------------
# Tool alias map  (Claude Code name → Copilot CLI primary alias)
# Unknown tool names are kept as-is (Copilot CLI silently ignores them).
# ---------------------------------------------------------------------------

TOOL_ALIAS_MAP: dict[str, str] = {
    "Read": "read",
    "NotebookRead": "read",
    "Write": "edit",
    "Edit": "edit",
    "MultiEdit": "edit",
    "NotebookEdit": "edit",
    "Grep": "search",
    "Glob": "search",
    "Bash": "execute",
    "shell": "execute",
    "powershell": "execute",
    "TodoWrite": "todo",
    "Task": "agent",
    # AskUserQuestion has no Copilot alias; kept as-is (Copilot ignores unknowns)
}

# ---------------------------------------------------------------------------
# Agent inventory
# ---------------------------------------------------------------------------

# (local_filename, external_category, external_filename)
OVERLAP_AGENTS: list[tuple[str, str, str]] = [
    ("architect-data-platform-engineer.agent.md", "architect", "data-platform-engineer.md"),
    ("architect-genai.agent.md",                  "architect", "genai-architect.md"),
    ("architect-kb.agent.md",                     "architect", "kb-architect.md"),
    ("architect-lakehouse.agent.md",              "architect", "lakehouse-architect.md"),
    ("architect-medallion.agent.md",              "architect", "medallion-architect.md"),
    ("architect-pipeline.agent.md",               "architect", "pipeline-architect.md"),
    ("architect-schema-designer.agent.md",        "architect", "schema-designer.md"),
    ("architect-the-planner.agent.md",            "architect", "the-planner.md"),
    ("cloud-ai-data-engineer-cloud.agent.md",     "cloud",     "ai-data-engineer-cloud.md"),
    ("cloud-ai-data-engineer-gcp.agent.md",       "cloud",     "ai-data-engineer-gcp.md"),
    ("cloud-ai-prompt-specialist-gcp.agent.md",   "cloud",     "ai-prompt-specialist-gcp.md"),
    ("cloud-aws-data-architect.agent.md",         "cloud",     "aws-data-architect.md"),
    ("cloud-aws-deployer.agent.md",               "cloud",     "aws-deployer.md"),
    ("cloud-aws-lambda-architect.agent.md",       "cloud",     "aws-lambda-architect.md"),
    ("cloud-ci-cd-specialist.agent.md",           "cloud",     "ci-cd-specialist.md"),
    ("cloud-gcp-data-architect.agent.md",         "cloud",     "gcp-data-architect.md"),
    ("cloud-lambda-builder.agent.md",             "cloud",     "lambda-builder.md"),
    ("cloud-supabase-specialist.agent.md",        "cloud",     "supabase-specialist.md"),
    ("de-ai-data-engineer.agent.md",              "data-engineering", "ai-data-engineer.md"),
    ("de-airflow-specialist.agent.md",            "data-engineering", "airflow-specialist.md"),
    ("de-dbt-specialist.agent.md",                "data-engineering", "dbt-specialist.md"),
    ("de-lakeflow-architect.agent.md",            "data-engineering", "lakeflow-architect.md"),
    ("de-lakeflow-expert.agent.md",               "data-engineering", "lakeflow-expert.md"),
    ("de-lakeflow-pipeline-builder.agent.md",     "data-engineering", "lakeflow-pipeline-builder.md"),
    ("de-lakeflow-specialist.agent.md",           "data-engineering", "lakeflow-specialist.md"),
    ("de-qdrant-specialist.agent.md",             "data-engineering", "qdrant-specialist.md"),
    ("de-spark-engineer.agent.md",                "data-engineering", "spark-engineer.md"),
    ("de-spark-performance-analyzer.agent.md",    "data-engineering", "spark-performance-analyzer.md"),
    ("de-spark-specialist.agent.md",              "data-engineering", "spark-specialist.md"),
    ("de-spark-streaming-architect.agent.md",     "data-engineering", "spark-streaming-architect.md"),
    ("de-spark-troubleshooter.agent.md",          "data-engineering", "spark-troubleshooter.md"),
    ("de-sql-optimizer.agent.md",                 "data-engineering", "sql-optimizer.md"),
    ("de-streaming-engineer.agent.md",            "data-engineering", "streaming-engineer.md"),
    ("dev-codebase-explorer.agent.md",            "dev",       "codebase-explorer.md"),
    ("dev-meeting-analyst.agent.md",              "dev",       "meeting-analyst.md"),
    ("dev-prompt-crafter.agent.md",               "dev",       "prompt-crafter.md"),
    ("dev-shell-script-specialist.agent.md",      "dev",       "shell-script-specialist.md"),
    ("fabric-ai-specialist.agent.md",             "platform",  "fabric-ai-specialist.md"),
    ("fabric-architect.agent.md",                 "platform",  "fabric-architect.md"),
    ("fabric-cicd-specialist.agent.md",           "platform",  "fabric-cicd-specialist.md"),
    ("fabric-logging-specialist.agent.md",        "platform",  "fabric-logging-specialist.md"),
    ("fabric-pipeline-developer.agent.md",        "platform",  "fabric-pipeline-developer.md"),
    ("fabric-security-specialist.agent.md",       "platform",  "fabric-security-specialist.md"),
    ("python-ai-prompt-specialist.agent.md",      "python",    "ai-prompt-specialist.md"),
    ("python-code-cleaner.agent.md",              "python",    "code-cleaner.md"),
    ("python-code-documenter.agent.md",           "python",    "code-documenter.md"),
    ("python-code-reviewer.agent.md",             "python",    "code-reviewer.md"),
    ("python-developer.agent.md",                 "python",    "python-developer.md"),
    ("python-llm-specialist.agent.md",            "python",    "llm-specialist.md"),
    ("test-data-contracts-engineer.agent.md",     "test",      "data-contracts-engineer.md"),
    ("test-data-quality-analyst.agent.md",        "test",      "data-quality-analyst.md"),
    ("test-generator.agent.md",                   "test",      "test-generator.md"),
    ("workflow-brainstorm.agent.md",              "workflow",  "brainstorm-agent.md"),
    ("workflow-build.agent.md",                   "workflow",  "build-agent.md"),
    ("workflow-define.agent.md",                  "workflow",  "define-agent.md"),
    ("workflow-design.agent.md",                  "workflow",  "design-agent.md"),
    ("workflow-iterate.agent.md",                 "workflow",  "iterate-agent.md"),
    ("workflow-ship.agent.md",                    "workflow",  "ship-agent.md"),
]

DS_AGENTS: list[str] = [
    "ds-eda-analyst.agent.md",
    "ds-experiment-tracker.agent.md",
    "ds-feature-engineer.agent.md",
    "ds-ml-deployer.agent.md",
    "ds-model-evaluator.agent.md",
    "ds-model-trainer.agent.md",
    "ds-statistician.agent.md",
    "ds-time-series-analyst.agent.md",
]

# ---------------------------------------------------------------------------
# Frontmatter split / name extraction
# ---------------------------------------------------------------------------

_FM_RE = re.compile(r"^---[ \t]*\n(.*?)\n---[ \t]*\n", re.DOTALL)


def split_file(content: str) -> tuple[str, str]:
    """Return (frontmatter_yaml, body_markdown). Raises if no valid frontmatter."""
    m = _FM_RE.match(content)
    if not m:
        raise ValueError("no YAML frontmatter block found")
    return m.group(1), content[m.end():]


def read_local_name(fm_yaml: str) -> str:
    m = re.search(r"^name:\s*(.+)$", fm_yaml, re.MULTILINE)
    if not m:
        raise ValueError("no `name:` field in frontmatter")
    return m.group(1).strip()


# ---------------------------------------------------------------------------
# Description conversion
# ---------------------------------------------------------------------------

# Pattern A: "Example N — Context description:\nuser: "..."\nassistant: "...""
# Handles both em-dash (—) and regular hyphen (-) separators, and optional example number.
_EX_A = re.compile(
    r"Example\s+\d*\s*[\u2014\-]\s*([^\n]+):\s*\n"
    r"[ \t]*user:\s*[\"']?([^\"\n]*)[\"']?\s*\n"
    r'[ \t]*assistant:\s*["\']?([^"\n]*)["\'  ]?',
)

# Pattern B: "Example N:\n- Context: ...\n- user: "..."\n- assistant: "...""
_EX_B = re.compile(
    r"Example \d+:\s*\n"
    r"[ \t]*-[ \t]*[Cc]ontext:\s*([^\n]+)\s*\n"
    r"[ \t]*-[ \t]*user:\s*[\"']?([^\"\n]*)[\"']?\s*\n"
    r'[ \t]*-[ \t]*assistant:\s*["\']?([^"\n]*)["\'  ]?',
)


def _xml_example(context: str, user: str, assistant: str) -> str:
    return (
        "<example>\n"
        f"Context: {context.strip()}\n"
        f'user: "{user.strip()}"\n'
        f'assistant: "{assistant.strip()}"\n'
        "</example>"
    )


def convert_description(desc: str) -> str:
    """Convert all plain-text example blocks in desc to Copilot CLI <example> XML."""
    result = _EX_A.sub(
        lambda m: _xml_example(m.group(1), m.group(2), m.group(3)), desc
    )
    result = _EX_B.sub(
        lambda m: _xml_example(m.group(1), m.group(2), m.group(3)), result
    )
    return result.strip()


# ---------------------------------------------------------------------------
# Tools conversion
# ---------------------------------------------------------------------------

def convert_tools(tools_raw: str, escalates: bool) -> list[str]:
    """Map Claude Code tool names to Copilot CLI aliases; deduplicate; add `agent` if needed."""
    cleaned = re.sub(r"[\[\]]", "", tools_raw).strip()
    raw_tools = [t.strip().strip("\"'") for t in cleaned.split(",") if t.strip()]

    seen: list[str] = []
    for t in raw_tools:
        alias = TOOL_ALIAS_MAP.get(t, t)
        if alias not in seen:
            seen.append(alias)

    if escalates and "agent" not in seen:
        seen.append("agent")

    return seen


def has_escalation_targets(fm_yaml: str) -> bool:
    """Return True if any escalation_rules entry has a `target:` field."""
    return bool(re.search(r"^\s+target\s*:", fm_yaml, re.MULTILINE))


# ---------------------------------------------------------------------------
# Frontmatter property extraction helpers
# ---------------------------------------------------------------------------

def _extract_description_text(fm_yaml: str) -> str:
    """Extract the description block scalar, dedenting one level (2 spaces)."""
    m = re.search(
        r"^description:\s*\|\s*\n((?:[ \t]+[^\n]*(?:\n|$)|\n)+)", fm_yaml, re.MULTILINE
    )
    if m:
        return re.sub(r"^  ", "", m.group(1), flags=re.MULTILINE)
    m = re.search(r"^description:\s*(.+)$", fm_yaml, re.MULTILINE)
    if m:
        return m.group(1).strip()
    return ""


def _extract_tools_raw(fm_yaml: str) -> str:
    """Return tools value as an inline-array string regardless of source format."""
    # Inline: tools: [Read, Write, ...]
    m = re.search(r"^tools:\s*(\[.+?\])", fm_yaml, re.MULTILINE)
    if m:
        return m.group(1)
    # Block list: tools:\n  - Read\n  - Write
    block = re.search(
        r"^tools:\s*\n((?:[ \t]+-[ \t]*.+(?:\n|$))+)", fm_yaml, re.MULTILINE
    )
    if block:
        items = re.findall(r"[ \t]+-[ \t]*(.+)", block.group(1))
        return "[" + ", ".join(i.strip() for i in items) + "]"
    return "[]"


def _extract_block_prop(key: str, fm_yaml: str) -> str | None:
    """Extract a YAML property verbatim (scalar or indented block)."""
    block = re.search(
        rf"^{key}:\s*\n((?:[ \t]+[^\n]*(?:\n|$)|\n)+)", fm_yaml, re.MULTILINE
    )
    if block:
        return f"{key}:\n{block.group(1).rstrip()}"
    scalar = re.search(rf"^{key}:\s*(.*?)$", fm_yaml, re.MULTILINE)
    if scalar:
        val = scalar.group(1).strip()
        return f"{key}: {val}" if val else f"{key}:"
    return None


# ---------------------------------------------------------------------------
# Frontmatter assembly
# ---------------------------------------------------------------------------

def build_frontmatter(local_name: str, external_fm: str) -> str:
    """Assemble a Copilot CLI-valid frontmatter YAML string."""
    description_raw = _extract_description_text(external_fm)
    description_converted = convert_description(description_raw)

    tools_raw = _extract_tools_raw(external_fm)
    tools = convert_tools(tools_raw, has_escalation_targets(external_fm))

    lines: list[str] = [f"name: {local_name}"]

    lines.append("description: |")
    for line in description_converted.splitlines():
        lines.append(f"  {line}")

    for prop in ("tier", "kb_domains", "color", "anti_pattern_refs"):
        raw = _extract_block_prop(prop, external_fm)
        if raw is not None:
            lines.append(raw)

    lines.append("model: Claude Sonnet 4.5")

    lines.append("tools:")
    for t in tools:
        lines.append(f"  - {t}")

    for prop in ("stop_conditions", "escalation_rules"):
        raw = _extract_block_prop(prop, external_fm)
        if raw is not None:
            lines.append(raw)

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# HTTP fetch
# ---------------------------------------------------------------------------

def fetch_external(category: str, filename: str) -> str:
    url = f"{BASE_URL}/{category}/{filename}"
    req = urllib.request.Request(url, headers={"User-Agent": "convert-frontmatter/1.0"})
    with urllib.request.urlopen(req, timeout=15) as resp:
        raw = resp.read().decode("utf-8")
    return raw.replace("\r\n", "\n").replace("\r", "\n")


# ---------------------------------------------------------------------------
# File write
# ---------------------------------------------------------------------------

def write_agent_file(path: Path, new_fm: str, body: str) -> None:
    path.write_text(f"---\n{new_fm}\n---\n{body}", encoding="utf-8")


# ---------------------------------------------------------------------------
# Processing
# ---------------------------------------------------------------------------

def process_overlap(
    local_file: str, category: str, ext_file: str, *, dry_run: bool
) -> bool:
    local_path = AGENTS_DIR / local_file
    try:
        local_fm, body = split_file(local_path.read_text(encoding="utf-8"))
        local_name = read_local_name(local_fm)

        ext_content = fetch_external(category, ext_file)
        ext_fm, _ = split_file(ext_content)

        new_fm = build_frontmatter(local_name, ext_fm)

        if dry_run:
            print(f"\n{'='*60}")
            print(f"[DRY RUN] {local_file}")
            print(f"{'='*60}")
            print(f"---\n{new_fm}\n---")
        else:
            write_agent_file(local_path, new_fm, body)
            print(f"  ✓  {local_file}")

        return True
    except Exception as exc:
        print(f"  ✗  {local_file}: {exc}", file=sys.stderr)
        return False


def verify_ds_agent(local_file: str, *, dry_run: bool) -> bool:
    local_path = AGENTS_DIR / local_file
    try:
        content = local_path.read_text(encoding="utf-8")
        fm, body = split_file(content)

        issues: list[str] = []
        model_m = re.search(r"^model:\s*(.+)$", fm, re.MULTILINE)
        if model_m and model_m.group(1).strip().lower() in ("sonnet", "haiku", "opus"):
            issues.append("model shorthand")
        if re.search(r"^tools:\s*\[", fm, re.MULTILINE):
            issues.append("inline tools array")
        if not re.search(r"<example>", fm + body):
            issues.append("no <example> blocks")

        if not issues:
            print(f"  ✓  {local_file} (already valid)")
            return True

        if dry_run:
            print(f"  ~  {local_file} [DRY RUN] needs fix: {', '.join(issues)}")
            return True

        local_name = read_local_name(fm)
        new_fm = build_frontmatter(local_name, fm)
        write_agent_file(local_path, new_fm, body)
        print(f"  ✓  {local_file} (fixed: {', '.join(issues)})")
        return True
    except Exception as exc:
        print(f"  ✗  {local_file}: {exc}", file=sys.stderr)
        return False


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Convert agent frontmatter from Claude Code to Copilot CLI format."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview changes without writing files.",
    )
    parser.add_argument(
        "--agent",
        metavar="FILENAME",
        help="Process a single agent file only (e.g. de-spark-engineer.agent.md).",
    )
    args = parser.parse_args()

    print(f"\n{'='*60}")
    print("Copilot CLI Frontmatter Conversion")
    print(f"Mode: {'DRY RUN (no files written)' if args.dry_run else 'LIVE'}")
    print(f"{'='*60}")

    ok = err = 0

    overlap = OVERLAP_AGENTS
    ds = DS_AGENTS
    if args.agent:
        overlap = [e for e in OVERLAP_AGENTS if e[0] == args.agent]
        ds = [f for f in DS_AGENTS if f == args.agent]
        if not overlap and not ds:
            print(f"Agent '{args.agent}' not found in inventory.", file=sys.stderr)
            return 1

    if overlap:
        print(f"\n── {len(overlap)} overlap agent(s) ─────────────────────────────────────")
        for local_file, category, ext_file in overlap:
            if process_overlap(local_file, category, ext_file, dry_run=args.dry_run):
                ok += 1
            else:
                err += 1

    if ds:
        print(f"\n── {len(ds)} ds-* agent(s) (self-verify) ──────────────────────────────")
        for local_file in ds:
            if verify_ds_agent(local_file, dry_run=args.dry_run):
                ok += 1
            else:
                err += 1

    print(f"\n{'='*60}")
    print(f"Done: {ok} ok, {err} error(s)")
    print(f"{'='*60}")

    if not args.dry_run and err == 0:
        print("\nNext step: run .\\build-copilot.ps1 to validate the full plugin build.")

    return 1 if err else 0


if __name__ == "__main__":
    sys.exit(main())
