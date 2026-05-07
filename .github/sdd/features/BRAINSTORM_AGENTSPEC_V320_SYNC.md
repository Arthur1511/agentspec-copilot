# BRAINSTORM: AgentSpec v3.2.0 Upstream Sync

> Exploratory session to clarify intent and approach before requirements capture

## Metadata

| Attribute | Value |
|-----------|-------|
| **Feature** | AGENTSPEC_V320_SYNC |
| **Date** | 2026-05-07 |
| **Author** | brainstorm-agent |
| **Status** | Ready for Define |

---

## Initial Idea

**Raw Input:** Read https://github.com/luanmorenommaciel/agentspec changelog.md and adapt all new changes to work on Copilot CLI.

**Context Gathered:**
- Our fork (Arthur1511/agentspec-copilot) is based on upstream v3.0.0/3.1.0 with v3.1.0 items partially ported in [Unreleased]
- Upstream is now at v3.2.0 (released 2026-05-01)
- Copilot CLI fork path convention: `.github/` (not `.claude/`), `${COPILOT_PLUGIN_ROOT}` (not `${CLAUDE_PLUGIN_ROOT}`)
- Agents are in a **flat** `.github/agents/` directory (no category subdirs) — differs from upstream
- SessionStart hooks ARE supported in Copilot CLI via `hooks.json`
- Current `hooks.json` uses inline bash/powershell (not an external script)
- Our fork has 35 skills, 58 agents, 24 KB domains

**Technical Context Observed:**

| Aspect | Observation | Implication |
|--------|-------------|-------------|
| Path convention | `.github/` not `.claude/` | All paths must be rewritten |
| Agent structure | Flat `.github/agents/*.agent.md` | Override resolution differs from upstream (no category subdirs) |
| Plugin root | `${COPILOT_PLUGIN_ROOT}` | Replace `${CLAUDE_PLUGIN_ROOT}` everywhere |
| Hooks | `hooks.json` with inline commands | Refactor to call `scripts/init-workspace.sh` |
| Build scripts | `build-copilot.sh` + `build-copilot.ps1` | Need Step 0 for agent-router generation |

---

## Discovery Questions & Answers

| # | Question | Answer | Impact |
|---|----------|--------|--------|
| 1 | What scope — full v3.2.0 sync or selective? | Full sync (v3.2.0 + any v3.1.0 gaps) | All 14 delta items must be implemented |
| 2 | How should Judge Layer be adapted (skill vs script)? | Adapt as a skill (`review-judge`) | Creates `skills/review-judge/SKILL.md` wrapping `scripts/judge.py` |
| 3 | Cross-platform Makefile? | Yes — Windows and Linux/macOS | Makefile targets invoke `build-copilot.sh` or `build-copilot.ps1` |
| 4 | Samples / reference data? | Use current repo structure as reference | Existing skills (e.g., `review-code`) are the template |
| 5 | Does Copilot CLI have SessionStart hooks? | Yes — `hooks.json` already has one | `init-workspace.sh` script should be created and hooks.json updated |

---

## Sample Data Inventory

| Type | Location | Count | Notes |
|------|----------|-------|-------|
| Existing skill format | `.github/skills/review-code/SKILL.md` | 1 | Template for `review-judge` skill |
| Existing hooks | `.github/hooks/hooks.json` | 1 | Template for updated hook |
| Upstream judge.py | `luanmorenommaciel/agentspec:scripts/judge.py` | 1 | Adapt `.claude/storage` → `.github/storage` |
| Upstream init-workspace.sh | `plugin-extras/scripts/init-workspace.sh` | 1 | Adapt stack detection + agent overrides for flat agent structure |
| Upstream CI workflow | `.github/workflows/quality-checks.yml` | 1 | Update paths for Copilot CLI fork |

---

## Approaches Explored

### Approach A: Full direct adaptation ⭐ Recommended

**Description:** Adapt all 14 delta items directly in `.github/` source. Rebuild with `build-copilot.ps1` to validate. One logical changeset.

**Pros:**
- Complete v3.2.0 parity in one pass
- All related changes land together — easier to verify
- Single CHANGELOG entry

**Cons:**
- Large changeset (14 files/dirs to create or update)
- Needs careful review per item

**Why Recommended:** All changes are independent — no sequencing issues. The user has confirmed scope and approach. Doing it in one pass avoids an incomplete intermediate state.

---

### Approach B: Split into two phases

**Description:** Phase 1 (infrastructure: judge.py, Makefile, CI, build scripts), Phase 2 (docs, agent overrides, version bumps).

**Pros:**
- Smaller, safer PRs
- Can ship infrastructure earlier

**Cons:**
- Incomplete state between phases (e.g., judge.py exists but no judge-setup.md)
- More coordination overhead

---

### Approach C: Scripts-only, skip docs

**Description:** Only ship code files — skip documentation adaptations.

**Not recommended** — `agent-overrides.md` and `judge-setup.md` are what users actually interact with; skipping them leaves incomplete features.

---

## Selected Approach

| Attribute | Value |
|-----------|-------|
| **Chosen** | Approach A |
| **User Confirmation** | 2026-05-07 (interactive session) |
| **Reasoning** | Full sync in one pass. All 14 items are independent; no sequencing risk. |

---

## Key Decisions Made

