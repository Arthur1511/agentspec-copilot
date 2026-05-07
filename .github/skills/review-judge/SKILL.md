---
name: judge
description: |
  Second-opinion reviewer using a non-Copilot model via OpenRouter. Sends a file or
  phase document to an independent LLM and returns a PASS/FAIL verdict with severity-
  ranked concerns. Phase-aware: uses tuned prompts for define, design, build, or generic reviews.

  Requires `OPENROUTER_API_KEY` environment variable.

  <example>
  Context: User wants an independent review of a DESIGN document
  user: "Judge this design document before I build it"
  assistant: "I'll use the review-judge skill to get a second opinion on the design."
  </example>

  <example>
  Context: User wants to review code before merging
  user: "Run the judge on scripts/parse_orders.py"
  assistant: "I'll invoke review-judge to get an independent assessment of the code."
  </example>

  <example>
  Context: User wants to check daily budget usage
  user: "How many judge calls have I used today?"
  assistant: "I'll check the judge ledger for today's usage."
  </example>
model: Claude Sonnet 4.5
tools:
  - execute
  - read
---

# review-judge Skill

> Cross-model second opinion via OpenRouter — catches what Copilot's self-review misses.

## Prerequisites

```bash
export OPENROUTER_API_KEY=sk-or-v1-...   # https://openrouter.ai/keys
```

Optional env vars:
```bash
export JUDGE_MODEL=openai/gpt-4o         # override model (default: phase-dependent)
export JUDGE_BUDGET=20                   # max calls per UTC day (default: 10)
```

## Usage

```bash
# Review a specific file (generic phase)
python3 scripts/judge.py <file>

# Review with phase-tuned prompt (better signal for SDD docs)
python3 scripts/judge.py .github/sdd/features/DEFINE_FEATURE.md --phase define
python3 scripts/judge.py .github/sdd/features/DESIGN_FEATURE.md --phase design
python3 scripts/judge.py src/my_module.py --phase build

# Pipe content from stdin
cat DESIGN_FEATURE.md | python3 scripts/judge.py --stdin --phase design

# With custom context (helps the model understand intent)
python3 scripts/judge.py src/auth.py \
  --context "JWT auth module — check for security issues and logic errors" \
  --phase build

# Use a specific model
python3 scripts/judge.py report.md --model anthropic/claude-3-haiku

# Check today's budget usage
python3 scripts/judge.py --ledger

# Emit raw JSON verdict instead of markdown
python3 scripts/judge.py DESIGN.md --json
```

## Phase defaults

| `--phase`  | Default model         | System prompt focus                         |
|------------|-----------------------|---------------------------------------------|
| `generic`  | `openai/gpt-4o-mini`  | General correctness, logic, security        |
| `define`   | `openai/gpt-4o`       | Spec clarity, testability, scope gaps       |
| `design`   | `openai/gpt-4o`       | Architectural soundness, missing edge cases |
| `build`    | `openai/gpt-4o`       | Concrete bugs, error handling, security     |

## Exit codes

| Code | Meaning                                     |
|------|---------------------------------------------|
| `0`  | Verdict = PASS                              |
| `1`  | Verdict = FAIL                              |
| `2`  | Config error (missing key, bad args)        |
| `3`  | Budget exceeded                             |
| `4`  | Network or API error                        |

## Invocation steps

1. **Check prerequisites** — verify `OPENROUTER_API_KEY` is set
2. **Resolve file** — read target or read from stdin
3. **Budget check** — read `JUDGE_BUDGET` (default 10) and today's ledger count
4. **Call OpenRouter** — send content + phase-tuned system prompt
5. **Render verdict** — display markdown table with PASS/FAIL + concerns
6. **Append ledger** — write result to `.github/storage/judge-ledger.jsonl`

## Ledger

Judge calls are tracked in `.github/storage/judge-ledger.jsonl` (append-only JSONL).
This file is in `.gitignore` by default — it is local to your machine.

```bash
python3 scripts/judge.py --ledger   # show today's count and recent calls
```

## Notes

- Judge is **advisory**: FAIL does not block anything; final call is yours.
- File size limit: 200KB. For larger files, pipe a focused excerpt via `--stdin`.
- The ledger budget resets at UTC midnight each day.
- See `docs/getting-started/judge-setup.md` for full setup instructions.
