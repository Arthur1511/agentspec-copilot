#!/usr/bin/env bash
# init-workspace.sh — AgentSpec Copilot CLI workspace initializer
#
# Run automatically at session start via .github/hooks/hooks.json.
# Safe to call manually too — all operations are idempotent.
#
# What it does:
#   1. Detects if the current directory is an AgentSpec-managed project
#   2. Creates SDD workspace directories (.github/sdd/)
#   3. Detects the technology stack and writes .github/sdd/.detected-stack.md
#   4. Scaffolds a .github/agents/custom/ directory for local agent overrides
#
# Exit codes: 0 = success or not an AgentSpec project (silent skip)

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────

GITHUB_DIR=".github"
SDD_DIR="${GITHUB_DIR}/sdd"
FEATURES_DIR="${SDD_DIR}/features"
REPORTS_DIR="${SDD_DIR}/reports"
ARCHIVE_DIR="${SDD_DIR}/archive"
AGENTS_DIR="${GITHUB_DIR}/agents"
CUSTOM_AGENTS_DIR="${AGENTS_DIR}/custom"
STORAGE_DIR="${GITHUB_DIR}/storage"
DETECTED_STACK="${SDD_DIR}/.detected-stack.md"

# ── Helpers ───────────────────────────────────────────────────────────────────

log()  { printf '[agentspec] %s\n' "$*" >&2; }
warn() { printf '[agentspec] WARN: %s\n' "$*" >&2; }

# ── Project detection ─────────────────────────────────────────────────────────

is_agentspec_project() {
    [[ -d ".git" ]] || [[ -f "copilot-instructions.md" ]] || [[ -d ".github" ]]
}

if ! is_agentspec_project; then
    exit 0
fi

# ── Step 1: SDD workspace directories ─────────────────────────────────────────

mkdir -p "${FEATURES_DIR}" "${REPORTS_DIR}" "${ARCHIVE_DIR}"
mkdir -p "${STORAGE_DIR}"
log "SDD workspace ready: ${SDD_DIR}"

# ── Step 2: Agent custom directory ────────────────────────────────────────────

if [[ ! -d "${CUSTOM_AGENTS_DIR}" ]]; then
    mkdir -p "${CUSTOM_AGENTS_DIR}"
    cat > "${CUSTOM_AGENTS_DIR}/README.md" <<'AGENT_README'
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
AGENT_README
    log "Custom agents directory created: ${CUSTOM_AGENTS_DIR}"
fi

# ── Step 3: Stack detection ───────────────────────────────────────────────────

detect_stack() {
    local detected=()

    # dbt
    if [[ -f "dbt_project.yml" ]] || [[ -d "models" && -f "profiles.yml" ]]; then
        detected+=("dbt")
    fi

    # Databricks / Lakeflow
    if [[ -f "databricks.yml" ]] || find . -maxdepth 3 -name "*.dlt" -o -name "databricks.yaml" 2>/dev/null | grep -q .; then
        detected+=("databricks")
    fi

    # AWS Lambda / SAM
    if [[ -f "template.yaml" ]] || [[ -f "template.yml" ]] || [[ -f "samconfig.toml" ]]; then
        if grep -qiE "AWSTemplateFormatVersion|Transform.*Serverless" template.yaml template.yml 2>/dev/null; then
            detected+=("aws-lambda-sam")
        fi
    fi

    # Airflow
    if find . -maxdepth 4 -name "*.py" 2>/dev/null | xargs grep -l "from airflow" 2>/dev/null | grep -q .; then
        detected+=("airflow")
    fi

    # Supabase
    if [[ -f "supabase/config.toml" ]] || [[ -d "supabase/migrations" ]]; then
        detected+=("supabase")
    fi

    # Terraform
    if find . -maxdepth 3 -name "*.tf" 2>/dev/null | grep -q .; then
        detected+=("terraform")
    fi

    # Spark / PySpark
    if find . -maxdepth 4 -name "*.py" 2>/dev/null | xargs grep -l "from pyspark\|import pyspark" 2>/dev/null | grep -q .; then
        detected+=("spark")
    fi

    # Streaming / Kafka
    if find . -maxdepth 4 -name "*.py" -o -name "*.java" -o -name "*.scala" 2>/dev/null | xargs grep -l "kafka\|flink\|KafkaProducer\|KafkaConsumer" 2>/dev/null | grep -q .; then
        detected+=("streaming-kafka")
    fi

    # Microsoft Fabric
    if [[ -f ".fabric/config.json" ]] || find . -maxdepth 3 -name "*.Lakehouse" -o -name "*.SemanticModel" 2>/dev/null | grep -q .; then
        detected+=("microsoft-fabric")
    fi

    # Data Quality (Great Expectations / Soda)
    if [[ -d "great_expectations" ]] || find . -maxdepth 3 -name "soda*.yml" 2>/dev/null | grep -q .; then
        detected+=("data-quality")
    fi

    # Pydantic
    if find . -maxdepth 4 -name "*.py" 2>/dev/null | xargs grep -l "from pydantic\|import pydantic" 2>/dev/null | grep -q .; then
        detected+=("pydantic")
    fi

    echo "${detected[*]:-}"
}

