# DEFINE: Copilot CLI Frontmatter Adaptation

> Adapt Claude Code YAML frontmatter properties to valid GitHub Copilot CLI syntax for AgentSpec agent files.

## Metadata

| Attribute | Value |
|-----------|-------|
| **Feature** | COPILOT_FRONTMATTER_ADAPTATION |
| **Date** | 2026-05-13 |
| **Author** | define-agent |
| **Status** | ✅ Shipped |
| **Clarity Score** | 14/15 |

---

## Problem Statement

AgentSpec agent files use Claude Code YAML frontmatter properties (e.g., `tier`, `color`, `stop_conditions`, `escalation_rules`, `kb_domains`) that are not recognised by the GitHub Copilot CLI frontmatter parser. Additionally, tool names and the `description` example format differ between the two platforms. Without a clear mapping, maintainers cannot produce a single agent file that is valid for both runtimes, and the Copilot CLI may silently ignore or misparse custom properties.

---

## Target Users

| User | Role | Pain Point |
|------|------|------------|
| AgentSpec maintainer | Writes / updates `.github/agents/*.agent.md` files | Unsure which Claude Code props to keep, adapt, or discard when targeting Copilot CLI |
| New contributor | Adds a new agent to the repo | No documented mapping between the two YAML schemas |

---

## Goals

| Priority | Goal |
|----------|------|
| **MUST** | Produce a complete property-by-property mapping table (Claude Code → Copilot CLI) |
| **MUST** | Convert all tool names to their official Copilot CLI aliases |
| **MUST** | Convert the `description` examples from plain-text to `<example>` XML blocks |
| **MUST** | Convert the `model` shorthand to the full Copilot model name |
| **SHOULD** | Retain unsupported properties as-is (Copilot ignores unknowns; they remain useful for tooling) |
| **COULD** | Define a header comment convention marking which properties are "custom/non-standard" |

---

## Success Criteria

- [ ] Every property from the input YAML is accounted for (mapped, adapted, or explicitly retained)
- [ ] Output YAML passes Copilot CLI parsing without warnings
- [ ] Tool list uses only officially recognised Copilot CLI aliases or documented "ignored unknowns"
- [ ] `agent` tool is included in the tools list for any agent whose `escalation_rules` targets another agent (or whose body uses `Task` / sub-agent invocation)
- [ ] `description` uses `<example>` XML blocks matching the format already used in `.github/agents/workflow-brainstorm.agent.md`
- [ ] `model` value matches the full Copilot model name (e.g., `Claude Sonnet 4.5`)

---

## Acceptance Tests

| ID | Scenario | Given | When | Then |
|----|----------|-------|------|------|
| AT-001 | Tool alias mapping | Claude Code tools list | Conversion is applied | Every tool maps to a recognised alias or is kept with a note |
| AT-002 | Description format | Plain-text `Example 1 —` blocks | Conversion is applied | Each example wrapped in `<example>…</example>` XML |
| AT-003 | Model name expansion | `model: sonnet` | Conversion is applied | Value becomes `model: Claude Sonnet 4.5` |
| AT-004 | Unsupported props retained | `color`, `tier`, `kb_domains`, etc. | Conversion is applied | Props present in output with original values |
| AT-005 | AskUserQuestion handling | `AskUserQuestion` in tools list | Conversion is applied | Kept (Copilot CLI ignores unrecognised tool names per docs) |
| AT-006 | Agent invocation tool | Agent has `escalation_rules` targeting another agent (e.g., `define-agent`) | Conversion is applied | `agent` is present in the tools list |

---

## Source Selection (added v1.2)

| Group | Count | Source for Frontmatter Values | Action |
|---|---|---|---|
| Overlapping agents | 58 | External repo: `luanmorenommaciel/agentspec` `.claude/agents/<category>/<agent>.md` | Fetch external frontmatter, apply Copilot CLI conversion |
| ds-* agents (no overlap) | 8 | Self (local file already in Copilot CLI format) | Verify format only |

**Name field exception:** Do NOT replace the local `name` field. Local names are Copilot CLI identifiers (e.g. `agentspec:brainstorm-agent`, `de-spark-engineer`) and must be preserved.

