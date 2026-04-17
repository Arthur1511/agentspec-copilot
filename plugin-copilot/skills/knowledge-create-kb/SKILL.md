---
name: knowledge-create-kb
description: Create a complete KB domain from scratch with MCP validation. Use when adding a new knowledge base domain for a technology, library, or concept.
---

# Create Knowledge Base Command

> Create a complete KB section from scratch with MCP validation.

## Usage

```
/create-kb <DOMAIN>
```

**Examples**: `/create-kb redis`, `/create-kb pandas`, `/create-kb authentication`

## What Happens

1. **Validates prerequisites** — checks `_templates/` and `_index.yaml` exist
2. **Invokes kb-architect agent** — executes full workflow
3. **Reports completion** — shows score and files created

## Options

| Command | Action |
|---------|--------|
| `/create-kb <domain>` | Create new KB domain |
| `/create-kb --audit` | Audit existing KB health |

## See Also

- **Agent**: `${COPILOT_PLUGIN_ROOT}/agents/kb-architect.agent.md`
- **Example**: `${COPILOT_PLUGIN_ROOT}/kb/{domain}/`
- **Templates**: `${COPILOT_PLUGIN_ROOT}/kb/_templates/`
- **Registry**: `${COPILOT_PLUGIN_ROOT}/kb/_index.yaml`
