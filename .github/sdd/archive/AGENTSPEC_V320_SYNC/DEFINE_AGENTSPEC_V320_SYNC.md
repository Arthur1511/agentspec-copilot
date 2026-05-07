# DEFINE: AgentSpec v3.2.0 Upstream Sync

> Port all upstream v3.2.0 changes from `luanmorenommaciel/agentspec` to the Copilot CLI fork, adapting Claude Code-specific paths and mechanisms to Copilot CLI conventions.

## Metadata

| Attribute | Value |
|-----------|-------|
| **Feature** | AGENTSPEC_V320_SYNC |
| **Date** | 2026-05-07 |
| **Author** | define-agent |
| **Status** | ✅ Shipped |
| **Clarity Score** | 15/15 |
| **Source** | BRAINSTORM_AGENTSPEC_V320_SYNC.md |

---

## Problem Statement

The Copilot CLI fork (`Arthur1511/agentspec-copilot`) is behind upstream `luanmorenommaciel/agentspec` by one major release. Upstream v3.2.0 (released 2026-05-01) adds Judge Layer V0, local-first agent overrides, auto-generated agent routing, a Makefile, CI quality checks, and workspace initialization improvements — none of which are present in the fork. Fork users and maintainers cannot access these features until they are ported and adapted.

---

## Target Users

| User | Role | Pain Point |
|------|------|------------|
| Fork maintainers | Maintain Copilot CLI plugin | Must manually track upstream and apply path rewrites; currently there's no structured process |
| Fork users | Use AgentSpec in GitHub Copilot CLI | Missing Judge Layer cross-model review; no agent override mechanism documented; no stack auto-detection |

---

## Goals

| Priority | Goal |
|----------|------|
| **MUST** | Port `scripts/judge.py` adapted for Copilot CLI (`.github/storage` ledger path) |
| **MUST** | Create `review-judge` skill wrapping judge.py as a discoverable Copilot CLI skill |
| **MUST** | Create `scripts/init-workspace.sh` with SDD dir creation, stack detection, and agent override scaffold |
| **MUST** | Update `hooks.json` to call init script (replaces fragile inline commands) |
| **MUST** | Add `agent_resolution` contract to `WORKFLOW_CONTRACTS.yaml` and bump version to 3.2.0 |
| **MUST** | Add Step 0 to both `build-copilot.sh` and `build-copilot.ps1` (agent-router generation) |
| **SHOULD** | Create `docs/concepts/agent-overrides.md` (adapted for flat Copilot CLI agent structure) |
| **SHOULD** | Create `docs/getting-started/judge-setup.md` |
| **SHOULD** | Create `.github/workflows/quality-checks.yml` CI workflow |
| **SHOULD** | Create `Makefile` for contributor tooling (cross-platform) |
| **COULD** | Add `.shellcheckrc` for shell script linting consistency |
| **MUST** | Bump `manifest.yaml` agentspec version to 3.2.0, skills 35 → 36 |
| **MUST** | Update `CHANGELOG.md` with v3.2.0 entry |

---

## Success Criteria

- [ ] `python3 scripts/judge.py --ledger` runs without error; ledger writes to `.github/storage/judge-ledger.jsonl`
- [ ] `review-judge` skill is listed in `.github/skills/review-judge/SKILL.md` with correct Copilot CLI invocation
- [ ] `bash scripts/init-workspace.sh` creates `.github/sdd/{features,reports,archive}` and `.github/agents/custom/`
- [ ] `.github/hooks/hooks.json` calls the init script (not inline commands)
- [ ] `WORKFLOW_CONTRACTS.yaml` version is `3.2.0` and contains `agent_resolution` section
- [ ] `build-copilot.sh` runs `python3 scripts/generate-agent-router.py` as Step 0 before packaging
- [ ] `build-copilot.ps1` runs `python scripts/generate-agent-router.py` as Step 0 before packaging
- [ ] `make build` invokes full Copilot CLI build pipeline
- [ ] `.github/workflows/quality-checks.yml` triggers on `push`/`PR` to `.github/agents/**` and `scripts/**`
- [ ] `manifest.yaml` shows `version: "3.2.0"` and `skills: 36`
- [ ] `CHANGELOG.md` has a `## [3.2.0]` section listing all 14 ported changes