### Agent Inventory

| Local File | External Path | Group |
|---|---|---|
| architect-data-platform-engineer.agent.md | architect/data-platform-engineer.md | overlap |
| architect-genai.agent.md | architect/genai-architect.md | overlap |
| architect-kb.agent.md | architect/kb-architect.md | overlap |
| architect-lakehouse.agent.md | architect/lakehouse-architect.md | overlap |
| architect-medallion.agent.md | architect/medallion-architect.md | overlap |
| architect-pipeline.agent.md | architect/pipeline-architect.md | overlap |
| architect-schema-designer.agent.md | architect/schema-designer.md | overlap |
| architect-the-planner.agent.md | architect/the-planner.md | overlap |
| cloud-ai-data-engineer-cloud.agent.md | cloud/ai-data-engineer-cloud.md | overlap |
| cloud-ai-data-engineer-gcp.agent.md | cloud/ai-data-engineer-gcp.md | overlap |
| cloud-ai-prompt-specialist-gcp.agent.md | cloud/ai-prompt-specialist-gcp.md | overlap |
| cloud-aws-data-architect.agent.md | cloud/aws-data-architect.md | overlap |
| cloud-aws-deployer.agent.md | cloud/aws-deployer.md | overlap |
| cloud-aws-lambda-architect.agent.md | cloud/aws-lambda-architect.md | overlap |
| cloud-ci-cd-specialist.agent.md | cloud/ci-cd-specialist.md | overlap |
| cloud-gcp-data-architect.agent.md | cloud/gcp-data-architect.md | overlap |
| cloud-lambda-builder.agent.md | cloud/lambda-builder.md | overlap |
| cloud-supabase-specialist.agent.md | cloud/supabase-specialist.md | overlap |
| de-ai-data-engineer.agent.md | data-engineering/ai-data-engineer.md | overlap |
| de-airflow-specialist.agent.md | data-engineering/airflow-specialist.md | overlap |
| de-dbt-specialist.agent.md | data-engineering/dbt-specialist.md | overlap |
| de-lakeflow-architect.agent.md | data-engineering/lakeflow-architect.md | overlap |
| de-lakeflow-expert.agent.md | data-engineering/lakeflow-expert.md | overlap |
| de-lakeflow-pipeline-builder.agent.md | data-engineering/lakeflow-pipeline-builder.md | overlap |
| de-lakeflow-specialist.agent.md | data-engineering/lakeflow-specialist.md | overlap |
| de-qdrant-specialist.agent.md | data-engineering/qdrant-specialist.md | overlap |
| de-spark-engineer.agent.md | data-engineering/spark-engineer.md | overlap |
| de-spark-performance-analyzer.agent.md | data-engineering/spark-performance-analyzer.md | overlap |
| de-spark-specialist.agent.md | data-engineering/spark-specialist.md | overlap |
| de-spark-streaming-architect.agent.md | data-engineering/spark-streaming-architect.md | overlap |
| de-spark-troubleshooter.agent.md | data-engineering/spark-troubleshooter.md | overlap |
| de-sql-optimizer.agent.md | data-engineering/sql-optimizer.md | overlap |
| de-streaming-engineer.agent.md | data-engineering/streaming-engineer.md | overlap |
| dev-codebase-explorer.agent.md | dev/codebase-explorer.md | overlap |
| dev-meeting-analyst.agent.md | dev/meeting-analyst.md | overlap |
| dev-prompt-crafter.agent.md | dev/prompt-crafter.md | overlap |
| dev-shell-script-specialist.agent.md | dev/shell-script-specialist.md | overlap |
| fabric-ai-specialist.agent.md | platform/fabric-ai-specialist.md | overlap |
| fabric-architect.agent.md | platform/fabric-architect.md | overlap |
| fabric-cicd-specialist.agent.md | platform/fabric-cicd-specialist.md | overlap |
| fabric-logging-specialist.agent.md | platform/fabric-logging-specialist.md | overlap |
| fabric-pipeline-developer.agent.md | platform/fabric-pipeline-developer.md | overlap |
| fabric-security-specialist.agent.md | platform/fabric-security-specialist.md | overlap |
| python-ai-prompt-specialist.agent.md | python/ai-prompt-specialist.md | overlap |
| python-code-cleaner.agent.md | python/code-cleaner.md | overlap |
| python-code-documenter.agent.md | python/code-documenter.md | overlap |
| python-code-reviewer.agent.md | python/code-reviewer.md | overlap |
| python-developer.agent.md | python/python-developer.md | overlap |
| python-llm-specialist.agent.md | python/llm-specialist.md | overlap |
| test-data-contracts-engineer.agent.md | test/data-contracts-engineer.md | overlap |
| test-data-quality-analyst.agent.md | test/data-quality-analyst.md | overlap |
| test-generator.agent.md | test/test-generator.md | overlap |
| workflow-brainstorm.agent.md | workflow/brainstorm-agent.md | overlap |
| workflow-build.agent.md | workflow/build-agent.md | overlap |
| workflow-define.agent.md | workflow/define-agent.md | overlap |
| workflow-design.agent.md | workflow/design-agent.md | overlap |
| workflow-iterate.agent.md | workflow/iterate-agent.md | overlap |
| workflow-ship.agent.md | workflow/ship-agent.md | overlap |
| ds-eda-analyst.agent.md | N/A | self-adapt |
| ds-experiment-tracker.agent.md | N/A | self-adapt |
| ds-feature-engineer.agent.md | N/A | self-adapt |
| ds-ml-deployer.agent.md | N/A | self-adapt |
| ds-model-evaluator.agent.md | N/A | self-adapt |
| ds-model-trainer.agent.md | N/A | self-adapt |
| ds-statistician.agent.md | N/A | self-adapt |
| ds-time-series-analyst.agent.md | N/A | self-adapt |