# ── Recommended agents per stack ──────────────────────────────────────────────

agents_for_stack() {
    local stack="$1"
    case "${stack}" in
        dbt)              echo "- \`de-dbt-specialist\` — dbt model development, testing, macros" ;;
        databricks)       echo "- \`de-lakeflow-architect\` — Databricks Lakeflow / DLT pipelines" ;;
        aws-lambda-sam)   echo "- \`cloud-aws-lambda-architect\` — SAM templates and Lambda design" ;;
        airflow)          echo "- \`de-airflow-specialist\` — Airflow 3.0 DAG development" ;;
        supabase)         echo "- \`cloud-supabase-specialist\` — pgvector, RLS, Edge Functions" ;;
        terraform)        echo "- \`cloud-ci-cd-specialist\` — Terraform modules and CI/CD pipelines" ;;
        spark)            echo "- \`de-spark-engineer\` — PySpark jobs, DataFrame transformations" ;;
        streaming-kafka)  echo "- \`de-streaming-engineer\` — Kafka, Flink, streaming SQL" ;;
        microsoft-fabric) echo "- \`fabric-architect\` — Fabric workloads, Medallion design" ;;
        data-quality)     echo "- \`test-data-quality-analyst\` — Great Expectations, Soda, dbt tests" ;;
        pydantic)         echo "- \`python-developer\` — Pydantic models, type hints, dataclasses" ;;
    esac
}

# ── Write detected-stack.md ───────────────────────────────────────────────────

write_detected_stack() {
    local detected_str="$1"
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

    {
        echo "# Detected Stack"
        echo ""
        echo "> Auto-generated by \`scripts/init-workspace.sh\` at ${now}."
        echo "> Re-run to refresh. Delete this file to force re-detection on next session."
        echo ""

        if [[ -z "${detected_str}" ]]; then
            echo "No recognized stack detected. AgentSpec will use generic agents."
            echo ""
            echo "## Recommended agents"
            echo ""
            echo "- \`architect-the-planner\` — strategic planning and implementation roadmaps"
            echo "- \`dev-codebase-explorer\` — explore unfamiliar codebases"
            echo "- \`python-code-reviewer\` — code review and quality"
            return
        fi

        echo "## Detected technologies"
        echo ""
        local stacks
        IFS=' ' read -ra stacks <<< "${detected_str}"
        for s in "${stacks[@]}"; do
            echo "- \`${s}\`"
        done
        echo ""
        echo "## Recommended agents"
        echo ""
        for s in "${stacks[@]}"; do
            agents_for_stack "${s}"
        done
        echo ""
        echo "## Data platform"
        echo ""
        echo "- \`architect-data-platform-engineer\` — cross-platform cost and provisioning decisions"
        echo "- \`architect-schema-designer\` — dimensional modeling, SCD types, schema evolution"
        echo "- \`test-data-contracts-engineer\` — ODCS contracts, SLA enforcement, governance"
    } > "${DETECTED_STACK}"
}

# Only regenerate if missing or older than 24h to avoid hammering the FS
SHOULD_DETECT=false
if [[ ! -f "${DETECTED_STACK}" ]]; then
    SHOULD_DETECT=true
elif [[ "$(find "${DETECTED_STACK}" -mmin +1440 2>/dev/null)" != "" ]]; then
    SHOULD_DETECT=true
fi

if [[ "${SHOULD_DETECT}" == "true" ]]; then
    detected=$(detect_stack)
    write_detected_stack "${detected}"
    if [[ -n "${detected}" ]]; then
        log "Stack detected: ${detected}"
    else
        log "No specific stack detected."
    fi
fi

log "Workspace initialization complete."
