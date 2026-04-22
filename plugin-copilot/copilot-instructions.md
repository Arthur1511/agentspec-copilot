# AgentSpec Copilot CLI — Copilot Instructions

AgentSpec is a GitHub Copilot CLI extension that provides a 5-phase Spec-Driven Development (SDD) workflow with 58 specialized agents, 29 commands, and 24 KB domains for data engineering.

---

## Build

```bash
# Linux / macOS
./build-copilot.sh

# Windows (PowerShell)
.\build-copilot.ps1

# Validate the build output
cat plugin-copilot/manifest.yaml
```

Both scripts package `.github/` → `plugin-copilot/` with identical logic: clean the output directory, copy all components, rewrite `.github/<path>` → `${COPILOT_PLUGIN_ROOT}/<path>`, and restore workspace paths (`sdd/features/`, `sdd/reports/`, `sdd/archive/`).

The CI workflow (`.github/workflows/plugin-validate.yml`) runs `build-plugin.sh` (Claude Code variant) and checks agent count (≥50), skill count (≥4), KB domain count (≥20), and JSON/plugin manifest validity.

---

## Architecture

### Two Parallel Distributions

This repo ships AgentSpec for **two platforms**:

| Platform | Source of Truth | Build Script | Output |
|---|---|---|---|
| GitHub Copilot CLI | `.github/` | `build-copilot.sh` | `plugin-copilot/` |
| Claude Code | `.claude/` | `build-plugin.sh` | `plugin/` |

**Never edit `plugin-copilot/` or `plugin/` directly** — they are generated artifacts. All content changes go into `.github/` (Copilot CLI) or `.claude/` (Claude Code).

### Source Structure (`.github/`)

```
.github/
├── agents/           # 58 *.agent.md files — flat directory, no subdirectories
├── skills/           # 31 skill directories, each containing SKILL.md
├── kb/               # 24 KB domain directories + _index.yaml registry
│   ├── _index.yaml   # Machine-readable domain registry (entry point for agents)
│   ├── _templates/   # 7 templates for new domains
│   └── <domain>/     # index.md, quick-reference.md, concepts/, patterns/
├── sdd/
│   ├── architecture/ # WORKFLOW_CONTRACTS.yaml + ARCHITECTURE.md (read-only reference)
│   ├── templates/    # 5 phase document templates
│   ├── features/     # Active WIP documents (BRAINSTORM_*, DEFINE_*, DESIGN_*)
│   ├── reports/      # BUILD_REPORT_* files
│   └── archive/      # Shipped features
└── manifest.yaml     # Plugin manifest
```

### Path Rewriting During Build

`build-copilot.sh` / `build-copilot.ps1` rewrites `.github/<path>` → `${COPILOT_PLUGIN_ROOT}/<path>` in all `.md`, `.yaml`, `.yml`, `.json` files inside `plugin-copilot/`.

**Exception — workspace output paths are preserved as-is:**
- `.github/sdd/features/`
- `.github/sdd/reports/`
- `.github/sdd/archive/`

If you add new internal references in agent or skill files, use `.github/<component>/` paths — the build will rewrite them.

### 5-Phase SDD Workflow

```
Phase 0: /brainstorm  →  BRAINSTORM_{FEATURE}.md  (optional)
Phase 1: /define      →  DEFINE_{FEATURE}.md
Phase 2: /design      →  DESIGN_{FEATURE}.md
Phase 3: /build       →  Code + BUILD_REPORT_{FEATURE}.md
Phase 4: /ship        →  archive/{FEATURE}/SHIPPED_{DATE}.md
Cross:   /iterate     →  Updates any phase 0-2 doc with cascade awareness
```

All phase documents live in `.github/sdd/features/` while active.

---

## Key Conventions

### Agent Files (`*.agent.md`)

All 58 agents live as a **flat list** in `.github/agents/` — no subdirectories. Category is encoded in the filename prefix:

| Prefix | Category | Count | Examples |
|---|---|---|---|
| `workflow-` | SDD pipeline | 6 | `workflow-brainstorm`, `workflow-build`, `workflow-ship` |
| `architect-` | System design | 8 | `architect-schema-designer`, `architect-pipeline`, `architect-the-planner` |
| `cloud-` | AWS / GCP / CI-CD | 10 | `cloud-aws-data-architect`, `cloud-gcp-data-architect`, `cloud-ci-cd-specialist` |
| `fabric-` | Microsoft Fabric | 6 | `fabric-architect`, `fabric-pipeline-developer`, `fabric-security-specialist` |
| `python-` | Python & code quality | 6 | `python-code-reviewer`, `python-code-cleaner`, `python-developer` |
| `test-` | QA & contracts | 3 | `test-generator`, `test-data-quality-analyst`, `test-data-contracts-engineer` |
| `de-` | Data engineering | 15 | `de-spark-engineer`, `de-dbt-specialist`, `de-airflow-specialist`, `de-lakeflow-*` |
| `dev-` | Developer tools | 4 | `dev-codebase-explorer`, `dev-meeting-analyst`, `dev-prompt-crafter` |

