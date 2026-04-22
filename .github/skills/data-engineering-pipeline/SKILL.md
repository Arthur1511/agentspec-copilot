---
name: data-engineering-pipeline
description: DAG/pipeline scaffolding — delegates to architect-pipeline agent. Use when scaffolding Airflow or Dagster pipelines with best-practice patterns.
---

# Pipeline Command

> Scaffold a data pipeline (Airflow, Dagster) with best-practice patterns

## Usage

```bash
/pipeline <description-or-file>
```

## Examples

```bash
/pipeline "Daily orders ETL from Postgres to Snowflake"
/pipeline "Kafka → staging → dbt → marts with hourly refresh"
/pipeline requirements/pipeline-spec.md
```

---

## What This Command Does

1. Invokes the **architect-pipeline** agent
2. Analyzes your description or requirements file
3. Loads KB patterns from `airflow` and `dbt` domains
4. Generates:
   - DAG structure (Airflow or Dagster)
   - Task definitions with dependencies
   - Error handling and retry configuration
   - Sensor/trigger patterns for scheduling

## Agent Delegation

| Agent | Role |
|-------|------|
| `architect-pipeline` | Primary — DAG design, task orchestration |
| `de-spark-engineer` | Escalation — when pipeline includes Spark jobs |
| `de-dbt-specialist` | Escalation — when pipeline includes dbt models |

## KB Domains Used

- `airflow` — DAG patterns, operators, sensors
- `dbt` — model execution, incremental strategies
- `data-quality` — quality gates between pipeline stages

## Output

The agent generates pipeline code files and a summary of the DAG structure with task dependencies.
