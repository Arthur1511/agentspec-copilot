# Agent Overrides

AgentSpec Copilot CLI ships 58 built-in agents as a flat list of `*.agent.md` files inside the plugin. You can override any agent or add project-specific agents without modifying the plugin.

## How resolution works

AgentSpec resolves agents in priority order at runtime:

| Priority | Location | Wins when… |
|----------|----------|------------|
| 1 | `.github/agents/<name>.agent.md` | File exists in your project |
| 2 | `${COPILOT_PLUGIN_ROOT}/agents/<name>.agent.md` | Plugin fallback |

**Flat structure required.** All agents — built-in and custom — must be placed directly in `.github/agents/` with no subdirectories. Agent names encode their category as a filename prefix (e.g., `de-dbt-specialist.agent.md`).

## Override a built-in agent

1. Copy the built-in agent from `plugin-copilot/agents/<name>.agent.md`
2. Place the copy at `.github/agents/<name>.agent.md`
3. Edit to taste — your version takes priority over the plugin's

```bash
# Example: override de-dbt-specialist with a project-specific version
cp plugin-copilot/agents/de-dbt-specialist.agent.md .github/agents/de-dbt-specialist.agent.md
# Edit .github/agents/de-dbt-specialist.agent.md
```

## Create a new custom agent

Create a new `*.agent.md` file in `.github/agents/`:

```bash
cat > .github/agents/my-domain-expert.agent.md << 'EOF'
---
name: my-domain-expert
description: |
  Expert in our internal data platform conventions.

  <example>
  Context: User needs help with our custom pipeline format
  user: "How do I add a new pipeline stage?"
  assistant: "I'll use the my-domain-expert agent to guide you."
  </example>
model: Claude Sonnet 4.5
tools:
  - read
  - edit
  - search
---

# My Domain Expert

## Identity
> **Identity:** Custom agent for [Your Company] data platform conventions.
> **Domain:** Internal platform engineering
> **Threshold:** 0.85

## Capabilities

- Deep knowledge of internal pipeline formats
- Company-specific naming conventions and patterns
EOF
```

## Agent naming conventions

All AgentSpec agents use kebab-case with a category prefix. Use the same convention for custom agents to avoid confusion:

| Prefix | Category | Example |
|--------|----------|---------|
| `workflow-` | SDD pipeline | `workflow-brainstorm` |
| `architect-` | System design | `architect-schema-designer` |
| `cloud-` | AWS / GCP | `cloud-aws-data-architect` |
| `fabric-` | Microsoft Fabric | `fabric-architect` |
| `python-` | Python & code | `python-code-reviewer` |
| `test-` | QA & contracts | `test-generator` |
| `de-` | Data engineering | `de-dbt-specialist` |
| `dev-` | Developer tools | `dev-codebase-explorer` |

For custom/internal agents, pick a prefix that makes their scope clear:
- `internal-` — company-specific agents
- `platform-` — platform engineering agents
- `domain-` — domain-specific experts

## Required agent front-matter

Every agent file must include these front-matter fields:

```yaml
---
name: <agent-name>               # kebab-case, matches filename without .agent.md
description: |
  <one-liner purpose>

  <example>
  Context: <when this triggers>
  user: "<user message>"
  assistant: "<how to invoke>"
  </example>
model: Claude Sonnet 4.5        # or Claude Haiku 4.5 for fast/cheap tasks
tools:
  - read
  - edit
  - search
---
```

## Custom agents directory

`scripts/init-workspace.sh` creates `.github/agents/custom/` with a README on first run. Files in `custom/` are **not** auto-loaded — place your overrides directly in `.github/agents/` for them to take effect.

## Verifying resolution

After adding a custom agent, run the build to confirm the agent appears in `plugin-copilot/agents/`:

```bash
./build-copilot.sh
ls plugin-copilot/agents/ | grep my-agent
```

Built-in agents bundled with the plugin live in `plugin-copilot/agents/` (generated artifact — do not edit directly).