Every agent file follows this structure:

```markdown
---
name: <agent-name>
description: |
  <one-liner purpose>
  
  <example>
  Context: <when this triggers>
  user: "<user message>"
  assistant: "<how to invoke>"
  </example>
model: Claude Sonnet 4.5
tools:
  - read
  - edit
  - execute
  - search
---

# Agent Title

## Identity
> **Identity:** ...
> **Domain:** ...
> **Threshold:** 0.90

## Knowledge Resolution
...

## Capabilities
...
```

Required front-matter fields: `name`, `description` (with ≥1 `<example>` block), `model`, `tools`.

Data engineering agents must include a `kb_domains` field listing relevant KB domains. Agents follow **KB-first resolution**: read `_index.yaml` → load relevant domain files → apply patterns.

### KB Domain Structure

24 domains live under `.github/kb/`. Each domain must have exactly:
```
<domain>/
├── index.md           # Domain overview
├── quick-reference.md # Cheat sheet (≤100 lines)
├── concepts/          # 3–6 concept files (≤150 lines each)
└── patterns/          # 3–6 pattern files with code examples (≤200 lines each)
```

**Available domains:** `ai-data-engineering`, `airflow`, `aws`, `cloud-platforms`, `data-modeling`, `data-quality`, `dbt`, `gcp`, `genai`, `lakeflow`, `lakehouse`, `medallion`, `microsoft-fabric`, `modern-stack`, `prompt-engineering`, `pydantic`, `python`, `spark`, `sql-patterns`, `streaming`, `supabase`, `terraform`, `testing`, `xgboost`

Register new domains in `.github/kb/_index.yaml` before writing any domain files.

### Skill Files

Each skill is a directory containing a single `SKILL.md` file (31 skills total). Skill names use kebab-case with a category prefix:

| Prefix | Skills |
|---|---|
| `workflow-` | `brainstorm`, `build`, `create-pr`, `define`, `design`, `iterate`, `ship` |
| `visual-explainer` / `visual-explainer-*` | base + `diff-review`, `fact-check`, `generate-slides`, `generate-visual-plan`, `generate-web-diagram`, `plan-review`, `project-recap`, `share` |
| `data-engineering-*` | `ai-pipeline`, `data-contract`, `data-quality`, `lakehouse`, `migrate`, `pipeline`, `schema`, `sql-review` |
| `core-*` | `meeting`, `memory`, `readme-maker`, `sync-context` |
| `knowledge-*` | `create-kb` |
| standalone | `excalidraw-diagram`, `review-code` |

### SDD Templates

When creating SDD phase documents, always use the corresponding template from `.github/sdd/templates/`:
- `BRAINSTORM_TEMPLATE.md`
- `DEFINE_TEMPLATE.md`
- `DESIGN_TEMPLATE.md`
- `BUILD_REPORT_TEMPLATE.md`
- `SHIPPED_TEMPLATE.md`

### Markdown Standards

- ATX-style headers (`#`, `##`, `###`) — no underline-style
- Fenced code blocks always include a language identifier
- Tables are properly aligned

### Confidence Scoring

Agents use confidence thresholds to decide actions:

| Score | Action |
|---|---|
| ≥ 0.90 | Proceed with recommendation |
| 0.80–0.89 | Suggest with adaptation notes |
| 0.70–0.79 | Present multiple options, ask user |
| < 0.70 | Escalate or ask for clarification |

---

## Using AgentSpec to Develop AgentSpec

This repo uses its own SDD workflow for feature development:

```bash
gh copilot suggest "Use agentspec:brainstorm-agent to explore 'add new KB domain for Redis'"
gh copilot suggest "Use agentspec:define-agent to capture requirements from BRAINSTORM_REDIS_KB.md"
gh copilot suggest "Use agentspec:build-agent to implement DESIGN_REDIS_KB.md"
```

Active WIP docs are in `.github/sdd/features/`. Check there before starting new work to avoid duplicating in-flight features.