---

## Acceptance Tests

| ID | Scenario | Given | When | Then |
|----|----------|-------|------|------|
| AT-001 | Judge script runs ledger view | `OPENROUTER_API_KEY` not set, `.github/storage/` absent | `python3 scripts/judge.py --ledger` | Outputs "Today: 0 / 10 calls", creates storage dir, exit 0 |
| AT-002 | Judge script config error | No `OPENROUTER_API_KEY`, file provided | `python3 scripts/judge.py myfile.sql` | Outputs config error message, exits with code 2 |
| AT-003 | Init script idempotent | `.github/sdd/features/` already exists | `bash scripts/init-workspace.sh` | No error, all dirs still present, no duplicate creation |
| AT-004 | Build Step 0 generates router | `agent-router` SKILL.md content drifted | `bash build-copilot.sh` | Step 0 regenerates SKILL.md + routing.json before packaging |
| AT-005 | Router drift CI check | `routing.json` out of date | CI runs `python3 scripts/generate-agent-router.py --check` | CI fails with diff output |
| AT-006 | Hooks.json init | Fresh project clone | Session starts | `hooks.json` runs init script; `.github/sdd/` dirs created |
| AT-007 | Agent override flat path | User creates `.github/agents/my-agent.agent.md` | Copilot CLI resolves agent | User's local agent takes precedence (flat structure, no subdirs) |
| AT-008 | Skill count in manifest | After adding `review-judge` skill | `cat .github/manifest.yaml` | Shows `skills: 36` |

---

## Out of Scope

- `--judge` flag on SDD phase commands (requires slash command pattern; not available in Copilot CLI)
- Auto-scaffolding of `.github/agents/custom/` in `init-workspace.sh` (flat structure — not needed)
- Agent Router v2 Phase 2-4 (semantic layer, runtime routing — upstream backlog, not v3.2.0)
- Judge multi-model ensembles (V2 roadmap item)
- Judge PostToolUse hook (V3 roadmap item)
- Upstream `plugin-extras/` directory (Claude Code specific; no Copilot CLI equivalent)

---

## Constraints

| Type | Constraint | Impact |
|------|------------|--------|
| Technical | Agent structure is **flat** — `.github/agents/*.agent.md` (no category subdirs) | Agent override docs and `agent_resolution` contract must use flat paths |
| Technical | Copilot CLI has no slash commands — `/judge`, `/define --judge` patterns don't apply | Judge must be a skill, not a command |
| Technical | `judge.py` uses `${REPO_ROOT}/.claude/storage` in upstream | Path must be changed to `${REPO_ROOT}/.github/storage` |
| Platform | Windows is the primary contributor environment | Makefile needs `build-copilot.ps1` note; `init-workspace.sh` needs cross-platform compatibility |
| Build | Path rewriting in `build-copilot.sh/ps1` rewrites `.github/` → `${COPILOT_PLUGIN_ROOT}/` | New files in `.github/` will be auto-rewritten correctly on build |
| Compatibility | `hooks.json` must support both `bash` and `powershell` keys | Init script call needs both paths in hooks.json |

---

## Technical Context

| Aspect | Value | Notes |
|--------|-------|-------|
| **Deployment Location** | `.github/` (source) → `plugin-copilot/` (built) | All source edits go in `.github/`; build rewrites paths |
| **KB Domains** | None required | This is a framework sync task, not a domain-knowledge task |
| **IaC Impact** | None | No new infrastructure; `.github/storage/` created at runtime by judge.py |
| **Build scripts** | `build-copilot.sh`, `build-copilot.ps1` | Step 0 added to both before existing copy logic |
| **CI** | `.github/workflows/` | New `quality-checks.yml` workflow added |
| **Scripts** | `scripts/` directory (already exists) | New files: `judge.py`, `init-workspace.sh` |

---

## Assumptions