---

## Out of Scope

- Converting the Markdown body (agent instructions) of the file — only the YAML frontmatter block (between `---` delimiters) is in scope
- Changing the local `name` field — it must match the Copilot CLI identifier already in use
- Changes to the `.claude/` distribution or `build-plugin.sh` pipeline
- Introducing a new CI validation step for Copilot CLI frontmatter compliance

---

## Constraints

| Type | Constraint | Impact |
|------|------------|--------|
| Technical | Must follow `https://docs.github.com/en/copilot/reference/custom-agents-configuration` as the authoritative reference | Mapping cannot invent new official properties |
| Technical | Copilot CLI silently ignores unrecognised tool names and unknown YAML keys | Custom props can safely remain; no runtime breakage |
| Compatibility | Output must remain parseable by Claude Code as well (Claude Code tolerates extra YAML keys) | No Claude Code-specific props should be removed |

---

## Property Mapping Specification

The following table is the **core deliverable** of this feature. It defines how every property in the input YAML maps to Copilot CLI.

| Claude Code Property | Value (input) | Copilot CLI Action | Adapted Value / Notes |
|---|---|---|---|
| `name` | `brainstorm-agent` | **Supported** | Keep as-is (optionally prefix: `agentspec:brainstorm-agent`) |
| `description` | Plain-text with `Example N —` blocks | **Adapt format** | Wrap each example in `<example>` XML blocks; keep body text |
| `tier` | `T2` | **Retain (unsupported)** | Keep — Copilot ignores unknown keys; useful for internal tooling |
| `model` | `sonnet` | **Adapt value** | Expand to full name: `Claude Sonnet 4.5` |
| `tools` | `[Read, Write, Edit, Grep, Glob, Bash, TodoWrite, AskUserQuestion]` | **Adapt aliases** | See tool mapping below; add `agent` because `escalation_rules` targets `define-agent` |
| `kb_domains` | `[]` | **Retain (unsupported)** | Keep — used by agent resolution logic at runtime |
| `anti_pattern_refs` | `[shared-anti-patterns]` | **Retain (unsupported)** | Keep — used by agent instruction templates |
| `color` | `purple` | **Retain (unsupported)** | Keep — used by UI tooling / AgentSpec visualisations |
| `stop_conditions` | `[…]` | **Retain (unsupported)** | Keep — used by workflow orchestration logic |
| `escalation_rules` | `[…]` | **Retain (unsupported)** | Keep — used by workflow orchestration logic |

