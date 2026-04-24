# DEFINE: Upstream Features Port

> Port six components from the upstream AgentSpec repo into this fork: core-status skill, agent-router skill + routing.json, data-engineering-guide skill, sdd-workflow skill, scripts/generate-agent-router.py, and CHANGELOG.md.

## Metadata

| Attribute | Value |
|-----------|-------|
| **Feature** | UPSTREAM_FEATURES |
| **Date** | 2026-04-24 |
| **Author** | Arthur1511 |
| **Status** | ✅ Shipped |
| **Clarity Score** | 13/15 |

---

## Problem Statement

This fork (`Arthur1511/agentspec-copilot`) is missing six components that exist in the upstream AgentSpec distribution. Without them the plugin lacks: a status dashboard for self-inspection, an intelligent agent-routing mechanism with its machine-readable manifest, consolidated guides for data engineering and the SDD workflow, the script that regenerates the routing manifest, and a project changelog. Developers and end-users cannot rely on routing or check plugin health without these pieces.

---

## Target Users

| User | Role | Pain Point |
|------|------|------------|
| Plugin end-user | Developer using Copilot CLI + AgentSpec | Cannot check which agents/skills are available; requests are not auto-routed to the right agent |
| Fork maintainer | Contributor keeping the fork in sync with upstream | No changelog tracking divergence; no script to regenerate routing when agents change |

---

## Goals

What success looks like (prioritized):

| Priority | Goal |
|----------|------|
| **MUST** | Add `core-status` skill that reports plugin health (agent count, skill count, KB count) |
| **MUST** | Add `agent-router` skill with `routing.json` so user intents are mapped to agents |
| **MUST** | Add `data-engineering-guide` skill as a consolidated entry-point for DE workflows |
| **MUST** | Add `sdd-workflow` skill as a single-page reference for the full 5-phase SDD flow |
| **MUST** | Add `scripts/generate-agent-router.py` that auto-generates `routing.json` from agent files |
| **MUST** | Add `CHANGELOG.md` at repo root documenting fork history vs upstream |

---

## Success Criteria

