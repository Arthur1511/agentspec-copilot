# Contributing to AgentSpec for GitHub Copilot CLI

Thank you for your interest in contributing! This is the **GitHub Copilot CLI port** of [AgentSpec](https://github.com/luanmorenommaciel/agentspec), originally created by [@luanmorenommaciel](https://github.com/luanmorenommaciel) for Claude Code.

## Quick Start

```bash
# Fork and clone
git clone https://github.com/Arthur1511/agentspec-copilot.git
cd agentspec-copilot
git checkout -b feature/your-feature

# The framework lives in .github/
ls .github/agents/      # 58 specialized agents (*.agent.md)
ls .github/skills/      # 31 skill directories (each with SKILL.md)
ls .github/kb/          # 24 KB domain directories + _index.yaml
ls .github/sdd/         # SDD framework (templates, architecture)
```

> **Never edit `plugin-copilot/` directly** — it is a generated artifact built from `.github/` by `build-copilot.sh`.

## Ways to Contribute

| Type           | Where                        | Guide                                    |
|----------------|------------------------------|------------------------------------------|
| New Agent      | `.github/agents/`            | [Adding Agents](#adding-a-new-agent)     |
| New KB Domain  | `.github/kb/{domain}/`       | [Adding KB Domains](#adding-a-kb-domain) |
| New Skill      | `.github/skills/{skill}/`    | [Adding Skills](#adding-a-skill)         |
| Bug Fix        | Any file                     | [Bug Fixes](#bug-fixes)                  |
| Documentation  | `docs/`, `README.md`         | [Docs Guide](#documentation)             |

## Adding a New Agent

1. Create a new file in `.github/agents/` (flat directory — no subdirectories):

   ```bash
   cp .github/agents/python-code-reviewer.agent.md .github/agents/your-agent.agent.md
   ```

2. Fill in the required front-matter and sections:

   ```markdown
   ---
   name: your-agent
   description: |
     One-liner purpose.

     <example>
     Context: When this triggers
     user: "user message"
     assistant: "how to invoke"
     </example>
   model: Claude Sonnet 4.5
   tools:
     - read
     - edit
     - execute
     - search
   ---
   ```

3. Required sections in the body:
   - **Identity block** — name, domain, trigger threshold (≥ 0.90)
   - **Capabilities** — what the agent does (2-8 items)
   - **Quality gate** — pre-flight checklist
   - **Response format** — expected output structure

4. For data engineering agents, add `kb_domains` to the front-matter listing relevant KB domains.

5. Build and verify:

   ```bash
   ./build-copilot.sh      # Linux / macOS
   .\build-copilot.ps1     # Windows
   ```

## Adding a KB Domain

1. Register the domain first in `.github/kb/_index.yaml`
2. Create the directory structure:

   ```text
   .github/kb/your-domain/
   ├── index.md              # Domain overview
   ├── quick-reference.md    # Cheat sheet (max 100 lines)
   ├── concepts/             # 3-6 concept files (max 150 lines each)
   │   └── your-concept.md
   └── patterns/             # 3-6 pattern files with code (max 200 lines each)
       └── your-pattern.md
   ```

3. Use the templates in `.github/kb/_templates/` as a starting point.

## Adding a Skill

Skills are the mechanism that connects user requests to agents in Copilot CLI.

1. Create a directory: `.github/skills/your-skill/`
2. Add a `SKILL.md` with YAML front-matter:

   ```yaml
   ---
   name: your-skill
   description: What this skill does and when to use it.
   ---
   ```

3. Use kebab-case with a category prefix (e.g. `workflow-brainstorm`, `data-engineering-pipeline`, `visual-explainer-generate-slides`)
4. See existing skills for examples — `workflow-brainstorm`, `data-engineering-pipeline`

## Bug Fixes

1. Check [existing issues](https://github.com/Arthur1511/agentspec-copilot/issues)
2. Create a branch: `git checkout -b fix/description`
3. Make your fix in `.github/` (never in `plugin-copilot/`)
4. Run `./build-copilot.sh` (Linux/macOS) or `.\build-copilot.ps1` (Windows) to verify the build
5. Submit a PR with a clear description of the problem and solution

## Documentation

- Keep markdown files ATX-style (`#`, `##`, `###`)
- Use fenced code blocks with language identifiers
- Keep tables properly aligned
- Test all links before submitting

## Pull Request Process

1. Fork the repository
2. Create a feature branch from `main`
3. Make all changes inside `.github/` (source of truth)
4. Run `./build-copilot.sh` (Linux/macOS) or `.\build-copilot.ps1` (Windows) to generate `plugin-copilot/`
5. Submit a PR with:
   - Conventional commit title (e.g. `feat(agents): add redis-specialist agent`)
   - Description of what changed and why
   - Link to related issue if applicable

## Plugin Development

AgentSpec for Copilot CLI is distributed as a Copilot CLI plugin. The development workflow:

1. **Develop in `.github/`** — this is the source of truth
2. **Build the plugin** — run `./build-copilot.sh` (Linux/macOS) or `.\build-copilot.ps1` (Windows) to generate `plugin-copilot/`
3. **Test locally** — run `copilot plugin install ./plugin-copilot`
4. **Iterate** — make changes in `.github/`, rebuild, reinstall

### Key Concepts

- **`.github/`** contains agents, skills, KB, SDD — your development environment
- **`plugin-copilot/`** is the generated distributable (built from `.github/` by `build-copilot.sh`)
- **`build-copilot.sh`** / **`build-copilot.ps1`** copies `.github/` → `plugin-copilot/` and rewrites `.github/` paths to `${COPILOT_PLUGIN_ROOT}/`

### Path Convention

In `.github/` (source), reference paths as `.github/kb/dbt/index.md`.  
In the plugin output, these become `${COPILOT_PLUGIN_ROOT}/kb/dbt/index.md`.  
Workspace output paths (`.github/sdd/features/`, `.github/sdd/reports/`, `.github/sdd/archive/`) stay as-is — they point to the user's project.

## Code of Conduct

We follow the [Contributor Covenant](https://www.contributor-covenant.org/). Be respectful, constructive, and inclusive.

## Questions?

- [Open an issue](https://github.com/Arthur1511/agentspec-copilot/issues)
- [Start a discussion](https://github.com/Arthur1511/agentspec-copilot/discussions)
- Original project: [AgentSpec for Claude Code](https://github.com/luanmorenommaciel/agentspec)

