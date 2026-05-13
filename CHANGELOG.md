# Changelog

All notable changes to AgentSpec Copilot CLI fork will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

> **Fork note:** This is a GitHub Copilot CLI fork of [luanmorenommaciel/agentspec](https://github.com/luanmorenommaciel/agentspec).
> Upstream changes are ported and adapted: `.claude/` paths → `.github/`, Claude Code slash commands → Copilot CLI skills, `${CLAUDE_PLUGIN_ROOT}` → `${COPILOT_PLUGIN_ROOT}`.

---

## [Unreleased]

---

## [3.3.0] - 2026-05-13

### Added

- **8 new `ds-*` data scientist agents** — `ds-eda-analyst`, `ds-model-trainer`, `ds-model-evaluator`, `ds-feature-engineer`, `ds-experiment-tracker`, `ds-ml-deployer`, `ds-statistician`, `ds-time-series-analyst`. Full Copilot CLI frontmatter with tier, kb_domains, color, stop_conditions, escalation_rules, and `agent` tool for inter-agent delegation.

- **6 new KB domains** — `data-visualization`, `mlflow`, `pandas`, `scikit-learn`, `statistical-analysis`, `time-series`. Each domain includes `index.md`, `quick-reference.md`, 4 concept files, and 4 pattern files with production code examples.

- **5 new `data-scientist-*` skills** — `data-scientist-eda`, `data-scientist-experiment-tracking`, `data-scientist-feature-engineering`, `data-scientist-model-evaluation`, `data-scientist-model-training`.

- **`scripts/convert_frontmatter.py`** — Bulk frontmatter conversion script. Fetches canonical frontmatter from upstream `luanmorenommaciel/agentspec`, maps tool name aliases (Read → read, Bash → shell, etc.), wraps description examples in `<example>` XML blocks, and retains custom properties (`tier`, `kb_domains`, `color`, `stop_conditions`, `escalation_rules`) as Copilot CLI unsupported fields.

### Changed

- **All 66 `.agent.md` files converted** to valid Copilot CLI frontmatter format. `description` field now uses `<example>` XML blocks as required by the spec. Tool names use canonical lowercase aliases. Unsupported fields retained for AgentSpec runtime use.

- **Fixed 93 broken `escalation_rules.target` names** — short IDs (`define-agent`, `spark-eng`) corrected to canonical agent identifiers (`workflow-define`, `de-spark-engineer`). `generate-agent-router.py` regex updated to allow `:` in agent names.

- **Multi-provider model routing strategy** applied to all 66 agents:
  - `GPT-5 mini` (0x) — discovery and documentation agents
  - `GPT-5.3-Codex` (1x) — agentic execution (build, data engineering, cloud deployers, test, code quality)
  - `Claude Sonnet 4.6` (1x) — reasoning and design (SDD workflow, ds-*, architect, fabric, cloud architects)
  - `Claude Opus 4.6` (3x) — security only (`fabric-security-specialist`)

- **`scripts/generate-agent-router.py`** — Added `ds` category support; updated STATIC_FOOTER with multi-provider routing table replacing old Anthropic-only table; target regex now matches `:` in canonical agent names.

- **Agent router regenerated** — `agent-router/SKILL.md` + `routing.json` updated to 66 agents across 9 categories.

- **`plugin-copilot/`** rebuilt to include all the above.

### Category counts

| Category | Before | After |
|----------|--------|-------|
| Agents | 58 | **66** |
| Skills | 36 | **41** |
| KB domains | 24 | **30** |

### SDD

- `COPILOT_FRONTMATTER_ADAPTATION` feature archived to `.github/sdd/archive/` (Phase 4 complete).

---

## [3.2.0] - 2026-05-07

Sync with upstream `luanmorenommaciel/agentspec` v3.2.0. All changes adapted to Copilot CLI conventions (`.github/` paths, `${COPILOT_PLUGIN_ROOT}`, flat agent structure, skills instead of slash commands).

### Added

- **`scripts/judge.py`** — Judge Layer V0: cross-model second opinion via OpenRouter. Adapted from upstream `.claude/commands/review/judge.md`. Key changes: `LEDGER` path → `.github/storage/judge-ledger.jsonl` (was `.claude/storage/`); `HTTP-Referer` → `Arthur1511/agentspec-copilot`; 4 phase-tuned system prompts (generic/define/design/build); budget enforced via append-only JSONL ledger; pure Python stdlib, no dependencies.

- **`scripts/init-workspace.sh`** — Workspace initializer run via `hooks.json` at session start. Adapted from upstream `plugin-extras/scripts/init-workspace.sh`. Key changes: project detection uses `.git` | `copilot-instructions.md` | `.github/` (not `.git` | `CLAUDE.md` | `.claude/`); SDD dirs → `.github/sdd/`; agent scaffold → `.github/agents/custom/` flat structure (no `workflow/` subdir); agent names use fork prefixes (`de-dbt-specialist`, `de-airflow-specialist`, `cloud-supabase-specialist`, etc.); README references `${COPILOT_PLUGIN_ROOT}`.

- **`.github/skills/review-judge/SKILL.md`** — 36th skill. User-invokable wrapper for `judge.py`. Documents all phases, exit codes, ledger usage, and model defaults.

- **`Makefile`** — Root-level contributor tooling. Targets: `help`, `build` (calls `build-copilot.sh`), `check` (validates agent/skill/KB counts), `generate` (agent router), `lint` (shellcheck), `clean`, `install-deps`.

- **`docs/concepts/agent-overrides.md`** — Guide for creating and overriding agents in the flat `.github/agents/` structure. Covers resolution order, naming conventions, required front-matter, and custom agent directory.

- **`docs/getting-started/judge-setup.md`** — Full setup guide for `review-judge` skill. Covers API key setup, budget management, model selection, usage patterns, exit codes, and troubleshooting.

- **`.shellcheckrc`** — ShellCheck config disabling `SC1091` (sourced files) and `SC2155` (masking return values with declare) for all shell scripts in the repo.

- **`agent_resolution` section** in `WORKFLOW_CONTRACTS.yaml` — Documents flat agent structure, priority-1 local override path, all 8 prefix categories with agent lists.

### Changed

- **`build-copilot.sh`** — Added Step 0 before Step 1: calls `python3 scripts/generate-agent-router.py` and fails fast if it errors.
- **`build-copilot.ps1`** — Added Step 0 before Step 1: calls `python scripts/generate-agent-router.py` (PowerShell equivalent, fails fast on non-zero exit).
- **`.github/hooks/hooks.json`** — Session-start hook now calls `bash scripts/init-workspace.sh` instead of inline `mkdir` commands. PowerShell fallback preserved for Windows environments without bash.
- **`.github/sdd/architecture/WORKFLOW_CONTRACTS.yaml`** — Version bumped `3.0.0` → `3.2.0`; added `agent_resolution` section; added v3.2.0 version history entry.
- **`.github/manifest.yaml`** — `agentspec.version` bumped `3.0.0` → `3.2.0`; `skills` updated `35` → `36`.

### Skill count

35 → **36** (added `review-judge`)

---

## Upstream Changelog (luanmorenommaciel/agentspec)

The following is the upstream changelog, preserved for reference.

---

# Upstream Changelog

All notable changes to AgentSpec will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- **Agent Router v2 — Phase 1 (Build-Time Generation)** — the `agent-router` skill is now auto-generated from agent frontmatter, eliminating hand-maintained routing tables:
  - `scripts/generate-agent-router.py` — parses frontmatter across all 58 agents and derives category/tier/model/kb_domains/escalations without any new frontmatter fields required
  - Generates both `.claude/skills/agent-router/SKILL.md` (human-readable) and `.claude/skills/agent-router/routing.json` (machine-readable, foundation for future semantic layer)
  - `--check` mode for CI: fails with a unified diff if on-disk output drifts from generated content
  - Content hash stamped in SKILL.md (currently `d2970b1b988f`) for drift detection
  - `DO NOT EDIT` header pointing contributors back to the script
- `scripts/` directory at repo root for build tooling (distinct from `plugin-extras/scripts/` which ships in the plugin)

### Changed

- `build-plugin.sh` gained **Step 0** — runs the agent-router generator before copying artifacts into `plugin/`, ensuring the plugin ships the current routing tables
- `CLAUDE.md` repository tree updated to reflect the new `scripts/` directory
- `tasks/backlog.md` marks Agent Router v2 Phase 1 as 🟢 shipped and tracks Phases 2-4 as future work

### Philosophy

Adding, renaming, or retiring an agent no longer requires editing the router. Edit the agent's frontmatter → run `./build-plugin.sh` (or the generator standalone) → routing updates itself.

## [3.1.0] - 2026-04-17

### Added

- **New skill: `agent-router`** — intelligent routing table that maps file patterns, intent keywords, and domain context to all 58 agents. Includes model cost optimization strategy (Haiku 70% / Sonnet 20% / Opus 10%) and serial/parallel composition hints
- **New command: `/status`** — comprehensive project status report scanning SDD workspace, git state, codebase health (tests, TODOs, docs), and generating actionable recommendations with suggested next commands
- **Stack auto-detection in `init-workspace.sh`** — SessionStart hook now detects 10+ technology stacks (dbt, Lakeflow, Lambda, Airflow, Supabase, Terraform, Spark, Streaming, Fabric, Data Quality) and generates `.detected-stack.md` with recommended KB domains, agents, and commands
- **New KB domain: `supabase/`** — dedicated knowledge base with 4 concepts (pgvector-fundamentals, rls-policies, edge-functions, realtime) and 3 patterns (rag-vector-store, multi-tenant-rls, webhook-edge-function)
- New KB concepts for `lakeflow/`: expectations-model, cdc-fundamentals, deployment-model (now 5 concepts, within 3-6 spec)
- New KB file: `aws/quick-reference.md` — consolidated Lambda + Deployment cheat sheet
- New file: `commands/visual-explainer/README.md` — documents all 8 visual-explainer commands
- Plugin-only skills (`sdd-workflow`, `data-engineering-guide`) documented in `docs/reference/README.md`
- Vercel CLI prerequisite note in `/share` command

### Fixed

- **Critical:** 4 agents referenced non-existent KB domains in body text — `supabase-specialist` (supabase/), `qdrant-specialist` (qdrant/, n8n/), `ci-cd-specialist` (devops/), `ai-prompt-specialist-gcp` (gemini/, langfuse/) — all remapped to existing domains
- **Critical:** `lakeflow-expert` dead reference to `08-operations/limitations.md` → corrected to `reference/limitations.md`
- Dead `README.md` reference in `excalidraw-diagram/SKILL.md` — replaced with inline setup pointer
- Dead `./commands/` references in `visual-explainer/SKILL.md` — corrected to `.claude/commands/visual-explainer/`
- Malformed `mcp_servers` frontmatter in `llm-specialist.md` — reformatted to proper YAML objects with `tools:` field
- Missing `tools:` field in `mcp_servers` for 3 lakeflow T3 agents (lakeflow-architect, lakeflow-pipeline-builder, lakeflow-expert)
- `spark-specialist` → `spark-engineer` in `docs/concepts/README.md` build delegation
- Code of Conduct entry in CHANGELOG v1.0.0 clarified as "referenced in CONTRIBUTING.md"
- `/share` command added to README Visual & Utilities table

### Changed

- Command count: 29 → 30 (added `/status`)
- Skill count: 3 in source / 5 in plugin (added `agent-router` to source; plugin adds `sdd-workflow`, `data-engineering-guide`)
- KB domain count: 22 → 23 (added `supabase/`) — updated across all docs, SDD files, agents README, CLAUDE.md, README.md, and WORKFLOW_CONTRACTS.yaml
- `WORKFLOW_CONTRACTS.yaml` version bumped from 2.1.0 → 3.0.0
- `_index.yaml` version bumped to 2.2, supabase domain registered
- `supabase-specialist` agent now uses dedicated `supabase/` KB domain instead of `ai-data-engineering/` (semantically correct)
- Skills section in `docs/reference/README.md` updated to "2 core + 2 plugin-only" with plugin-only skills documented
- Plugin rebuilt — 58 agents, 30 commands, 5 skills, 23 KB domains

## [3.0.0] - 2026-03-29

### Added

- **Claude Code Plugin support**: AgentSpec is now distributable as a proper Claude Code plugin
- Plugin manifest (`plugin/.claude-plugin/plugin.json`) with marketplace metadata
- `build-plugin.sh` — build script that packages `.claude/` into plugin format with path rewriting
- `plugin-extras/` — plugin-only skills, hooks, and scripts not in `.claude/`
- New skill: `sdd-workflow` — auto-invoked when users discuss feature development workflow
- New skill: `data-engineering-guide` — auto-invoked when users discuss data engineering tasks
- `hooks/hooks.json` — SessionStart hook for workspace initialization
- `scripts/init-workspace.sh` — idempotent workspace directory creator
- Marketplace configuration for self-hosted distribution
- Plugin installation method in README alongside legacy `cp -r` method

### Changed

- All internal paths in plugin output rewritten from `.claude/` to `${CLAUDE_PLUGIN_ROOT}/`
- Skills count increased from 2 to 4 (added sdd-workflow, data-engineering-guide)
- Version bumped to 3.0.0 (new distribution model)

### Architecture

- `.claude/` remains the source of truth for development
- `build-plugin.sh` generates `plugin/` directory with proper plugin structure
- Plugin-only content lives in `plugin-extras/` to survive build clean cycles
- Workspace-specific paths (features/, reports/, archive/) preserved as project-relative

## [2.1.1] - 2026-03-29

### Added

- Documentation for 8 visual-explainer commands (`/generate-web-diagram`, `/generate-slides`, `/generate-visual-plan`, `/diff-review`, `/plan-review`, `/project-recap`, `/fact-check`, `/share`)
- Documentation for skills system (2 skills: `visual-explainer`, `excalidraw-diagram`)
- Skills contribution guide in CONTRIBUTING.md

### Fixed

- Command count corrected from 21 to 29 across all documentation (CLAUDE.md, README, commands/README, docs/reference)
- Fixed `meeting-analyst` incorrectly listed in Architect category (belongs in Dev) in sdd/README.md and README.md; replaced with `kb-architect`
- Fixed "23 KB domains" typo in sdd/README.md version history (correct: 22)
- Removed orphan `lakeflow/_index.yaml` (only domain with its own index file; master `_index.yaml` already covers it)

## [2.1.0] - 2026-03-26

### Added

- Multi-cloud agent coverage: 58 agents across 8 categories (was 27 across 5)
- New agent categories: architect/ (8), cloud/ (10), platform/ (6), python/ (6), test/ (3), dev/ (4)
- 11 additional KB domains: aws, gcp, microsoft-fabric, lakeflow, medallion, prompt-engineering, genai, pydantic, python, testing, terraform
- Supabase, Qdrant, and Lambda specialist agents
- Spark ecosystem agents: spark-specialist, spark-streaming-architect, spark-performance-analyzer
- Lakeflow ecosystem agents: lakeflow-architect, lakeflow-expert, lakeflow-pipeline-builder
- Shell script specialist and CI/CD specialist agents

### Changed

- Reorganized 15 agent folders into 8 clean semantic categories
- Eliminated duplicate agents (fabric-architect, fabric-pipeline-developer had inferior copies)
- Dissolved legacy categories: ai-ml/, code-quality/, communication/, exploration/, database/, ci-cd/
- Complete documentation overhaul: all docs pages rewritten for v2.1 accuracy
- SDD README, _index.md, ARCHITECTURE.md, WORKFLOW_CONTRACTS.yaml bumped to v2.1.0
- All root files (README, CLAUDE.md, CONTRIBUTING, SECURITY) aligned with actual counts

### Removed

- `/dev` command (file deleted; prompt-crafter agent still available directly)
- overnight-builder agent (superseded by prompt-crafter)
- adaptive-explainer and linear-project-manager agents
- PLAN_DATA_ENGINEERING_PIVOT.md from features/ (pivot complete)
- tasks/backlog.md and empty tasks/ directory

## [2.0.0] - 2026-03-26

### Added

- Data engineering specialization across the entire framework
- 11 new KB domains: dbt, spark, sql-patterns, airflow, streaming, data-modeling, data-quality, lakehouse, cloud-platforms, ai-data-engineering, modern-stack
- 11 new data engineering agents: dbt-specialist, spark-engineer, pipeline-architect, schema-designer, sql-optimizer, streaming-engineer, lakehouse-architect, data-quality-analyst, ai-data-engineer, data-platform-engineer, data-contracts-engineer
- 8 new data engineering commands: /pipeline, /schema, /data-quality, /lakehouse, /sql-review, /ai-pipeline, /data-contract, /migrate
- Data contract support in DEFINE phase (schema, SLAs, lineage)
- Pipeline architecture section in DESIGN phase (DAG, partitions, incremental strategy)
- Data engineering quality gates in BUILD phase (dbt build, sqlfluff, GE suites)
- DE delegation map in WORKFLOW_CONTRACTS.yaml

### Changed

- SDD templates extended with data engineering sections
- Existing agents (code-reviewer, code-cleaner, test-generator, design, define, build) adapted for DE
- All documentation rewritten with data engineering examples
- README, CLAUDE.md, CONTRIBUTING rebranded for data engineering focus

## [1.1.0] - 2026-02-24

### Added

- Complete documentation overhaul: getting-started, concepts, tutorials, reference guides
- Linear as project source of truth (60 issues, 6 milestones, 9 project documents)

### Changed

- KB domains cleaned — removed project-specific domains, kept framework scaffolding
- Agent prompts sanitized — removed all project-specific references
- `concept.md.template` section renamed from "The Pattern" to "The Concept"
- `test-case.json.template` now documents valid type values
- CLAUDE.md updated with current project status and active tasks
- README, CONTRIBUTING, SECURITY, CHANGELOG rewritten for public release

### Removed

- Project-specific KB domains (agentspec, projects)
- `design/agent-spec-plan-todo-list.md` (migrated to Linear)

### Fixed

- All 60 Linear issues linked to correct milestones
- Duplicate Linear documents consolidated (4 deprecated with redirects)

## [1.0.0] - 2026-02-03

### Initial Release

- Initial release of AgentSpec
- 5-phase SDD workflow (Brainstorm, Define, Design, Build, Ship)
- 16 specialized agents
  - 6 workflow agents (brainstorm, define, design, build, ship, iterate)
  - 4 code-quality agents (reviewer, cleaner, documenter, test-generator)
  - 4 communication agents (adaptive-explainer, linear-project-manager, meeting-analyst, the-planner)
  - 2 exploration agents (codebase-explorer, kb-architect)
- 12 slash commands
- Knowledge Base (KB) framework with 7 templates
- SDD document templates (5 phases)
- Workflow contracts (YAML-based phase transitions)

### Documentation

- README with quick start guide
- CONTRIBUTING guidelines
- Code of Conduct (referenced in CONTRIBUTING.md)
- Agent reference documentation
- KB framework guide
