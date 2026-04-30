# Getting Started with AgentSpec

Get from zero to your first spec-driven data pipeline in 10 minutes.

## Prerequisites

- [GitHub Copilot CLI](https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-in-the-command-line) installed and authenticated
- Git

## Installation

### Install the Plugin (Recommended)

```bash
copilot plugin install Arthur1511/agentspec-copilot:plugin-copilot
```

Or test locally from source:

```bash
git clone https://github.com/Arthur1511/agentspec-copilot.git
cd agentspec-copilot
./build-copilot.sh   # Linux/macOS
.\build-copilot.ps1  # Windows PowerShell
```

## Framework Structure

The plugin ships 58 agents, 35 skills, and 24 KB domains under `.github/`:

```text
.github/
├── agents/              # 58 specialized agents (flat directory)
├── skills/              # 35 skills (each directory has SKILL.md)
│   ├── workflow-*/      # 7 SDD phase skills
│   ├── data-engineering-*/ # 9 DE skills
│   ├── visual-explainer-*/ # 9 visual documentation skills
│   ├── core-*/          # 5 utility skills
│   └── ...              # 5 more standalone skills
├── sdd/
│   ├── features/        # Active WIP feature documents
│   ├── reports/         # Build reports
│   ├── archive/         # Shipped features
│   └── templates/       # 5 phase document templates
└── kb/                  # 24 data engineering KB domains
```

## Your First Data Pipeline (5 minutes)

Let's build an orders pipeline using the full SDD workflow. Invoke skills with `/agentspec:<skill-name>`:

### Step 1: Brainstorm (Optional)

Explore your idea through guided dialogue:

```
/agentspec:workflow-brainstorm "Daily orders pipeline from Postgres to Snowflake with star schema"
```

AgentSpec asks targeted questions about source systems, volumes, freshness SLAs, and consumer needs. Output: `.github/sdd/features/BRAINSTORM_ORDERS_PIPELINE.md`

### Step 2: Define Requirements

Capture formal requirements with data contracts:

```
/agentspec:workflow-define ORDERS_PIPELINE
```

Output: `.github/sdd/features/DEFINE_ORDERS_PIPELINE.md` with:

- Problem statement and users
- Data contract (schema, SLAs, lineage)
- Source inventory (volumes, freshness)
- Clarity Score (must reach 12/15 to proceed)

### Step 3: Design Architecture

Create the pipeline architecture:

```
/agentspec:workflow-design ORDERS_PIPELINE
```

Output: `.github/sdd/features/DESIGN_ORDERS_PIPELINE.md` with:

- Architecture diagram with DAG structure
- Partition strategy and incremental approach
- File manifest with agent assignments (`@dbt-specialist`, `@airflow-specialist`, `@spark-engineer`)
- Schema evolution plan and data quality gates

### Step 4: Build

Execute the implementation with agent delegation:

```
/agentspec:workflow-build ORDERS_PIPELINE
```

AgentSpec delegates dbt models to `@dbt-specialist`, DAGs to `@airflow-specialist`, Spark jobs to `@spark-engineer`, and quality checks to `@data-quality-analyst`. Output: `.github/sdd/reports/BUILD_REPORT_ORDERS_PIPELINE.md`

### Step 5: Ship

Archive everything with lessons learned:

```
/agentspec:workflow-ship ORDERS_PIPELINE
```

## Quick Data Engineering Skills

Don't need the full SDD workflow? Use skills directly:

```
# Design a star schema
/agentspec:data-engineering-schema "Star schema for e-commerce analytics"

# Scaffold an Airflow DAG
/agentspec:data-engineering-pipeline "Daily orders ETL from Postgres to Snowflake"

# Generate quality checks for a model
/agentspec:data-engineering-data-quality models/staging/stg_orders.sql

# Review SQL for anti-patterns
/agentspec:data-engineering-sql-review models/marts/

# Migrate legacy stored procedures
/agentspec:data-engineering-migrate legacy/etl_orders_proc.sql

# Author a data contract
/agentspec:data-engineering-data-contract "Contract between orders team and analytics"
```

## What's Next

- [Core Concepts](../concepts/) — understand how phases, agents, and KB work together
- [Tutorials](../tutorials/) — dbt, star schema, data quality, Spark, streaming, RAG walkthroughs
- [Reference](../reference/) — full skill, agent, and KB domain catalog

## Troubleshooting

**Skills not recognized?**
Ensure the plugin is installed: `copilot plugin install Arthur1511/agentspec-copilot:plugin-copilot`

**Agent not matching?**
Check that `.github/agents/` contains the agent `.md` files in the installed plugin.

**Clarity score too low?**
The `/agentspec:workflow-define` phase requires 12/15 to proceed. For data pipelines, ensure Source Inventory, Schema Contract, and Freshness SLAs are populated.

**KB domain not loading?**
Check `.github/kb/_index.yaml` — the domain must be registered there. All 24 KB domains come pre-configured.

