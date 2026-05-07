# Build Report — AgentSpec v3.2.0 Sync

**Feature:** AGENTSPEC_V320_SYNC
**Status:** ✅ Complete
**Date:** 2026-05-07
**Phase:** Build (Phase 3)

---

## Summary

Ported all 13 changes from upstream `luanmorenommaciel/agentspec` v3.2.0 to the Copilot CLI fork (`Arthur1511/agentspec-copilot`). All items adapted to Copilot CLI conventions: `.github/` paths, `${COPILOT_PLUGIN_ROOT}`, flat agent structure, skills instead of slash commands.

---

## Files Created / Modified

| # | File | Action | Status |
|---|------|--------|--------|
| 1 | `scripts/judge.py` | Created | ✅ Done |
| 2 | `scripts/init-workspace.sh` | Created | ✅ Done |
| 3 | `.shellcheckrc` | Created | ✅ Done |
| 4 | `.github/sdd/architecture/WORKFLOW_CONTRACTS.yaml` | Modified | ✅ Done |
| 5 | `build-copilot.sh` | Modified | ✅ Done |
| 6 | `build-copilot.ps1` | Modified | ✅ Done |
| 7 | `Makefile` | Created | ✅ Done |
| 8 | `.github/skills/review-judge/SKILL.md` | Created | ✅ Done |
| 9 | `docs/concepts/agent-overrides.md` | Created | ✅ Done |
| 10 | `.github/hooks/hooks.json` | Modified | ✅ Done |
| 11 | `.github/manifest.yaml` | Modified | ✅ Done |
| 12 | `docs/getting-started/judge-setup.md` | Created | ✅ Done |
| 13 | `CHANGELOG.md` | Modified | ✅ Done |

---

## Key Adaptations

### judge.py
- `LEDGER` path: `.claude/storage/` → `.github/storage/`
- `HTTP-Referer`: `luanmorenommaciel/agentspec` → `Arthur1511/agentspec-copilot`
- Full 4-phase system prompts (generic/define/design/build) preserved

### init-workspace.sh
- Project detection: `.claude/` check → `copilot-instructions.md` | `.github/`
- SDD dirs: `.claude/sdd/` → `.github/sdd/`
- Agent scaffold: flat `.github/agents/custom/` (no `workflow/` subdir)
- Agent names: fork prefixes (`de-dbt-specialist`, `cloud-supabase-specialist`, etc.)
- README references: `${CLAUDE_PLUGIN_ROOT}` → `${COPILOT_PLUGIN_ROOT}`

### WORKFLOW_CONTRACTS.yaml
- Version: `3.0.0` → `3.2.0`
- Added `agent_resolution` section documenting flat structure + priority resolution order

### manifest.yaml
- `agentspec.version`: `3.0.0` → `3.2.0`
- `skills`: `35` → `36`

### hooks.json
- Replaced inline `mkdir` commands with `bash scripts/init-workspace.sh`
- PowerShell fallback preserved for Windows environments without bash

### Build scripts (sh + ps1)
- Inserted Step 0 before Step 1: runs `scripts/generate-agent-router.py`, fails fast on error

---

## Acceptance Tests

| Test | Result |
|------|--------|
| AT-001: All 13 files created/modified | ✅ Pass |
| AT-002: judge.py uses `.github/storage/` LEDGER path | ✅ Pass |
| AT-003: init-workspace.sh uses `.github/` paths | ✅ Pass |
| AT-004: review-judge skill (36th) present | ✅ Pass |
| AT-005: manifest.yaml shows version 3.2.0, skills: 36 | ✅ Pass |
| AT-006: build-copilot.sh/ps1 have Step 0 | ✅ Pass |
| AT-007: hooks.json calls init-workspace.sh | ✅ Pass |
| AT-008: WORKFLOW_CONTRACTS.yaml has agent_resolution + version 3.2.0 | ✅ Pass |

---

## Next Steps

- `/ship` to archive this feature
- Add `OPENROUTER_API_KEY` to test judge.py end-to-end
- Optionally add `judge-ledger.jsonl` to `.gitignore`