- [ ] `core-status` skill directory and `SKILL.md` created; runnable via `/status` and outputs counts matching `manifest.yaml`
- [ ] `agent-router` skill directory and `SKILL.md` created; `routing.json` present at `.github/skills/agent-router/routing.json` with at least one route per agent category
- [ ] `data-engineering-guide` skill directory and `SKILL.md` created; covers all `de-*` agents and KB domains
- [ ] `sdd-workflow` skill directory and `SKILL.md` created; covers all 5 phases with slash command references
- [ ] `scripts/generate-agent-router.py` executes without error and regenerates `routing.json` from `.github/agents/*.agent.md`
- [ ] `CHANGELOG.md` at repo root follows Keep A Changelog format (https://keepachangelog.com) with at least one version entry documenting this fork's changes vs upstream

---

## Acceptance Tests

| ID | Scenario | Given | When | Then |
|----|----------|-------|------|------|
| AT-001 | Status skill reports correct counts | Plugin is installed, `manifest.yaml` present | User runs `/status` | Output lists agents ≥ 58, skills ≥ 31, KB domains ≥ 24 |
| AT-002 | Agent router resolves a DE request | `routing.json` present | User asks "analyze my Spark job" | Skill returns `de-spark-specialist` as recommended agent |
| AT-003 | Agent router resolves a workflow request | `routing.json` present | User asks "I want to build a new feature" | Skill returns `workflow-brainstorm` or `workflow-define` |
| AT-004 | DE guide lists all `de-*` agents | Skill SKILL.md exists | User reads guide | All 15 `de-*` agents referenced with one-liner purpose |
| AT-005 | SDD workflow skill covers all phases | Skill SKILL.md exists | User reads guide | Phases 0–4 described with slash commands and output artifacts |
| AT-006 | Script regenerates routing.json | `.github/agents/*.agent.md` present | `python scripts/generate-agent-router.py` is run | `routing.json` is written with routes for every agent |
| AT-007 | Build script includes new skills | New skill directories added | `.\build-copilot.ps1` is run | `plugin-copilot/skills/` contains all 4 new skill directories |
| AT-008 | Changelog has at least one entry | CHANGELOG.md created | User opens file | `[Unreleased]` or versioned section present |

---

## Out of Scope

- Modifying any existing skill or agent files
- Updating `manifest.yaml` skill count (that is a separate maintenance task)
- Implementing automated CI validation of `routing.json` schema
- Back-porting any other upstream features not listed in this DEFINE

---

## Constraints

| Type | Constraint | Impact |
|------|------------|--------|
| Technical | New skills must follow the existing `SKILL.md` front-matter schema (`name`, `description`) | Ensures build script picks them up without changes |
| Technical | `routing.json` must be valid JSON parseable by the build script path-rewriter | Build script rewrites `.github/` paths in `*.json` files |
| Technical | `generate-agent-router.py` must run with Python 3.9+ stdlib only (no third-party deps) | No `requirements.txt` or venv setup required |
| Convention | Skill directories use kebab-case with a category prefix (`core-`, `agent-`, `data-engineering-`, `sdd-`) | Consistent with existing skill naming |
| Convention | `CHANGELOG.md` follows Keep A Changelog 1.0.0 format | Standard adopted by the upstream |

---

## Technical Context

| Aspect | Value | Notes |
|--------|-------|-------|
| **Deployment Location** | `.github/skills/<skill-name>/SKILL.md` | Skills live here per build script logic |
| **Routing JSON location** | `.github/skills/agent-router/routing.json` | Co-located with the agent-router skill |
| **Script location** | `scripts/generate-agent-router.py` | New `scripts/` directory at repo root |
| **Changelog location** | `CHANGELOG.md` | Repo root, alongside README.md |
| **KB Domains** | `modern-stack`, `python` | Script tooling conventions |
| **IaC Impact** | None | No infrastructure changes |

**Skill file manifest (new files):**

```
.github/skills/core-status/SKILL.md
.github/skills/agent-router/SKILL.md
.github/skills/agent-router/routing.json
.github/skills/data-engineering-guide/SKILL.md
.github/skills/sdd-workflow/SKILL.md
scripts/generate-agent-router.py
CHANGELOG.md
```

---

## Assumptions

| ID | Assumption | If Wrong, Impact | Validated? |
|----|------------|------------------|------------|
| A-001 | All 58 agents follow a consistent front-matter format with `name` and `description` | Script would fail to parse some agents → partial routing.json | [x] Confirmed by inspection of existing agents |
| A-002 | The build script's path-rewriter covers `routing.json` (it processes `*.json`) | routing.json would retain `.github/` paths in the distributed plugin | [x] Confirmed in build-copilot.ps1 line 134 |
| A-003 | No existing skill is named `core-status`, `agent-router`, `data-engineering-guide`, or `sdd-workflow` | Conflict with existing directory | [x] Confirmed by listing `.github/skills/` |

---

## Clarity Score Breakdown

| Element | Score (0-3) | Notes |
|---------|-------------|-------|
| Problem | 3 | Specific: six named missing components in a fork |
| Users | 2 | Two personas identified; pain points clear but personas are generic |
| Goals | 3 | One goal per deliverable, all MUST |
| Success | 3 | Measurable, testable criteria per deliverable |
| Scope | 2 | Explicit out-of-scope; minor ambiguity on exact content of routing.json schema |
| **Total** | **13/15** | |

---

## Open Questions

1. **routing.json schema**: Should routes include confidence thresholds, keyword lists, or regex patterns? The design phase should decide the exact schema.
2. **core-status source**: The user referenced "core/status.md" as the upstream source — does this mean there is a `core/` folder with a `status.md` to mirror, or is this a conceptual reference? Design should specify the exact behavior.
3. **data-engineering-guide scope**: Should this skill delegate to a specific agent or serve purely as a human-readable reference guide?

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-04-24 | define-agent | Initial version |

---

## Next Step

**Ready for:** `/design .github/sdd/features/DEFINE_UPSTREAM_FEATURES.md`
