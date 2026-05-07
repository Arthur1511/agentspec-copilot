---
name: migrate
description: Legacy ETL migration — delegates to de-dbt-specialist and de-spark-engineer agents. Use when converting stored procedures, SSIS packages, or Informatica workflows to modern stack.
---

# Migrate Command

> Migrate legacy ETL (stored procedures, SSIS, Informatica) to modern stack

## Usage

```bash
/migrate <description-or-file>
```

## Examples

```bash
/migrate "Convert stored procedures to dbt models"
/migrate legacy/etl_orders_proc.sql
/migrate "Migrate Informatica workflows to Airflow + dbt"
/migrate "Move SSIS packages to Spark + Iceberg"
```

---

## What This Command Does

1. Analyzes legacy ETL code or description
2. Invokes the appropriate agent based on target stack
3. Loads KB patterns from `dbt`, `spark`, and `airflow` domains
4. Generates:
   - Equivalent modern code (dbt models, PySpark jobs, Airflow DAGs)
   - Migration mapping (source → target)
   - Data validation queries to compare old vs new output
   - Rollback strategy documentation

## Agent Delegation

| Agent | Role |
|-------|------|
| `de-dbt-specialist` | Primary — stored proc → dbt model conversion |
| `de-spark-engineer` | Primary — heavy ETL → PySpark conversion |
| `architect-pipeline` | Escalation — orchestration migration |
| `de-sql-optimizer` | Escalation — query optimization during migration |

## KB Domains Used

- `dbt` — model patterns, incremental strategies, macros
- `spark` — PySpark patterns, DataFrame transformations
- `airflow` — DAG patterns, operator selection
- `sql-patterns` — cross-dialect SQL translation

## Output

The agent generates modern code equivalents, a migration checklist, and validation queries to ensure data parity.
