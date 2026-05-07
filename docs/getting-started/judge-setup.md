# Judge Setup Guide

The `review-judge` skill provides a cross-model second opinion on your work using a non-Copilot model via OpenRouter. This guide walks you through setup, first use, and configuration.

## Prerequisites

- Python 3.9+ (already required by AgentSpec)
- An [OpenRouter](https://openrouter.ai) account and API key
- A few cents of OpenRouter credits (gpt-4o-mini costs ~$0.15 per 1M input tokens)

## Step 1: Get an OpenRouter API key

1. Sign up at [https://openrouter.ai](https://openrouter.ai)
2. Go to **Keys** → **Create key**
3. Copy the key — it starts with `sk-or-v1-`

## Step 2: Set the environment variable

```bash
# Add to your shell profile (~/.bashrc, ~/.zshrc, etc.)
export OPENROUTER_API_KEY=sk-or-v1-your-key-here

# Or set it for just the current session
export OPENROUTER_API_KEY=sk-or-v1-your-key-here
```

## Step 3: Verify setup

```bash
# This should print today's usage (0/10 calls on first run)
python3 scripts/judge.py --ledger
```

Expected output:
```
Judge Ledger — .github/storage/judge-ledger.jsonl
  Today (2026-05-07):  0 / 10 calls
  All-time:            0 calls
```

## Step 4: Run your first review

```bash
# Review any file
python3 scripts/judge.py README.md

# Review a DESIGN document with phase-tuned prompt
python3 scripts/judge.py .github/sdd/features/DESIGN_MY_FEATURE.md --phase design
```

## Ledger location

Judge calls are tracked in `.github/storage/judge-ledger.jsonl`. This file:

- Is created automatically on first use (directory is created by `init-workspace.sh`)
- Uses append-only JSONL format — safe to inspect, never truncated
- Resets the daily count at UTC midnight (entries are preserved forever)
- Should be added to `.gitignore` — it is local to your machine

```bash
# Add to .gitignore
echo ".github/storage/judge-ledger.jsonl" >> .gitignore
```

## Configuration

All configuration uses environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENROUTER_API_KEY` | *(required)* | Your OpenRouter API key |
| `JUDGE_MODEL` | phase-dependent | Override the default model |
| `JUDGE_BUDGET` | `10` | Max calls per UTC day |

### Budget management

The default budget of 10 calls/day keeps costs predictable. Raise it when doing intensive reviews:

```bash
export JUDGE_BUDGET=50   # 50 calls today
```

### Model selection

Models are selected per phase by default:

| Phase | Default model | Notes |
|-------|--------------|-------|
| `generic` | `openai/gpt-4o-mini` | Cheap, fast — good for quick reviews |
| `define` | `openai/gpt-4o` | Best for spec gap detection |
| `design` | `openai/gpt-4o` | Best for architectural review |
| `build` | `openai/gpt-4o` | Best for bug detection |

Override for a single call:
```bash
python3 scripts/judge.py src/auth.py --model anthropic/claude-3-haiku --phase build
```

Override globally:
```bash
export JUDGE_MODEL=openai/gpt-4o   # use gpt-4o for all calls
```

## Usage patterns

### Review before `/design`

```bash
python3 scripts/judge.py .github/sdd/features/DEFINE_FEATURE.md \
  --phase define \
  --context "Requirements for new ETL pipeline from Postgres to Snowflake"
```

### Review before `/build`

```bash
python3 scripts/judge.py .github/sdd/features/DESIGN_FEATURE.md \
  --phase design \
  --context "Architecture design — check for missing edge cases and unsafe patterns"
```

### Review code before merging

```bash
python3 scripts/judge.py src/pipeline/transform.py \
  --phase build \
  --context "PySpark transformation job — check for data loss risks and performance issues"
```

### Review a focused excerpt

For files over 200KB or when you want targeted feedback:

```bash
# Pipe a specific section
sed -n '50,150p' large_file.py | python3 scripts/judge.py --stdin \
  --phase build \
  --context "Authentication middleware — check for JWT validation correctness"
```

### Emit JSON for automation

```bash
python3 scripts/judge.py src/auth.py --json | jq '.verdict'
```

## Interpreting results

Judge returns a markdown verdict with:

- **PASS / FAIL** — based on high-severity concerns and confidence ≥ 0.70
- **Confidence** — 0.0–1.0 (below 0.70 forces FAIL)
- **Concerns table** — severity (high/medium/low), issue, evidence (file:line or quoted text)
- **Suggested fixes** — actionable next steps

**Judge is advisory.** A FAIL verdict does not block anything — it is an input to your judgment, not a gate.

## Exit codes for CI integration

| Code | Meaning |
|------|---------|
| `0` | PASS — no high-severity issues |
| `1` | FAIL — high-severity issue or low confidence |
| `2` | Config error — missing key or bad args |
| `3` | Budget exceeded |
| `4` | Network or API error |

```bash
# Optional CI integration (non-blocking by default)
python3 scripts/judge.py src/auth.py --phase build || echo "Judge flagged issues — review output above"
```

## Troubleshooting

**`OPENROUTER_API_KEY not set`**
→ Export the variable: `export OPENROUTER_API_KEY=sk-or-v1-...`

**`Daily budget exhausted`**
→ Raise via `export JUDGE_BUDGET=50` or wait until UTC midnight.

**`File exceeds 200KB`**
→ Pipe a focused section using `--stdin`.

**`OpenRouter HTTP 401`**
→ Invalid or expired API key. Generate a new one at https://openrouter.ai/keys.

**`OpenRouter HTTP 429`**
→ Rate limited. Wait a minute and retry, or switch to a less loaded model.
