---
name: create-pr
description: |
  Create a pull request with conventional commits and a structured description.
  Supports GitHub and Azure DevOps — platform is auto-detected from the git remote.
  Use when the user wants to open a PR, commit changes, or submit work for review.
---

# Create PR Command

> Automate professional pull request creation with conventional commits and structured descriptions — for both **GitHub** and **Azure DevOps**

## Usage

```bash
/create-pr                           # Auto-detect platform and create PR
/create-pr "feat: add user auth"     # Create PR with custom title
/create-pr --draft                   # Create as draft PR
/create-pr --review                  # Run dual AI review before PR creation
/create-pr --review --draft          # Review + create as draft
```

---

## Platform Detection

At the start of every run, detect the remote platform:

```bash
git remote get-url origin
```

| Remote URL Pattern | Platform |
|--------------------|----------|
| `*github.com*` | **GitHub** → use `gh` CLI |
| `*dev.azure.com*` or `*visualstudio.com*` | **Azure DevOps** → use `az repos` CLI |

Extract Azure DevOps coordinates when applicable:

```bash
# URL format A (modern):  https://dev.azure.com/{org}/{project}/_git/{repo}
# URL format B (legacy):  https://{org}.visualstudio.com/{project}/_git/{repo}
#
# Example (legacy):
#   https://myorg.visualstudio.com/My%20Project/_git/my-repo
#   → org:     myorg
#   → project: My Project       (URL-decode %20 → space)
#   → repo:    my-repo

REMOTE_URL=$(git remote get-url origin)

# For legacy visualstudio.com URLs, extract:
#   ADO_ORG     = https://<subdomain>.visualstudio.com
#   ADO_PROJECT = URL-decoded path segment before /_git/
#   ADO_REPO    = path segment after /_git/

ADO_ORG="https://<org>.visualstudio.com"   # or https://dev.azure.com/<org>
ADO_PROJECT="<project>"                     # URL-decode if percent-encoded (e.g. My%20Project → "My Project")
ADO_REPO="<repo>"
```

> **Note:** Project names may be URL-encoded (e.g. `My%20Project`). Always decode before passing to `az repos` commands — the CLI accepts the human-readable name.

> If the platform cannot be determined, ask the user: **"Is this a GitHub or Azure DevOps repository?"**

---

## Pre-PR Review Option

When using `--review`, the command runs a **dual AI review** (CodeRabbit + Claude) before creating the PR:

```text
┌─────────────────────────────────────────────────────────────────┐
│                  /create-pr --review WORKFLOW                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   1. Analyze Changes                                             │
│          ↓                                                       │
│   2. Run CodeRabbit CLI (static analysis)                       │
│          ↓                                                       │
│   3. Run Claude Review (architectural)                          │
│          ↓                                                       │
│   4. Check for Critical Issues                                  │
│          ↓                                                       │
│   ┌──────┴──────┐                                               │
│   │             │                                                │
│   ▼             ▼                                                │
│ Critical     No Critical                                         │
│ Issues       Issues                                              │
│   │             │                                                │
│   ▼             ▼                                                │
│ STOP &       Continue                                            │
│ Show         to PR                                               │
│ Issues       Creation                                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Review Behavior

| Review Result | Action |
|---------------|--------|
| 🔴 Critical issues found | Stop and show issues, do not create PR |
| 🟠 Errors found | Warn user, ask to continue or fix |
| 🟡 Warnings only | Continue to PR, include warnings in description |
| ✅ Clean | Continue to PR |

### Review Integration

```bash
# Run CodeRabbit + Claude review
source ~/.zshrc && coderabbit review --plain 2>&1

# Parse results and check for blockers
# If critical issues: STOP
# If errors: ASK user
# Otherwise: CONTINUE
```

---

## Overview

This command streamlines PR creation by:

1. **Detecting** the remote platform (GitHub or Azure DevOps)
2. **Analyzing** all staged/unstaged changes
3. **Categorizing** changes by type (feat/fix/refactor/docs)
4. **Generating** conventional commit messages
5. **Building** structured PR descriptions with test plans
6. **Creating** the PR via the appropriate CLI (`gh` for GitHub, `az repos` for Azure DevOps)

---

## Process

### Step 1: Analyze Changes

```bash
# Run these commands to understand the change scope
git status
git diff --stat
git log origin/main..HEAD --oneline
```

Categorize files into change types:

```text
CHANGE CATEGORIES
═════════════════