### Tool Alias Mapping

| Claude Code Tool | Copilot CLI Primary Alias | Compatible Aliases | Notes |
|---|---|---|---|
| `Read` | `read` | `NotebookRead` | Direct match |
| `Write` | `edit` | `Edit`, `MultiEdit`, `Write`, `NotebookEdit` | `Write` is a compatible alias of `edit` |
| `Edit` | `edit` | (same as above) | Deduplicated with Write |
| `Grep` | `search` | `Glob` | Copilot maps both Grep and Glob to `search` |
| `Glob` | `search` | `Grep` | Deduplicated with Grep |
| `Bash` | `execute` | `shell`, `powershell` | Direct compatible alias |
| `TodoWrite` | `todo` | — | Direct compatible alias |
| `AskUserQuestion` | _(no alias)_ | — | **Retain as-is** — Copilot ignores unrecognised names; no breakage |
| `Task` _(implicit)_ | `agent` | `custom-agent`, `Task` | **Add when agent invokes another agent** — triggered by presence of `escalation_rules[].target` pointing to another agent, or explicit `Task` calls in the agent body |

> **Rule:** If an agent's `escalation_rules` contain a `target` field pointing to another agent (e.g., `target: define-agent`), or if the agent body explicitly delegates work via `Task`, add `agent` to the Copilot CLI `tools` list.

---

## Technical Context

| Aspect | Value | Notes |
|--------|-------|-------|
| **Deployment Location** | `.github/agents/*.agent.md` | All 58 agents share the same format |
| **KB Domains** | None required | This is a schema-level change, not a data engineering task |
| **IaC Impact** | None | No infrastructure changes; file-level edit only |

**Reference files:**
- Existing Copilot-format agent: `.github/agents/workflow-brainstorm.agent.md` (lines 1–26 show the canonical output format)
- Official spec: `https://docs.github.com/en/copilot/reference/custom-agents-configuration`

---

## Assumptions

| ID | Assumption | If Wrong, Impact | Validated? |
|----|------------|------------------|------------|
| A-001 | `model: Claude Sonnet 4.5` is the correct full name for `sonnet` in Copilot CLI | Wrong model name would cause fallback to default | ✅ Confirmed via existing repo agents |
| A-002 | Unknown YAML keys are silently ignored by Copilot CLI parser | Custom props would cause parse errors if wrong | ✅ Confirmed via GitHub Docs ("All unrecognized tool names are ignored") |
| A-003 | `AskUserQuestion` is Claude Code-specific and has no Copilot CLI equivalent | Would need to be removed if it caused issues | ✅ Safe to retain per A-002 |

---

## Clarity Score Breakdown

| Element | Score (0-3) | Notes |
|---------|-------------|-------|
| Problem | 3 | Clear: Claude Code YAML ≠ Copilot CLI YAML; specific example provided |
| Users | 2 | AgentSpec maintainers/contributors; role clear, persona not fully described |
| Goals | 3 | Crystal clear: mapping table + converted output |
| Success | 3 | Testable: valid frontmatter, correct aliases, XML examples |
| Scope | 3 | Explicit: one input YAML, one output YAML, no body changes |
| **Total** | **14/15** | |

---

## Open Questions

None — ready for Design.

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-05-13 | define-agent | Initial version |
| 1.1 | 2026-05-13 | iterate-agent | Added `agent` tool rule: agents that invoke other agents (via `escalation_rules[].target` or `Task`) must include `agent` in Copilot CLI tools list |
| 1.2 | 2026-05-13 | iterate-agent | **Scope expansion**: added source selection spec (58 overlapping agents use external repo luanmorenommaciel/agentspec as frontmatter source; 8 ds-* agents self-adapt); added full agent inventory table; `name` field freeze rule |
| 1.3 | 2026-05-13 | ship-agent | Shipped and archived |

---

## Next Step

**Ready for:** `/design .github/sdd/features/DEFINE_COPILOT_FRONTMATTER_ADAPTATION.md`
