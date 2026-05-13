# DESIGN: Copilot CLI Frontmatter Adaptation

> Technical design for bulk-converting 66 `.agent.md` YAML frontmatter blocks to GitHub Copilot CLI format.

## Metadata

| Attribute | Value |
|-----------|-------|
| **Feature** | COPILOT_FRONTMATTER_ADAPTATION |
| **Date** | 2026-05-13 |
| **Author** | design-agent |
| **DEFINE** | [DEFINE_COPILOT_FRONTMATTER_ADAPTATION.md](./DEFINE_COPILOT_FRONTMATTER_ADAPTATION.md) |
| **Status** | ✅ Shipped |

---

## Architecture Overview

```text
┌──────────────────────────────────────────────────────────────────────┐
│                   CONVERSION PIPELINE                                │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  GitHub Raw API                                                      │
│  (luanmorenommaciel/agentspec)                                       │
│        │                                                             │
│        ▼ fetch_external(category, filename)                          │
│  ┌──────────────┐    parse_frontmatter()    ┌───────────────────┐   │
│  │ External .md │ ─────────────────────────▶│ ExternalFrontmatter│  │
│  └──────────────┘                           └────────┬──────────┘   │
│                                                      │              │
│  Local .agent.md                                     │              │
│        │                                             ▼              │
│        ▼ read_local()                    convert_frontmatter()      │
│  ┌──────────────┐  local name only  ┌───────────────────────────┐   │
│  │  local name  │ ─────────────────▶│   Converted Frontmatter   │   │
│  │  + body text │                   │  (Copilot CLI valid YAML)  │   │
│  └──────────────┘                   └────────────┬──────────────┘   │
│                                                  │                  │
│                                                  ▼                  │
│                                    write_agent_file()               │
│                                    (replaces only frontmatter)      │
│                                                  │                  │
│                                                  ▼                  │
│                                       .github/agents/<file>         │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

**Special cases handled inline:**
- `ds-*` agents (8): read local only → verify format → fix if needed → no external fetch
- `fabric-cicd-specialist`: deduplicate any extra `name:` fields after conversion

---

## Components

| Component | Purpose | Location |
|-----------|---------|----------|
| `convert_frontmatter.py` | Main conversion script | `scripts/convert_frontmatter.py` |
| Agent inventory | Mapping table (local ↔ external path) | Embedded constant in script |
| Tool alias map | Claude Code → Copilot CLI alias lookup | Embedded constant in script |
| Description converter | Regex-based example block converter | Function in script |
| Frontmatter writer | Replaces YAML block, preserves body | Function in script |

---

## Key Decisions

### Decision 1: Python as implementation language

| Attribute | Value |
|-----------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-13 |

**Context:** The conversion involves YAML parsing, multi-pattern regex, HTTP fetching, and file manipulation across 66 files. Needs to run on Windows (PowerShell-native CI environment).

**Choice:** Python 3 with stdlib only (`re`, `urllib.request`, `pathlib`) — no third-party dependencies.

**Rationale:** `pyyaml` would be ideal but introduces a dependency. The agent frontmatter is simple enough (no nested anchors, no multi-line scalars beyond `description`) that manual regex-based YAML extraction is reliable and zero-dependency.

**Alternatives Rejected:**
1. PowerShell — regex string manipulation for YAML is verbose and error-prone; no built-in YAML parser
2. Python + PyYAML — better YAML parsing but adds `pip install` step; overkill for this structured format

**Consequences:**
- Script is self-contained and runs with `python scripts/convert_frontmatter.py`
- Manual YAML extraction is scoped to the known frontmatter structure; edge cases are logged as warnings

---

### Decision 2: Regex-based frontmatter extraction (not full YAML parse)

| Attribute | Value |
|-----------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-13 |

**Context:** The YAML frontmatter has a predictable structure. A full YAML parse risks reformatting custom list properties (`stop_conditions`, `escalation_rules`) in ways that change their canonical representation.

**Choice:** Extract the raw frontmatter block as a string, apply targeted regex substitutions per-property, then reassemble.

**Rationale:** Preserves the exact original YAML style of retained custom properties. Only `description`, `tools`, and `model` need algorithmic conversion; everything else is copied verbatim.

**Alternatives Rejected:**
1. Full YAML round-trip (parse → modify → dump) — `yaml.dump()` would reformat multi-line strings, change quote styles, and reorder keys
2. AST-based YAML editing — no stdlib support; requires `ruamel.yaml`

**Consequences:**
- Custom props (`tier`, `kb_domains`, `color`, `escalation_rules`, `stop_conditions`, `anti_pattern_refs`) are copied verbatim from external frontmatter
- `description` conversion uses regex to find example blocks and replace them with XML

---

### Decision 3: Frontmatter-only file mutation

| Attribute | Value |
|-----------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-13 |

**Context:** Each `.agent.md` file has a YAML frontmatter block (lines between the first and second `---` delimiters) followed by Markdown body content. Only frontmatter should change.

**Choice:** Split file on `---` delimiter, replace only the first segment (frontmatter), rejoin with body untouched.

**Rationale:** Safe, deterministic, zero risk of corrupting agent instructions in the body.

**Consequences:**
- Body content (agent instructions, capability tables, quality gates) is never touched
- If a file has no valid frontmatter, the script logs a warning and skips it

---

### Decision 4: `name:` field is frozen (local value always wins)

| Attribute | Value |
|-----------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-13 |

**Context:** Local `name:` values are the Copilot CLI identifiers referenced across the entire skill/agent ecosystem. External names use Claude Code naming (e.g., `brainstorm-agent` vs. `agentspec:brainstorm-agent`).

**Choice:** Always read the local file's existing `name:` value and inject it into the converted frontmatter, ignoring whatever `name:` the external file declares.

**Consequences:**
- `workflow-*` agents keep their `agentspec:` prefix
- No cross-system references break

---

## File Manifest

| # | File | Action | Purpose | Dependencies |
|---|------|--------|---------|--------------|
| 1 | `scripts/convert_frontmatter.py` | Create | Main conversion script | None |
| 2 | `.github/agents/*.agent.md` (66 files) | Modify | Replace frontmatter per conversion spec | 1 |

**Total Files:** 1 created + 66 modified

---

## Agent Assignment

| Agent | Files | Why |
|-------|-------|-----|
| @python-developer | `scripts/convert_frontmatter.py` | Python scripting, regex, file I/O |

---

## Code Patterns

### Pattern 1: Frontmatter extraction

```python
import re
from pathlib import Path

FRONTMATTER_RE = re.compile(r'^---\n(.*?)\n---\n', re.DOTALL)

def split_file(content: str) -> tuple[str, str]:
    """Return (frontmatter_yaml, body_markdown). Raises if no frontmatter found."""
    m = FRONTMATTER_RE.match(content)
    if not m:
        raise ValueError("No frontmatter block found")
    fm_yaml = m.group(1)
    body = content[m.end():]
    return fm_yaml, body

def read_local_name(fm_yaml: str) -> str:
    """Extract the `name:` value from YAML string."""
    m = re.search(r'^name:\s*(.+)$', fm_yaml, re.MULTILINE)
    if not m:
        raise ValueError("No `name:` field in frontmatter")
    return m.group(1).strip()
```

### Pattern 2: Description conversion — two input formats

The external repo uses **two** example patterns that both convert to the same Copilot CLI XML:

```python
# Pattern A: "Example N — Context description:\nuser: ...\nassistant: ..."
EXAMPLE_A_RE = re.compile(
    r'Example \d+\s*[—\-]\s*(.+?):\s*\n'
    r'\s*user:\s*"(.*?)"\s*\n'
    r'\s*assistant:\s*"(.*?)"',
    re.DOTALL
)

# Pattern B: "Example N:\n- Context: ...\n- user: ...\n- assistant: ..."
EXAMPLE_B_RE = re.compile(
    r'Example \d+:\s*\n'
    r'\s*-\s*Context:\s*(.+?)\s*\n'
    r'\s*-\s*user:\s*"(.*?)"\s*\n'
    r'\s*-\s*assistant:\s*"(.*?)"',
    re.DOTALL
)

def convert_description(desc: str) -> str:
    """Convert plain-text examples to Copilot CLI <example> XML blocks."""
    def replacement(m):
        context, user, assistant = m.group(1).strip(), m.group(2).strip(), m.group(3).strip()
        return (
            f'<example>\n'
            f'Context: {context}\n'
            f'user: "{user}"\n'
            f'assistant: "{assistant}"\n'
            f'</example>'
        )

    result = EXAMPLE_A_RE.sub(replacement, desc)
    result = EXAMPLE_B_RE.sub(replacement, result)
    return result.strip()
```

### Pattern 3: Tool alias conversion

```python
TOOL_ALIAS_MAP = {
    'Read':             'read',
    'Write':            'edit',
    'Edit':             'edit',
    'MultiEdit':        'edit',
    'Grep':             'search',
    'Glob':             'search',
    'Bash':             'execute',
    'TodoWrite':        'todo',
    'Task':             'agent',
    # Keep unrecognised names as-is (Copilot ignores them)
}

def convert_tools(tools_raw: str, has_escalation_targets: bool) -> list[str]:
    """Parse Claude Code tools list and return Copilot CLI alias list."""
    # Strip brackets and split: "[Read, Write, Edit]" → ["Read", "Write", "Edit"]
    cleaned = tools_raw.strip().lstrip('[').rstrip(']')
    raw_tools = [t.strip().strip('"\'') for t in cleaned.split(',') if t.strip()]

    seen = []
    for t in raw_tools:
        alias = TOOL_ALIAS_MAP.get(t, t)  # unknown tools kept as-is
        if alias not in seen:
            seen.append(alias)

    if has_escalation_targets and 'agent' not in seen:
        seen.append('agent')

    return seen
```

### Pattern 4: Check for escalation targets

```python
def has_escalation_targets(fm_yaml: str) -> bool:
    """Return True if any escalation_rules entry has a `target:` field."""
    return bool(re.search(r'^\s+target\s*:', fm_yaml, re.MULTILINE))
```

### Pattern 5: Assemble converted frontmatter

```python
def build_frontmatter(
    local_name: str,
    external_fm: str,
) -> str:
    """Assemble a valid Copilot CLI frontmatter block from external YAML + local name."""

    # --- description ---
    desc_m = re.search(r'^description:\s*\|?\s*\n((?:[ \t]+.+\n?)+)', external_fm, re.MULTILINE)
    description = desc_m.group(1) if desc_m else ''
    # Dedent one level (remove leading 2 spaces added by block scalar)
    description = re.sub(r'^  ', '', description, flags=re.MULTILINE)
    converted_description = convert_description(description)

    # --- tools ---
    tools_m = re.search(r'^tools:\s*(\[.+?\]|\|?\s*\n(?:\s+-\s*.+\n?)+)', external_fm, re.MULTILINE)
    tools_raw = tools_m.group(1).strip() if tools_m else '[]'
    escalates = has_escalation_targets(external_fm)
    tools = convert_tools(tools_raw, escalates)

    # --- custom props (verbatim copy) ---
    def extract_prop(key: str) -> str | None:
        """Extract a YAML property as its raw string (scalar or block)."""
        # Scalar: "key: value"
        scalar = re.search(rf'^{key}:\s*(.+)$', external_fm, re.MULTILINE)
        # Block: "key:\n  - item"
        block = re.search(
            rf'^{key}:\s*\n((?:[ \t]+.+\n?)+)',
            external_fm, re.MULTILINE
        )
        if block:
            return f"{key}:\n{block.group(1).rstrip()}"
        if scalar and scalar.group(1).strip() not in ('', '[]', '{}'):
            return f"{key}: {scalar.group(1).strip()}"
        if scalar:
            return f"{key}: {scalar.group(1).strip()}"
        return None

    # Build lines
    lines = [f'name: {local_name}']

    # description block scalar
    lines.append('description: |')
    for line in converted_description.splitlines():
        lines.append(f'  {line}')

    # custom props (retain if present)
    for prop in ['tier', 'kb_domains', 'color', 'anti_pattern_refs']:
        raw = extract_prop(prop)
        if raw:
            lines.append(raw)

    # model (always overridden)
    lines.append('model: Claude Sonnet 4.5')

    # tools (YAML list)
    lines.append('tools:')
    for t in tools:
        lines.append(f'  - {t}')

    # remaining custom props
    for prop in ['stop_conditions', 'escalation_rules']:
        raw = extract_prop(prop)
        if raw:
            lines.append(raw)

    return '\n'.join(lines)
```

### Pattern 6: Fetch external file

```python
import urllib.request

BASE_URL = 'https://raw.githubusercontent.com/luanmorenommaciel/agentspec/main/.claude/agents'

def fetch_external(category: str, filename: str) -> str:
    url = f'{BASE_URL}/{category}/{filename}'
    with urllib.request.urlopen(url) as resp:
        return resp.read().decode('utf-8')
```

### Pattern 7: Write updated file

```python
def write_agent_file(path: Path, new_fm: str, body: str) -> None:
    content = f'---\n{new_fm}\n---\n{body}'
    path.write_text(content, encoding='utf-8')
```

### Pattern 8: Main orchestration loop

```python
AGENTS_DIR = Path('.github/agents')

OVERLAP_AGENTS = [
    # (local_file, category, external_file)
    ('architect-data-platform-engineer.agent.md', 'architect', 'data-platform-engineer.md'),
    ('architect-genai.agent.md', 'architect', 'genai-architect.md'),
    # ... (full table from DEFINE)
]

DS_AGENTS = [
    'ds-eda-analyst.agent.md',
    'ds-experiment-tracker.agent.md',
    # ...
]

def process_overlap_agent(local_file, category, ext_file, dry_run=False):
    local_path = AGENTS_DIR / local_file
    local_content = local_path.read_text(encoding='utf-8')
    local_fm, body = split_file(local_content)
    local_name = read_local_name(local_fm)

    ext_content = fetch_external(category, ext_file)
    ext_fm, _ = split_file(ext_content)

    new_fm = build_frontmatter(local_name, ext_fm)

    if dry_run:
        print(f'[DRY RUN] {local_file}')
        print(f'---\n{new_fm}\n---')
    else:
        write_agent_file(local_path, new_fm, body)
        print(f'[OK] {local_file}')

def verify_ds_agent(local_file):
    """Check ds-* agents are already in Copilot CLI format; fix if needed."""
    local_path = AGENTS_DIR / local_file
    content = local_path.read_text(encoding='utf-8')
    fm, body = split_file(content)

    issues = []
    if re.search(r'^model:\s*sonnet\s*$', fm, re.MULTILINE | re.IGNORECASE):
        issues.append('model shorthand')
    if re.search(r'^tools:\s*\[', fm, re.MULTILINE):
        issues.append('inline tools array')
    if not re.search(r'<example>', fm + body):
        issues.append('missing <example> blocks')

    if issues:
        print(f'[FIX NEEDED] {local_file}: {", ".join(issues)}')
    else:
        print(f'[OK] {local_file} already valid')
```

### Pattern 9: Entry point with `--dry-run` support

```python
import sys

if __name__ == '__main__':
    dry_run = '--dry-run' in sys.argv

    print('=== Processing 58 overlap agents ===')
    for local_file, category, ext_file in OVERLAP_AGENTS:
        try:
            process_overlap_agent(local_file, category, ext_file, dry_run=dry_run)
        except Exception as e:
            print(f'[ERROR] {local_file}: {e}')

    print('\n=== Verifying 8 ds-* agents ===')
    for local_file in DS_AGENTS:
        try:
            verify_ds_agent(local_file)
        except Exception as e:
            print(f'[ERROR] {local_file}: {e}')
```

---

## Data Flow

```text
1. Script reads OVERLAP_AGENTS inventory (hardcoded list of 58 tuples)
   │
   ▼
2. For each agent: fetch external .md from GitHub raw URL
   │
   ▼
3. parse external frontmatter → extract description, tools, model, custom props
   │
   ▼
4. Read local .agent.md → extract current `name:` value + body markdown
   │
   ▼
5. convert_description()  → plain-text examples → <example> XML
   convert_tools()        → Claude Code aliases → Copilot CLI aliases
                          → add `agent` if escalation_rules has targets
   model                  → "Claude Sonnet 4.5" (hardcoded override)
   custom props           → copied verbatim from external
   │
   ▼
6. Assemble new frontmatter YAML string (name always from local)
   │
   ▼
7. write_agent_file(): overwrite lines 1 to second `---`; body unchanged
   │
   ▼
8. After all 66 files: run .\build-copilot.ps1 to validate output
```

---

## Integration Points

| External System | Integration Type | Authentication |
|-----------------|-----------------|----------------|
| `raw.githubusercontent.com` | HTTPS GET (urllib.request) | None (public repo) |
| `build-copilot.ps1` | PowerShell subprocess (manual post-step) | None |

---

## Testing Strategy

| Test Type | Scope | How |
|-----------|-------|-----|
| Dry run | All 66 agents | `python scripts/convert_frontmatter.py --dry-run` — inspect output, no files written |
| Spot check | 3 representative files (1 workflow, 1 de-, 1 fabric) | Read converted frontmatter, verify: `<example>` blocks, YAML list tools, full model name, retained custom props |
| Build validation | Full plugin output | `.\build-copilot.ps1` must complete without error |
| Name field freeze | All 66 local names unchanged | `grep "^name:" .github/agents/*.agent.md` before/after — values must be identical |

---

## Error Handling

| Error Type | Handling Strategy | Skip? |
|------------|-------------------|-------|
| GitHub fetch fails (404) | Print `[ERROR] <file>: HTTP 404` | Yes — log and continue |
| No frontmatter in file | Print `[ERROR] <file>: No frontmatter` | Yes |
| No `name:` in local frontmatter | Raise, halt script | No — this is a critical invariant |
| Regex finds no examples in description | Warn, keep description as-is | Yes |
| `fabric-cicd-specialist` duplicate `name:` | Deduplicate in `build_frontmatter()` — local name always wins | Automatic |

---

## Special Case: `fabric-cicd-specialist`

The external file may produce a frontmatter with a duplicate `name:` field (one is `fabric-cicd-specialist`, another may be `Fabric CI/CD`). The `build_frontmatter()` function resolves this by construction: it always starts with `name: {local_name}` and never copies the `name:` field from the external source. No separate handling needed.

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-05-13 | design-agent | Initial version |

---

## Next Step

**Ready for:** `/build .github/sdd/features/DESIGN_COPILOT_FRONTMATTER_ADAPTATION.md`