feat:     New features, capabilities
fix:      Bug fixes, error corrections
refactor: Code restructuring, no behavior change
docs:     Documentation only
test:     Test additions or corrections
chore:    Build, CI/CD, dependencies
style:    Formatting, whitespace
perf:     Performance improvements
```

### Step 2: Determine PR Type

Based on file analysis, identify the primary change type:

| Files Changed | Likely Type |
|---------------|-------------|
| `src/**/*.py` + new functionality | `feat:` |
| `src/**/*.py` + bug fix | `fix:` |
| `src/**/*.py` + restructure | `refactor:` |
| `*.md`, `docs/**` | `docs:` |
| `tests/**`, `*_test.py` | `test:` |
| `.github/**`, `Makefile`, `pyproject.toml` | `chore:` |
| `.github/agents/**` | `refactor(agents):` |
| `.github/kb/**` | `docs(kb):` |
| `.github/sdd/**` | `docs(sdd):` |

### Step 3: Generate Commit Message

Use Conventional Commits format:

```text
<type>(<scope>): <short description>

<body - what changed and why>

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Examples:**

```text
feat(auth): add OAuth2 token refresh flow

- Implement OAuth2 token refresh with PKCE
- Add backward compatibility for session-based auth
- Update validation rules for new token format

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Step 4: Ask Clarifying Questions

Use AskUserQuestion to confirm:

**Question 1: PR Type**
- Does this categorization look correct?
- Options: feat, fix, refactor, docs, test, chore

**Question 2: Scope**
- What component/area does this affect?
- Options: Based on detected file paths (e.g., parser, agents, kb, api)

**Question 3: Breaking Changes**
- Are there any breaking changes?
- Options: Yes (describe), No

**Question 4: Related Items** *(platform-aware)*
- **GitHub**: Link to any related issues? (e.g., "Closes #123")
- **Azure DevOps**: Link to any related work items? (e.g., work item IDs: `1234 5678`)

### Step 5: Build PR Description

Generate structured description following this template:

```markdown
## Summary

{2-3 bullet points describing the change}

### Key Changes
- {Primary change 1}
- {Primary change 2}
- {Primary change 3}

## What's Changed

### {Category 1}
{Description of changes in this category}

### {Category 2}
{Description of changes in this category}

## Files Changed

| Category | Files | Description |
|----------|-------|-------------|
| {cat1} | {count} | {brief description} |
| {cat2} | {count} | {brief description} |

## Test Plan

- [ ] {Test case 1}
- [ ] {Test case 2}
- [ ] {Test case 3}

## Breaking Changes

{Describe breaking changes or "None"}

## Related Items

{GitHub: "Closes #XXX" | Azure DevOps: "Work Items: #1234 #5678" | "None"}

---

Generated with [GitHub Copilot](https://github.com/features/copilot)
```

### Step 6: Create Branch (if needed)

```bash
# If on main, create feature branch
git checkout -b <type>/<short-description>

# Examples:
git checkout -b feat/user-authentication
git checkout -b fix/parser-null-handling
git checkout -b refactor/agents-standardization
```

### Step 7: Commit and Push

```bash
# Stage all changes (or specific files)
git add -A

# Commit with conventional message
git commit -m "<message>"

# Push with upstream tracking
git push -u origin <branch-name>
```

### Step 8: Create PR

#### GitHub

```bash
gh pr create \
  --title "<type>(<scope>): <description>" \
  --body "<generated-body>" \
  --base main
```

For draft PRs:
```bash
gh pr create --draft \
  --title "<type>(<scope>): <description>" \
  --body "<generated-body>" \
  --base main
```

#### Azure DevOps

Requires the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with the `azure-devops` extension:

```bash
# One-time setup (if not already installed)
az extension add --name azure-devops
az devops configure --defaults organization=$ADO_ORG project=$ADO_PROJECT
```

```bash
az repos pr create \
  --title "<type>(<scope>): <description>" \
  --description "<generated-body>" \
  --source-branch "<branch-name>" \
  --target-branch main \
  --repository "$ADO_REPO" \
  --project "$ADO_PROJECT" \
  --organization "$ADO_ORG"
```

For draft PRs:
```bash
az repos pr create --draft \
  --title "<type>(<scope>): <description>" \
  --description "<generated-body>" \
  --source-branch "<branch-name>" \
  --target-branch main \
  --repository "$ADO_REPO" \
  --project "$ADO_PROJECT" \
  --organization "$ADO_ORG"
```

Linking work items:
```bash
az repos pr create \
  ... \
  --work-items 1234 5678
```

After PR creation, set reviewers (optional):
```bash
az repos pr reviewer add \
  --id <pr-id> \
  --reviewers "user@org.com" "team@org.com"
```

---

## Output

| Field | GitHub | Azure DevOps |
|-------|--------|--------------|
| **Branch** | `<type>/<short-description>` | `<type>/<short-description>` |
| **Commit** | Conventional commit format | Conventional commit format |
| **PR URL** | `https://github.com/org/repo/pull/<id>` | `https://dev.azure.com/org/project/_git/repo/pullrequest/<id>` |

---

## Quality Checklist

Before creating PR, verify:

```text
COMMIT MESSAGE
[ ] Uses conventional commits format
[ ] Type matches the primary change
[ ] Scope is specific and meaningful
[ ] Description is concise (< 72 chars)

PR DESCRIPTION
[ ] Summary explains WHY not just WHAT
[ ] Files changed table is accurate
[ ] Test plan has actionable items
[ ] Breaking changes documented (if any)

BRANCH
[ ] Branch name matches convention
[ ] Not committing directly to main
[ ] All changes are staged
```

---

## Conventional Commits Reference

| Type | When to Use | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(api): add user endpoint` |
| `fix` | Bug fix | `fix(parser): handle null dates` |
| `refactor` | Code restructure | `refactor(auth): extract token service` |
| `docs` | Documentation | `docs(readme): add setup instructions` |
| `test` | Tests | `test(parser): add edge case coverage` |
| `chore` | Maintenance | `chore(deps): update dependencies` |
| `style` | Formatting | `style: apply black formatting` |
| `perf` | Performance | `perf(query): add index for lookups` |
| `ci` | CI/CD | `ci: add github actions workflow` |
| `build` | Build system | `build: update dockerfile` |

**Scopes for this project:**

| Scope | Applies To |
|-------|------------|
| `agents` | `.github/agents/**` |
| `kb` | `.github/kb/**` |
| `sdd` | `.github/sdd/**` |
| `commands` | `.github/commands/**` |
| `handlers` | `src/handlers/**` |
| `services` | `src/services/**` |
| `api` | `src/api/**` |
| `infra` | `terraform/**`, `infrastructure/**` |
| `ci` | `.github/**` |

---

## Examples

### Example 1: Feature PR (GitHub)

```bash
/create-pr

# Detected: New files in src/handlers/, remote: github.com
# Suggested: feat(auth): add OAuth2 refresh support

→ Created branch: feat/oauth2-refresh
→ Committed: feat(auth): add OAuth2 token refresh
→ PR: https://github.com/org/repo/pull/42
```

### Example 2: Refactor PR (GitHub)

```bash
/create-pr "refactor(agents): standardize agent definitions"

→ Created branch: refactor/agents-standardization
→ Committed: refactor(agents): standardize agent definitions
→ PR: https://github.com/org/repo/pull/43
```

### Example 3: Documentation PR — Draft (GitHub)

```bash
/create-pr --draft

# Detected: Changes in .github/kb/
# Suggested: docs(kb): add redis caching patterns

→ Created branch: docs/kb-redis-patterns
→ Committed: docs(kb): add redis caching patterns
→ Draft PR: https://github.com/org/repo/pull/44
```

### Example 4: Feature PR (Azure DevOps)

```bash
/create-pr

# Detected: New files in src/handlers/
# Remote: https://myorg.visualstudio.com/My%20Project/_git/my-repo
#   → Org:     https://myorg.visualstudio.com
#   → Project: My Project
#   → Repo:    my-repo
# Suggested: feat(auth): add OAuth2 refresh support

→ Created branch: feat/oauth2-refresh
→ Committed: feat(auth): add OAuth2 token refresh
→ PR: https://myorg.visualstudio.com/My%20Project/_git/my-repo/pullrequest/101
```

### Example 5: Bug Fix PR with Work Item (Azure DevOps)

```bash
/create-pr "fix(parser): handle null date values"

# Remote: https://myorg.visualstudio.com/My%20Project/_git/my-repo
# Linked work item: 4521
→ Created branch: fix/parser-null-dates
→ Committed: fix(parser): handle null date values
→ PR: https://myorg.visualstudio.com/My%20Project/_git/my-repo/pullrequest/102
→ Work Item #4521 linked
```

### Example 6: Draft PR (Azure DevOps)

```bash
/create-pr --draft

# Remote: https://myorg.visualstudio.com/My%20Project/_git/my-repo
# Suggested: feat(api): add pagination support

→ Created branch: feat/api-pagination
→ Draft PR: https://myorg.visualstudio.com/My%20Project/_git/my-repo/pullrequest/103
```

---

## Tips

1. **Keep PRs Small** — Aim for < 400 lines changed
2. **One Concern Per PR** — Don't mix features with refactors
3. **Write for Reviewers** — Assume they don't know the context
4. **Link Issues** — Use "Closes #XX" to auto-close issues
5. **Test Plan Matters** — Reviewers should know how to verify