| ID | Assumption | If Wrong, Impact | Validated? |
|----|------------|------------------|------------|
| A-001 | Copilot CLI `hooks.json` supports calling external shell scripts | hooks.json would need to keep inline commands | ✅ Yes — hooks.json spec supports `bash:` and `powershell:` string values |
| A-002 | `python3` (Linux/macOS) and `python` (Windows) are available in contributor environments | Scripts would need a shebang fallback | [ ] Partially — standard in most dev environments |
| A-003 | Upstream judge.py adapts cleanly by changing only the `LEDGER` path constant | Deeper refactoring needed | ✅ Yes — LEDGER is a single `Path` constant at top of file |
| A-004 | `build-copilot.sh` path rewriting handles `scripts/` directory correctly | judge.py would ship with wrong paths | ✅ Yes — rewriting is `.github/<path>` → `${COPILOT_PLUGIN_ROOT}/<path>`; scripts/ is not in `.github/` so no rewriting needed |
| A-005 | Adding `.github/workflows/quality-checks.yml` won't conflict with existing CI | CI fails or duplicates | [ ] Needs verification — check existing workflows |

---

## Delta — 14 Implementation Items

### Group 1: Scripts (New Files)
| Item | File | Action | Key Adaptation |
|------|------|--------|----------------|
| 1 | `scripts/judge.py` | Create | `LEDGER = REPO_ROOT / ".github" / "storage" / "judge-ledger.jsonl"` |
| 2 | `scripts/init-workspace.sh` | Create | Flat `.github/agents/custom/` (no category subdirs); `.github/` paths |

### Group 2: Config (New Files)
| Item | File | Action | Key Adaptation |
|------|------|--------|----------------|
| 3 | `.shellcheckrc` | Create | Copy as-is (shell=bash, disable=SC1091,SC2155) |
| 4 | `Makefile` | Create | `build` calls `build-copilot.sh`; `lint` checks fork scripts |
| 5 | `.github/workflows/quality-checks.yml` | ~~Create~~ **✅ Already exists** | Already adapted with `.github/agents/**` paths and fork-specific shell scripts |

### Group 3: Skills & Docs (New Files)
| Item | File | Action | Key Adaptation |
|------|------|--------|----------------|
| 6 | `.github/skills/review-judge/SKILL.md` | Create | Skill format; `${COPILOT_PLUGIN_ROOT}/scripts/judge.py`; `.github/storage` |
| 7 | `docs/concepts/agent-overrides.md` | Create | Flat `.github/agents/<name>.agent.md`; `COPILOT_PLUGIN_ROOT` |
| 8 | `docs/getting-started/judge-setup.md` | Create | `.github/storage` path; skill invocation instead of `/judge` |

### Group 4: Updates (Existing Files)
| Item | File | Action | Key Change |
|------|------|--------|------------|
| 9 | `.github/hooks/hooks.json` | Update | Call `scripts/init-workspace.sh` via bash + powershell |
| 10 | `.github/sdd/architecture/WORKFLOW_CONTRACTS.yaml` | Update | Version 3.2.0; add `agent_resolution` section |
| 11 | `.github/manifest.yaml` | Update | `agentspec.version: "3.2.0"`, `skills: 36` |
| 12 | `build-copilot.sh` | Update | Step 0: `python3 scripts/generate-agent-router.py` |
| 13 | `build-copilot.ps1` | Update | Step 0: `python scripts/generate-agent-router.py` |
| 14 | `CHANGELOG.md` | Update | Add `## [3.2.0] - 2026-05-07` section |

---

## Clarity Score Breakdown

| Element | Score (0-3) | Notes |
|---------|-------------|-------|
| Problem | 3 | Specific: version gap, specific features missing, measurable parity goal |
| Users | 3 | Two concrete personas, clear pain points |
| Goals | 3 | 14 itemized goals with MUST/SHOULD/COULD priority |
| Success | 3 | 11 testable criteria, all binary pass/fail |
| Scope | 3 | Explicit in/out boundaries, YAGNI applied in brainstorm |
| **Total** | **15/15** | |

---

## Open Questions

None — ready for Design.

The one assumption to verify before Design: check `.github/workflows/` for existing CI workflows that `quality-checks.yml` might conflict with.

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-05-07 | define-agent | Initial version from BRAINSTORM_AGENTSPEC_V320_SYNC.md |

---

## Next Step

**Ready for:** `/design .github/sdd/features/DEFINE_AGENTSPEC_V320_SYNC.md`