| # | Decision | Rationale | Alternative Rejected |
|---|----------|-----------|----------------------|
| 1 | Agent overrides use flat structure (no category subdirs) | Matches our fork's existing flat `.github/agents/` convention | Upstream categorized subdirs — doesn't fit our structure |
| 2 | Judge as a `review-judge` skill | Copilot CLI uses skills instead of slash commands | Standalone script only — less discoverable |
| 3 | `init-workspace.sh` adapted in `scripts/` | Consistent with upstream; Copilot CLI hooks.json can invoke scripts | Keep inline bash in hooks.json — too complex to maintain inline |
| 4 | Makefile cross-platform | Windows is primary dev environment for this fork | bash-only Makefile would break Windows contributors |
| 5 | WORKFLOW_CONTRACTS.yaml bumped to 3.2.0 | Accurate version tracking for downstream consumers | Keep at 3.0.0 — misleading |

---

## Features Removed (YAGNI)

| Feature Suggested | Reason Removed | Can Add Later? |
|-------------------|----------------|----------------|
| `init-workspace.sh` auto-creating `.github/agents/custom/` | Copilot CLI projects don't use category subdirs for agent overrides — agent override docs explain the flat pattern | Yes |
| `--judge` flag on `/define`, `/design`, `/build` | Copilot CLI doesn't have slash commands; the `review-judge` skill covers the use case | Yes (if flag system ships for Copilot CLI) |
| `routing.json` regeneration in hooks.json | Happens at build time, not session start | Yes |

---

## Incremental Validations

| Section | Presented | User Feedback | Adjusted? |
|---------|-----------|---------------|-----------|
| Delta scope (14 items) | ✅ | "Add something I'm missing" — SessionStart hook | Yes — added init-workspace.sh + hooks.json update |
| Approach selection | ✅ | Selected Approach A | No |

---

## Full Delta — 14 Items to Implement

### New Files
1. `scripts/judge.py` — adapt from upstream (`.claude/storage` → `.github/storage` path for ledger)
2. `scripts/init-workspace.sh` — adapt from upstream `plugin-extras/scripts/init-workspace.sh` (flat agent dirs, `.github/` paths)
3. `.shellcheckrc` — copy as-is from upstream
4. `Makefile` — adapt (use `build-copilot.sh/ps1`, Copilot CLI targets)
5. `.github/workflows/quality-checks.yml` — adapt (update paths `.claude/agents/**` → `.github/agents/**`, shell scripts for this fork)
6. `.github/skills/review-judge/SKILL.md` — new skill adapted from `.claude/commands/review/judge.md`
7. `docs/concepts/agent-overrides.md` — adapt (flat agent structure, `.github/` paths, `${COPILOT_PLUGIN_ROOT}`)
8. `docs/getting-started/judge-setup.md` — adapt (update storage path, Copilot CLI invocation)

### Updated Files
9. `.github/hooks/hooks.json` — call `scripts/init-workspace.sh` instead of inline commands
10. `.github/sdd/architecture/WORKFLOW_CONTRACTS.yaml` — bump to 3.2.0, add `agent_resolution` contract
11. `.github/manifest.yaml` — bump `agentspec.version` to 3.2.0, skills `35 → 36`
12. `build-copilot.sh` — add Step 0 (run `python3 scripts/generate-agent-router.py`)
13. `build-copilot.ps1` — add Step 0 (run `python scripts/generate-agent-router.py`)
14. `CHANGELOG.md` — add v3.2.0 section

---

## Suggested Requirements for /define

### Problem Statement (Draft)
Port all upstream v3.2.0 changes from `luanmorenommaciel/agentspec` to the Copilot CLI fork, adapting Claude Code-specific paths and mechanisms to Copilot CLI conventions.

### Target Users (Draft)
| User | Pain Point |
|------|------------|
| Fork maintainers | Need parity with upstream to benefit from new features |
| Fork users | Want Judge Layer for cross-model review, agent overrides for customization |

### Success Criteria (Draft)
- [ ] `scripts/judge.py` runs and writes ledger to `.github/storage/judge-ledger.jsonl`
- [ ] `review-judge` skill is discoverable and invocable
- [ ] `scripts/init-workspace.sh` creates `.github/sdd/` dirs and detects stack
- [ ] `hooks.json` calls init script (bash + PowerShell paths)
- [ ] `make build` runs full Copilot CLI build (calls `build-copilot.sh`)
- [ ] CI workflow triggers on agent changes and validates router drift
- [ ] WORKFLOW_CONTRACTS.yaml at 3.2.0 with `agent_resolution` contract
- [ ] `manifest.yaml` reflects 3.2.0, 36 skills

### Constraints Identified
- Agents are flat (no category subdirs) — agent override paths differ from upstream
- Windows primary — all scripts must have both bash and PowerShell paths where needed
- No slash commands in Copilot CLI — judge is a skill, not a command

### Out of Scope (Confirmed)
- `--judge` flag on SDD phase commands (slash command pattern, not available in Copilot CLI)
- Auto-scaffolding of `.github/agents/custom/` (not needed for flat structure)

---

## Session Summary

| Metric | Value |
|--------|-------|
| Questions Asked | 5 |
| Approaches Explored | 3 |
| Features Removed (YAGNI) | 3 |
| Validations Completed | 2 |
| Selected Approach | A — Full direct adaptation |

---

## Next Step

**Ready for:** `/define .github/sdd/features/BRAINSTORM_AGENTSPEC_V320_SYNC.md`

Or proceed directly to implementation — all decisions are locked.
