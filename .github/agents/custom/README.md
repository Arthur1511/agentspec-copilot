# Custom Agents

Drop project-specific `.agent.md` files here to override or extend AgentSpec built-in agents.

## How agent resolution works

AgentSpec Copilot CLI resolves agents in priority order:

1. **`.github/agents/<name>.agent.md`** — project-level override (checked first)
2. **`${COPILOT_PLUGIN_ROOT}/agents/<name>.agent.md`** — plugin-bundled agent (fallback)

Files in this `custom/` folder are **not** auto-loaded by name. To create a local override, place your file directly in `.github/agents/`, e.g.:

```
.github/agents/de-dbt-specialist.agent.md   # overrides the built-in agent
```

## Agent naming conventions

All AgentSpec agents follow kebab-case with a category prefix:

| Prefix     | Category                  |
|------------|---------------------------|
| `workflow-`| SDD pipeline (6 agents)   |
| `architect-`| System design (8 agents) |
| `cloud-`   | AWS / GCP / CI-CD         |
| `fabric-`  | Microsoft Fabric          |
| `python-`  | Python & code quality     |
| `test-`    | QA & contracts            |
| `de-`      | Data engineering          |
| `dev-`     | Developer tools           |

See `docs/concepts/agent-overrides.md` for a full guide.
