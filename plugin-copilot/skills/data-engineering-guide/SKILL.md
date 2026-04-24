---
name: data-engineering-guide
description: |
  Data engineering expertise for pipelines, schemas, data quality, SQL, lakehouse, and streaming.
  Use PROACTIVELY when the user discusses data pipelines, ETL/ELT, schema design, dimensional modeling,
  data quality checks, SQL optimization, dbt models, Spark jobs, Airflow DAGs, streaming pipelines,
  lakehouse architecture, or data contracts.
---

# Data Engineering Guide

You have access to 24 specialized knowledge base domains and 15+ data engineering agents. Route the user to the right tool based on their task.

## Quick Routing

| User Task | Skill | Agent |
|-----------|-------|-------|
| Design a data pipeline / DAG | `/agentspec:data-engineering-pipeline` | `/agentspec:architect-pipeline` |
| Design a schema / star schema / data model | `/agentspec:data-engineering-schema` | `/agentspec:architect-schema-designer` |
| Add data quality checks | `/agentspec:data-engineering-data-quality` | `/agentspec:test-data-quality-analyst` |
| Review SQL performance | `/agentspec:data-engineering-sql-review` | `/agentspec:de-sql-optimizer` |
| Choose table format (Iceberg/Delta) | `/agentspec:data-engineering-lakehouse` | `/agentspec:architect-lakehouse` |
| Build RAG / embedding pipeline | `/agentspec:data-engineering-ai-pipeline` | `/agentspec:de-ai-data-engineer` |
| Create a data contract | `/agentspec:data-engineering-data-contract` | `/agentspec:test-data-contracts-engineer` |
| Migrate legacy ETL | `/agentspec:data-engineering-migrate` | `/agentspec:de-dbt-specialist` + `/agentspec:de-spark-engineer` |

## Knowledge Domains Available

| Category | Domains |
|----------|---------|
| Core DE | `dbt`, `spark`, `airflow`, `streaming`, `sql-patterns` |
| Data Design | `data-modeling`, `data-quality`, `medallion` |
| Infrastructure | `lakehouse`, `cloud-platforms`, `aws`, `gcp`, `microsoft-fabric`, `lakeflow`, `terraform` |
| AI & Modern | `ai-data-engineering`, `genai`, `prompt-engineering`, `modern-stack` |
| Foundations | `pydantic`, `python`, `testing`, `xgboost`, `supabase` |

## How Agents Use Knowledge

1. Agent reads KB index at `${COPILOT_PLUGIN_ROOT}/kb/{domain}/index.md`
2. Loads specific pattern/concept file matching the task
3. Falls back to MCP if KB insufficient (max 3 MCP calls)
4. Calculates confidence from evidence matrix

## When to Suggest Skills

- User mentions "dbt model" or "staging model" → `data-engineering-schema` or delegate to `de-dbt-specialist`
- User mentions "pipeline" or "DAG" or "orchestration" → `data-engineering-pipeline`
- User mentions "data quality" or "expectations" or "tests" → `data-engineering-data-quality`
- User mentions "slow query" or "optimize SQL" → `data-engineering-sql-review`
- User mentions "Iceberg" or "Delta Lake" or "table format" → `data-engineering-lakehouse`
- User mentions "RAG" or "embeddings" or "vector" → `data-engineering-ai-pipeline`
- User mentions "contract" or "SLA" or "schema governance" → `data-engineering-data-contract`
- User mentions "migrate" or "legacy" or "SSIS" or "Informatica" → `data-engineering-migrate`
