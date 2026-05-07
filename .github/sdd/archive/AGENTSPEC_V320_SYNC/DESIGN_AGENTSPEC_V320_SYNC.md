# DESIGN: AgentSpec v3.2.0 Upstream Sync

> Technical design for porting all upstream v3.2.0 changes from `luanmorenommaciel/agentspec` to the Copilot CLI fork.

## Metadata

| Attribute | Value |
|-----------|-------|
| **Feature** | AGENTSPEC_V320_SYNC |
| **Date** | 2026-05-07 |
| **Author** | design-agent |
| **DEFINE** | [DEFINE_AGENTSPEC_V320_SYNC.md](./DEFINE_AGENTSPEC_V320_SYNC.md) |
| **Status** | ✅ Shipped |

---

## Architecture Overview

```text
┌──────────────────────────────────────────────────────────────────────────┐
│                     AgentSpec v3.2.0 Sync — Delivery Map                 │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────────── Group 1: Scripts ──────────────────────────┐   │
│  │  scripts/judge.py           — Judge Layer V0 (LEDGER path adapted) │   │
│  │  scripts/init-workspace.sh  — Workspace init + stack detection     │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────────────── Group 2: Config ───────────────────────────┐   │
│  │  .shellcheckrc              — ShellCheck config (shell=bash)       │   │
│  │  Makefile                   — Contributor tooling entry point      │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────── Group 3: Skills & Docs (New) ──────────────────────┐   │
│  │  .github/skills/review-judge/SKILL.md  — Skill wrapping judge.py  │   │
│  │  docs/concepts/agent-overrides.md      — Override docs (flat)     │   │
│  │  docs/getting-started/judge-setup.md   — Setup guide              │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────── Group 4: Updates to Existing Files ────────────────┐   │
│  │  .github/hooks/hooks.json              — Call init-workspace.sh   │   │
│  │  .github/sdd/architecture/WORKFLOW_CONTRACTS.yaml — v3.2.0        │   │
│  │  .github/manifest.yaml                 — version + skills count   │   │
│  │  build-copilot.sh                      — Step 0 agent-router gen  │   │
│  │  build-copilot.ps1                     — Step 0 agent-router gen  │   │
│  │  CHANGELOG.md                          — [3.2.0] entry            │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  Runtime flow:                                                             │
│  Session Start → hooks.json → init-workspace.sh                           │
│                → creates .github/sdd/{features,reports,archive}/          │
│                → creates .github/agents/custom/ (flat, no subdirs)        │
│                → writes .github/sdd/.detected-stack.md                    │
│                                                                           │
│  User invokes review-judge skill → scripts/judge.py → OpenRouter          │
│                → PASS/FAIL verdict → ledger appended to                   │
│                   .github/storage/judge-ledger.jsonl                      │
│                                                                           │
│  Build: build-copilot.sh → Step 0: generate-agent-router.py              │
│         → Step 1-7: existing copy + path rewrite → plugin-copilot/       │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Components

| Component | Purpose | Location |
|-----------|---------|----------|
| `judge.py` | Cross-model second opinion via OpenRouter | `scripts/judge.py` |
| `init-workspace.sh` | Idempotent workspace init + stack detection | `scripts/init-workspace.sh` |
| `review-judge` skill | Copilot CLI wrapper that invokes judge.py | `.github/skills/review-judge/SKILL.md` |
| `Makefile` | Contributor tooling (build, test, lint, clean) | `Makefile` (repo root) |
| `.shellcheckrc` | ShellCheck config for all shell scripts | `.shellcheckrc` (repo root) |
| `hooks.json` | SessionStart hook calling init-workspace.sh | `.github/hooks/hooks.json` |
| `WORKFLOW_CONTRACTS.yaml` | SDD contracts + agent resolution spec | `.github/sdd/architecture/` |
| `agent-overrides.md` | How to create local flat-structure overrides | `docs/concepts/` |
| `judge-setup.md` | First-time setup guide for the Judge skill | `docs/getting-started/` |

---

## Key Decisions

### Decision 1: judge.py LEDGER path — `.github/storage/` not `.claude/storage/`

| Attribute | Value |
|-----------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-07 |

**Context:** Upstream stores the judge ledger at `.claude/storage/judge-ledger.jsonl`. Copilot CLI fork uses `.github/` as the plugin root.

**Choice:** Change `LEDGER = REPO_ROOT / ".claude" / "storage" / "judge-ledger.jsonl"` to `REPO_ROOT / ".github" / "storage" / "judge-ledger.jsonl"`. No other changes to judge.py.

**Rationale:** The `scripts/` directory is NOT inside `.github/` so it does not get path-rewritten by the build scripts. The LEDGER constant is the single touch-point. All other logic (OpenRouter API, verdict format, budget enforcement, exit codes) is platform-neutral.

**Alternatives Rejected:**
1. Environment variable for LEDGER path — unnecessary complexity; `.github/storage/` is the canonical location for the fork.

**Consequences:**
- One-line diff from upstream; trivially auditable on future upstream syncs.

---

### Decision 2: init-workspace.sh — flat agent structure, no category dirs

| Attribute | Value |
|-----------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-07 |

**Context:** Upstream creates `.claude/agents/workflow/` and `.claude/agents/custom/` (categorized). Copilot CLI fork uses a flat `.github/agents/*.agent.md` structure.

**Choice:** Create only `.github/agents/custom/` — one directory, no `workflow/` subdirectory. The README explains the flat-structure override pattern.

**Rationale:** Copilot CLI resolves agents from a flat directory by `name:` frontmatter. Categorized subdirs add no value and would confuse users about where to put overrides.

**Alternatives Rejected:**
1. Mirror upstream's `workflow/` + `custom/` structure — breaks flat-first resolution convention.

**Consequences:**
- Simpler agent override docs; users only need one folder.

---

### Decision 3: Project detection in init-workspace.sh

| Attribute | Value |
|-----------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-07 |

**Context:** Upstream detects AgentSpec-aware projects by looking for `.git`, `CLAUDE.md`, or `.claude/`. Copilot CLI fork has no `CLAUDE.md`.

**Choice:** Detect by `.git`, `copilot-instructions.md`, or `.github/` — all three are Copilot CLI idioms.

**Rationale:** `copilot-instructions.md` is the Copilot CLI equivalent of `CLAUDE.md`. `.github/` presence signals a GitHub-aware project. Either signals that workspace init is appropriate.

**Consequences:**
- init-workspace.sh behaves identically to upstream in git repos; broader in non-git GitHub projects.

---

### Decision 4: review-judge as a skill, not a slash command

| Attribute | Value |
|-----------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-07 |

**Context:** Upstream ships judge as `/judge` slash command. Copilot CLI has no slash command mechanism — all user-invocable tools are skills.

**Choice:** Create `.github/skills/review-judge/SKILL.md` adapting the upstream judge.md command format to Copilot CLI skill format.

**Rationale:** Settled in Brainstorm. Skills are the Copilot CLI equivalent of slash commands. The skill invokes `python3 scripts/judge.py` (or the built-in `${COPILOT_PLUGIN_ROOT}/scripts/judge.py`).

**Consequences:**
- Skill count goes from 35 → 36. manifest.yaml must be updated.

---

### Decision 5: Build Step 0 placement — before Step 1 (Clean)

| Attribute | Value |
|-----------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-07 |

**Context:** The agent-router generator updates `.github/skills/agent-router/SKILL.md` and `routing.json`. These files must be current before Step 1 (which copies `.github/skills/` into `plugin-copilot/`).

**Choice:** Insert Step 0 as the very first step in both build scripts, before Step 1 (Clean) and before Step 2 (Copy).

**Rationale:** If the router is stale, it must be regenerated first so the fresh output is copied. Running it after cleaning would work too, but running before clean is idempotent and matches upstream convention.

**Alternatives Rejected:**
1. Run after copy (Step 2.5) — regenerated files would need a second copy pass.

**Consequences:**
- Build takes slightly longer (generator is fast, ~1-2s). Zero functional risk.

---

## File Manifest

| # | File | Action | Purpose | Agent | Dependencies |
|---|------|--------|---------|-------|--------------|
| 1 | `scripts/judge.py` | Create | Cross-model verdict via OpenRouter; LEDGER → `.github/storage/` | general | None |
| 2 | `scripts/init-workspace.sh` | Create | Idempotent workspace init + stack detection; flat `.github/agents/custom/` | general | None |
| 3 | `.shellcheckrc` | Create | ShellCheck config shared by all shell scripts | general | None |
| 4 | `Makefile` | Create | Contributor tooling; `build` → `build-copilot.sh`; `lint` → fork scripts | general | 2, 3 |
| 5 | `.github/skills/review-judge/SKILL.md` | Create | Copilot CLI skill wrapping judge.py | general | 1 |
| 6 | `docs/concepts/agent-overrides.md` | Create | Flat-structure agent override guide | general | 2 |
| 7 | `docs/getting-started/judge-setup.md` | Create | Judge setup guide (`.github/storage`, skill invocation) | general | 1, 5 |
| 8 | `.github/hooks/hooks.json` | Update | Call `scripts/init-workspace.sh` (bash + powershell) | general | 2 |
| 9 | `.github/sdd/architecture/WORKFLOW_CONTRACTS.yaml` | Update | Version 3.2.0 + `agent_resolution` section | general | None |
| 10 | `.github/manifest.yaml` | Update | `agentspec.version: "3.2.0"`, `skills: 36` | general | 5 |
| 11 | `build-copilot.sh` | Update | Step 0: `python3 scripts/generate-agent-router.py` | general | None |
| 12 | `build-copilot.ps1` | Update | Step 0: `python scripts/generate-agent-router.py` | general | None |
| 13 | `CHANGELOG.md` | Update | Add `## [3.2.0] - 2026-05-07` section | general | 1–12 done |

**Total Files:** 13

---

## Code Patterns

### Pattern 1: scripts/judge.py — Key Adaptation

The only change from upstream is the `LEDGER` constant (line ~70 in upstream):

```python
# UPSTREAM (do NOT keep):
LEDGER = REPO_ROOT / ".claude" / "storage" / "judge-ledger.jsonl"

# FORK (change to):
LEDGER = REPO_ROOT / ".github" / "storage" / "judge-ledger.jsonl"
```

All other constants, classes, functions, and main() are unchanged:

```python
REPO_ROOT = Path(__file__).resolve().parent.parent
LEDGER = REPO_ROOT / ".github" / "storage" / "judge-ledger.jsonl"
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
DEFAULT_MODEL = "openai/gpt-4o-mini"
DEFAULT_BUDGET = 10

PHASE_MODEL_DEFAULTS: dict[str, str] = {
    "generic": "openai/gpt-4o-mini",
    "define":  "openai/gpt-4o",
    "design":  "openai/gpt-4o",
    "build":   "openai/gpt-4o",
}
```

---

### Pattern 2: scripts/init-workspace.sh — Key Adaptations

**Detection:** Use Copilot CLI identifiers instead of Claude Code identifiers:
```bash
# UPSTREAM detects:
if [[ -d ".git" ]] || [[ -f "CLAUDE.md" ]] || [[ -d ".claude" ]]; then

# FORK detects:
if [[ -d ".git" ]] || [[ -f "copilot-instructions.md" ]] || [[ -d ".github" ]]; then
```

**Workspace dirs:** Use `.github/` instead of `.claude/`:
```bash
# FORK:
mkdir -p .github/sdd/features || true
mkdir -p .github/sdd/reports  || true
mkdir -p .github/sdd/archive  || true
```

**Agent overrides scaffold:** Flat structure only (no `workflow/` subdir):
```bash
# FORK: only .github/agents/custom/ — no category subdirs
mkdir -p .github/agents/custom 2>/dev/null || true

# Write README only on first run:
local readme=".github/agents/README.md"
if [[ -f "$readme" ]]; then return 0; fi
```

**README content** — adapted for flat structure:
```markdown
# Local Agents — Override AgentSpec

Agents in this directory **take precedence over AgentSpec plugin agents**
of the same name. Use this to customize agents to your project's
conventions without forking the plugin.

## Layout

| Folder | Purpose |
|--------|---------|
| `custom/` | New project-specific agents (or overrides with matching `name:` field) |

## Override an AgentSpec agent

1. Find the plugin agent at `${COPILOT_PLUGIN_ROOT}/agents/<name>.agent.md`
2. Copy it to `.github/agents/<name>.agent.md` — keep the `name:` field identical
3. Edit freely; your version runs instead of the plugin agent

## Resolution Order

```text
.github/agents/<name>.agent.md   (your local override — wins)
        ↓ if absent
${COPILOT_PLUGIN_ROOT}/agents/<name>.agent.md   (AgentSpec plugin)
```

This is enforced by Copilot CLI's native plugin loader. No config required.
```

**Stack detection output:** Write to `.github/sdd/.detected-stack.md` (not `.claude/sdd/`):
```bash
cat > ".github/sdd/.detected-stack.md" <<STACKEOF
# Detected Project Stack
...
STACKEOF
```

**Agent references in detected-stack.md:** Use Copilot CLI agent names (prefix-based):
- `dbt-specialist` → `de-dbt-specialist`
- `spark-engineer` → `de-spark-engineer`
- `airflow-specialist` → `de-airflow-specialist`
- `lakeflow-specialist` → `de-lakeflow-specialist`
- `fabric-architect` → `fabric-architect` (unchanged)
- `supabase-specialist` → `cloud-supabase-specialist`
- `data-platform-engineer` → `architect-data-platform-engineer`
- `data-quality-analyst` → `test-data-quality-analyst`
- `data-contracts-engineer` → `test-data-contracts-engineer`

---

### Pattern 3: .shellcheckrc

```ini
shell=bash
disable=SC1091,SC2155
```

- `SC1091`: Don't follow sourced files (common with CI environment scripts)
- `SC2155`: Declare and assign separately — too noisy for our scripting style

---

### Pattern 4: Makefile — Copilot CLI adaptation

```makefile
SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help
.PHONY: help build test check lint clean generate install-deps

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

build: ## Full plugin build (regenerate agent-router + package)
	@./build-copilot.sh
	@echo "Windows: run .\build-copilot.ps1 for PowerShell equivalent"

check: ## Drift check — agent-router in --check mode (fails on drift)
	@python3 scripts/generate-agent-router.py --check

generate: ## Regenerate agent-router artifacts (SKILL.md + routing.json)
	@python3 scripts/generate-agent-router.py

lint: ## Lint shell scripts via shellcheck
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -S warning \
			build-copilot.sh \
			scripts/init-workspace.sh \
			.github/skills/visual-explainer/scripts/share.sh; \
	else \
		echo "shellcheck not installed — brew install shellcheck / apt install shellcheck"; \
		exit 0; \
	fi

clean: ## Remove generated plugin-copilot/ artifacts (keep .claude-plugin/)
	@find plugin-copilot -mindepth 1 -maxdepth 1 \
		! -name '.claude-plugin' \
		! -name 'README.md' \
		-exec rm -rf {} + 2>/dev/null || true

install-deps: ## Install optional dev dependencies
	@python3 -m pip install --user pytest
	@echo "For shellcheck: brew install shellcheck (macOS) or apt install shellcheck (Linux)"
```

Note: No `test` target (no pytest suite exists yet in this fork). No `plugin` alias needed.

---

### Pattern 5: .github/skills/review-judge/SKILL.md

```markdown
---
name: review-judge
description: Cross-model second opinion via OpenRouter — catches hallucinations Copilot's self-review misses
---

# Review Judge Skill

> Get a second opinion from a non-Copilot model on code or content just produced.

## Usage

Invoke this skill when you want a cross-model review of a file:

```
"Use review-judge to review migrations/add_user_roles.sql"
"Run the judge on this Terraform module with context: least-privilege IAM for Lambda"
```

## What This Skill Does

Sends the target file + optional context to a non-Copilot model via OpenRouter.

| Field | Meaning |
|-------|---------|
| **Verdict** | `PASS` or `FAIL` |
| **Confidence** | 0.0 – 1.0 |
| **Concerns** | Severity-tagged issues with evidence |
| **Suggested fixes** | Concrete repairs |

Ledger entry appended to `.github/storage/judge-ledger.jsonl`.

## Execution

```bash
python3 scripts/judge.py <file> [--context "..."] [--model MODEL]
python3 scripts/judge.py --ledger
```

## Setup

See `docs/getting-started/judge-setup.md`.
```

---

### Pattern 6: hooks.json update

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "type": "command",
        "bash": "bash scripts/init-workspace.sh 2>/dev/null || true",
        "powershell": "if (Get-Command bash -ErrorAction SilentlyContinue) { bash scripts/init-workspace.sh 2>$null } elseif (Test-Path 'scripts/init-workspace.sh') { Write-Host '[AgentSpec] Run bash scripts/init-workspace.sh manually to initialize workspace' }",
        "timeoutSec": 30
      }
    ]
  }
}
```

**Rationale:** PowerShell environments with bash available (WSL, Git Bash) run the script. Pure Windows without bash falls back gracefully.

---

### Pattern 7: WORKFLOW_CONTRACTS.yaml — agent_resolution section

Add after the existing `ship:` section and before any terminal sections:

```yaml
# =============================================================================
# AGENT RESOLUTION (v3.2.0)
# =============================================================================

agent_resolution:
  description: "How Copilot CLI resolves agents — local overrides take precedence over plugin agents"
  version: "3.2.0"

  structure:
    type: "flat"
    path: ".github/agents/"
    pattern: "*.agent.md"
    note: "All 58 agents in a single directory; category encoded in filename prefix"

  prefixes:
    workflow: "workflow-*"
    architect: "architect-*"
    cloud: "cloud-*"
    fabric: "fabric-*"
    python: "python-*"
    test: "test-*"
    data_engineering: "de-*"
    developer: "dev-*"

  resolution_order:
    - priority: 1
      location: ".github/agents/<name>.agent.md"
      description: "Local project override — always wins"
      note: "name: frontmatter field must match plugin agent name exactly"
    - priority: 2
      location: "${COPILOT_PLUGIN_ROOT}/agents/<name>.agent.md"
      description: "AgentSpec plugin agent — fallback"

  custom_agents:
    location: ".github/agents/"
    naming: "Any .agent.md file not matching a plugin agent name"
    recommendation: "Use prefix custom- to avoid collision: custom-<name>.agent.md"

  scaffold:
    command: "bash scripts/init-workspace.sh"
    creates:
      - ".github/agents/custom/"
      - ".github/agents/README.md"
    note: "Run once per project. SessionStart hook calls this automatically."
```

---

### Pattern 8: build-copilot.sh Step 0 insertion

Insert immediately after the preflight block (after the `info "Building AgentSpec Copilot CLI plugin..."` line):

```bash
# --- Step 0: Generate agent-router artifacts ---------------------------------

info "Generating agent-router artifacts..."
if ! python3 scripts/generate-agent-router.py; then
    error "Agent-router generation failed. Fix the error above and re-run."
    exit 1
fi
ok "Agent-router generated"
```

### Pattern 9: build-copilot.ps1 Step 0 insertion

Insert at the same position (after `Write-Info "Building AgentSpec Copilot CLI plugin..."`):

```powershell
# --- Step 0: Generate agent-router artifacts ----------------------------------

Write-Info "Generating agent-router artifacts..."
$result = & python scripts/generate-agent-router.py
if ($LASTEXITCODE -ne 0) {
    Write-Err "Agent-router generation failed. Fix the error above and re-run."
    exit 1
}
Write-Ok "Agent-router generated"
```

---

## Data Flow

```text
1. Developer session starts
   │
   ▼
2. hooks.json triggers init-workspace.sh
   │  creates: .github/sdd/{features,reports,archive}/
   │  creates: .github/agents/custom/  (first run only)
   │  writes:  .github/sdd/.detected-stack.md
   ▼
3. Developer works — produces a file to review
   │
   ▼
4. User invokes review-judge skill
   │  skill reads: target file
   ▼
5. scripts/judge.py executes
   │  reads: OPENROUTER_API_KEY env var
   │  sends: file content + system prompt to OpenRouter
   │  writes: PASS/FAIL verdict to stdout
   │  appends: ledger entry to .github/storage/judge-ledger.jsonl
   ▼
6. Verdict rendered in chat

Developer builds plugin:
   │
   ▼
7. make build → ./build-copilot.sh
   │
   ▼
8. Step 0: python3 scripts/generate-agent-router.py
   │  updates: .github/skills/agent-router/SKILL.md
   │  updates: .github/skills/agent-router/routing.json
   ▼
9. Steps 1-7: copy + rewrite + verify → plugin-copilot/
```

---

## Integration Points

| External System | Integration Type | Authentication |
|-----------------|-----------------|----------------|
| OpenRouter API | HTTPS REST | `OPENROUTER_API_KEY` env var |
| GitHub Copilot CLI | Skill invocation | Built-in (Copilot CLI session) |
| ShellCheck | CLI tool (lint) | None (local install) |

---

## Testing Strategy

| Test Type | Scope | Files | Tools | Coverage Goal |
|-----------|-------|-------|-------|---------------|
| Manual AT-001 | Judge `--ledger` | `scripts/judge.py` | Manual | Exit 0, no API key required |
| Manual AT-002 | Judge config error | `scripts/judge.py` | Manual | Exit 2 without API key |
| Manual AT-003 | Init idempotent | `scripts/init-workspace.sh` | Manual | No error on re-run |
| Manual AT-004 | Build Step 0 | `build-copilot.sh` | Manual | Router regenerated |
| Manual AT-005 | Router drift CI | `.github/workflows/quality-checks.yml` | CI | Fails with diff |
| Manual AT-006 | hooks.json init | `.github/hooks/hooks.json` | Session start | Dirs created |
| Manual AT-008 | Manifest count | `.github/manifest.yaml` | `cat` | Shows `skills: 36` |

---

## Error Handling

| Error Type | Handling Strategy | Retry? |
|------------|-------------------|--------|
| `OPENROUTER_API_KEY` missing | judge.py exits with code 2, clear message | No |
| Daily budget exceeded | judge.py exits with code 3, ledger shows count | No |
| OpenRouter network error | judge.py exits with code 4, prints error | No |
| Init script not found | hooks.json bash command returns `|| true` — silent | No |
| Agent-router generation fails | build scripts exit with error, build halts | No |
| ShellCheck not installed | Makefile lint target prints install hint, exits 0 | No |

---

## Security Considerations

- `OPENROUTER_API_KEY` is read from environment variable, never hardcoded
- judge-ledger.jsonl stores only metadata (date, model, verdict, cost_usd) — no file contents
- `.github/storage/` is local-only; not committed (add to `.gitignore` if sensitive)
- init-workspace.sh is idempotent and uses `|| true` guards — cannot corrupt workspace on partial failure
- No elevated privileges required anywhere

---

## Configuration

| Config Key | Type | Default | Description |
|------------|------|---------|-------------|
| `OPENROUTER_API_KEY` | env string | None (required) | OpenRouter API key for judge.py |
| `JUDGE_MODEL` | env string | `openai/gpt-4o-mini` | Override default model |
| `JUDGE_BUDGET` | env int | `10` | Max judge calls per UTC day |

---

## Observability

| Aspect | Implementation |
|--------|----------------|
| Judge ledger | Append-only JSONL at `.github/storage/judge-ledger.jsonl` |
| Stack detection | `.github/sdd/.detected-stack.md` written at session start |
| Build summary | `build-copilot.sh` prints agent/skill/KB counts at end |

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-05-07 | design-agent | Initial version |

---

## Next Step

**Ready for:** `/build .github/sdd/features/DESIGN_AGENTSPEC_V320_SYNC.md`
