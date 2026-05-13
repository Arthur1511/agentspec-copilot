---
name: agent-router
description: Intelligent agent routing -- automatically matches tasks to the best specialist agent based on file patterns, intent keywords, and domain context. Loaded every session to give Copilot explicit routing rules for all 66 AgentSpec agents.
---

<!-- =========================================================================
     GENERATED FILE — DO NOT EDIT BY HAND
     Source of truth: ${COPILOT_PLUGIN_ROOT}/agents/*.agent.md frontmatter
     Regenerate:      python3 scripts/generate-agent-router.py
     CI check:        python3 scripts/generate-agent-router.py --check
     ========================================================================= -->

# Agent Router

Explicit routing rules for matching tasks to the correct specialist agent. Generated from each agent's frontmatter, so any change to an agent's `description`, `kb_domains`, or `escalation_rules` flows here automatically.

**Agent count:** 66  |  **Categories:** 9  |  **Content hash:** `d78b10c448e6`

## A. Agents by Category

### SDD Workflow
*Brainstorm, Define, Design, Build, Ship, Iterate*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `agentspec:brainstorm-agent` | T2 | sonnet | — | `agentspec:define-agent` |
| `agentspec:build-agent` | T2 | sonnet | — | `agentspec:design-agent` |
| `agentspec:define-agent` | T2 | sonnet | — | `agentspec:design-agent` |
| `agentspec:design-agent` | T2 | sonnet | — | `agentspec:build-agent` |
| `agentspec:iterate-agent` | T2 | sonnet | — | `agentspec:define-agent`, `agentspec:design-agent`, `agentspec:build-agent` |
| `agentspec:ship-agent` | T2 | sonnet | — | `agentspec:build-agent` |

### Architecture & Design
*System-level design, schemas, pipelines, lakehouse*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `architect-data-platform-engineer` | T2 | sonnet | `cloud-platforms`, `lakehouse`, `data-modeling` | `architect-lakehouse`, `architect-pipeline`, `architect-schema-designer` |
| `architect-genai` | T1 | sonnet | `genai`, `prompt-engineering`, `ai-data-engineering` | — |
| `architect-kb` | T2 | sonnet | — | `user` |
| `architect-lakehouse` | T2 | sonnet | `lakehouse`, `spark`, `data-modeling` | `architect-data-platform-engineer`, `de-spark-engineer`, `architect-schema-designer` |
| `architect-medallion` | T1 | sonnet | `medallion`, `data-modeling`, `lakehouse`, `data-quality` | — |
| `architect-pipeline` | T2 | sonnet | `airflow`, `data-quality`, `dbt` | `de-dbt-specialist`, `de-spark-engineer`, `de-streaming-engineer` |
| `architect-schema-designer` | T2 | sonnet | `data-modeling`, `sql-patterns`, `data-quality` | `de-dbt-specialist`, `architect-lakehouse`, `test-data-quality-analyst`, `de-sql-optimizer` |
| `architect-the-planner` | T2 | sonnet | — | `user` |

### Cloud & Infrastructure
*AWS, GCP, CI/CD, deployment*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `cloud-ai-data-engineer-cloud` | T3 | sonnet | `gcp`, `aws`, `terraform`, `data-quality`, `cloud-platforms` | `cloud-ai-data-engineer-gcp`, `cloud-aws-data-architect`, `user` |
| `cloud-ai-data-engineer-gcp` | T2 | sonnet | `gcp`, `terraform`, `cloud-platforms`, `data-quality` | `cloud-aws-data-architect`, `user` |
| `cloud-ai-prompt-specialist-gcp` | T3 | sonnet | `prompt-engineering`, `genai`, `pydantic`, `gcp` | `cloud-gcp-data-architect`, `user` |
| `cloud-aws-data-architect` | T1 | sonnet | `aws`, `terraform`, `data-quality` | — |
| `cloud-aws-deployer` | T3 | sonnet | `aws`, `terraform` | `cloud-aws-lambda-architect`, `cloud-ci-cd-specialist`, `user` |
| `cloud-aws-lambda-architect` | T3 | sonnet | `aws`, `terraform` | `cloud-aws-deployer`, `cloud-lambda-builder`, `user` |
| `cloud-ci-cd-specialist` | T3 | sonnet | `terraform`, `aws`, `lakeflow` | `cloud-lambda-builder`, `cloud-aws-lambda-architect`, `user` |
| `cloud-gcp-data-architect` | T1 | sonnet | `gcp`, `terraform`, `cloud-platforms`, `data-quality` | — |
| `cloud-lambda-builder` | T3 | sonnet | `aws`, `python`, `testing` | `cloud-aws-lambda-architect`, `cloud-aws-deployer`, `user` |
| `cloud-supabase-specialist` | T3 | sonnet | `supabase`, `ai-data-engineering`, `data-modeling` | `cloud-gcp-data-architect`, `cloud-aws-data-architect`, `user` |

### Data Engineering
*dbt, Spark, SQL, Airflow, streaming, data quality*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `de-ai-data-engineer` | T2 | sonnet | `ai-data-engineering`, `data-quality`, `streaming` | `architect-pipeline`, `de-spark-engineer`, `de-streaming-engineer`, `test-data-quality-analyst` |
| `de-airflow-specialist` | T3 | sonnet | `airflow`, `sql-patterns`, `data-quality` | `de-spark-engineer`, `de-dbt-specialist`, `de-streaming-engineer` |
| `de-dbt-specialist` | T2 | sonnet | `dbt`, `data-quality`, `sql-patterns` | `architect-schema-designer`, `de-spark-engineer`, `architect-pipeline`, `test-data-quality-analyst` |
| `de-lakeflow-architect` | T3 | sonnet | `lakeflow`, `lakehouse`, `spark`, `medallion` | `de-spark-engineer`, `de-dbt-specialist`, `de-airflow-specialist` |
| `de-lakeflow-expert` | T3 | sonnet | `lakeflow`, `lakehouse`, `data-quality`, `medallion` | `de-spark-engineer`, `de-airflow-specialist`, `architect-schema-designer` |
| `de-lakeflow-pipeline-builder` | T3 | sonnet | `lakeflow`, `lakehouse`, `data-quality`, `medallion` | `de-spark-engineer`, `de-airflow-specialist`, `architect-schema-designer` |
| `de-lakeflow-specialist` | T1 | sonnet | `lakeflow`, `lakehouse`, `spark`, `data-quality` | — |
| `de-qdrant-specialist` | T3 | sonnet | `ai-data-engineering`, `genai` | `de-ai-data-engineer`, `de-spark-engineer`, `de-ai-data-engineer` |
| `de-spark-engineer` | T2 | sonnet | `spark`, `sql-patterns`, `streaming` | `architect-pipeline`, `de-dbt-specialist`, `architect-lakehouse` |
| `de-spark-performance-analyzer` | T1 | sonnet | `spark`, `cloud-platforms`, `lakehouse` | — |
| `de-spark-specialist` | T2 | sonnet | `spark`, `sql-patterns`, `cloud-platforms` | `architect-pipeline`, `de-dbt-specialist`, `architect-lakehouse` |
| `de-spark-streaming-architect` | T3 | sonnet | `spark`, `streaming`, `lakehouse` | `de-spark-engineer`, `de-streaming-engineer`, `de-airflow-specialist` |
| `de-spark-troubleshooter` | T1 | sonnet | `spark`, `sql-patterns` | — |
| `de-sql-optimizer` | T2 | sonnet | `sql-patterns`, `data-modeling`, `dbt` | `de-spark-engineer`, `architect-schema-designer`, `de-dbt-specialist` |
| `de-streaming-engineer` | T2 | sonnet | `streaming`, `spark`, `sql-patterns` | `architect-pipeline`, `de-dbt-specialist`, `architect-lakehouse`, `de-ai-data-engineer` |

### Developer Tools
*Codebase exploration, meeting analysis, shell, prompts*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `dev-codebase-explorer` | T2 | sonnet | — | `python-developer`, `architect-the-planner` |
| `dev-meeting-analyst` | T2 | sonnet | — | `architect-the-planner`, `architect-pipeline` |
| `dev-prompt-crafter` | T1 | sonnet | `python` | — |
| `dev-shell-script-specialist` | T2 | sonnet | — | `python-developer`, `cloud-ci-cd-specialist` |

### Microsoft Fabric
*Fabric lakehouse, pipelines, AI, security*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `fabric-ai-specialist` | T3 | sonnet | `microsoft-fabric` | `user`, `fabric-security-specialist` |
| `fabric-architect` | T3 | sonnet | `microsoft-fabric` | `user`, `fabric-security-specialist` |
| `fabric-cicd-specialist` | T3 | sonnet | `microsoft-fabric` | `user`, `fabric-security-specialist` |
| `fabric-logging-specialist` | T3 | sonnet | `microsoft-fabric` | `user`, `fabric-security-specialist` |
| `fabric-pipeline-developer` | T3 | sonnet | `microsoft-fabric` | `user`, `fabric-architect` |
| `fabric-security-specialist` | T3 | opus | `microsoft-fabric` | `user`, `user` |

### Python & Code Quality
*Python dev, review, cleanup, documentation, LLM prompts*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `python-ai-prompt-specialist` | T1 | sonnet | `prompt-engineering`, `pydantic`, `genai` | — |
| `python-code-cleaner` | T2 | sonnet | `python` | — |
| `python-code-documenter` | T2 | sonnet | `python` | — |
| `python-code-reviewer` | T2 | sonnet | `data-quality`, `sql-patterns`, `dbt` | — |
| `python-developer` | T1 | sonnet | `python`, `pydantic`, `testing` | — |
| `python-llm-specialist` | T3 | sonnet | `prompt-engineering`, `pydantic`, `genai` | — |

### Testing & Contracts
*pytest, data quality, ODCS contracts*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `test-data-contracts-engineer` | T2 | sonnet | `data-quality`, `data-modeling` | `test-data-quality-analyst`, `architect-schema-designer`, `de-dbt-specialist` |
| `test-data-quality-analyst` | T2 | sonnet | `data-quality`, `dbt`, `data-modeling` | `de-dbt-specialist`, `architect-schema-designer`, `test-data-contracts-engineer` |
| `test-generator` | T2 | sonnet | `data-quality`, `dbt`, `testing` | `architect-schema-designer`, `de-dbt-specialist`, `test-data-quality-analyst` |

### Data Science
*EDA, feature engineering, model training, evaluation, deployment, statistics, time series*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `ds-eda-analyst` | T2 | sonnet | `python`, `data-quality`, `xgboost` | `ds-feature-engineer`, `ds-model-trainer` |
| `ds-experiment-tracker` | T2 | sonnet | `python`, `xgboost` | `ds-model-trainer`, `ds-ml-deployer` |
| `ds-feature-engineer` | T2 | sonnet | `python`, `data-quality`, `xgboost` | `ds-eda-analyst`, `ds-model-trainer` |
| `ds-ml-deployer` | T2 | sonnet | `python`, `xgboost`, `cloud-platforms` | `ds-experiment-tracker`, `ds-model-evaluator` |
| `ds-model-evaluator` | T2 | sonnet | `python`, `xgboost`, `testing` | `ds-model-trainer`, `ds-ml-deployer` |
| `ds-model-trainer` | T2 | sonnet | `python`, `xgboost`, `data-quality` | `ds-feature-engineer`, `ds-model-evaluator`, `ds-experiment-tracker` |
| `ds-statistician` | T2 | sonnet | `python`, `data-quality` | `ds-model-trainer`, `ds-eda-analyst` |
| `ds-time-series-analyst` | T2 | sonnet | `python`, `xgboost`, `data-quality` | `ds-feature-engineer`, `ds-model-evaluator` |

## B. KB Domain → Agents

Which agents know which domain. Use this when the user names a technology.

| KB Domain | Agents |
|-----------|--------|
| `ai-data-engineering` | `architect-genai`, `cloud-supabase-specialist`, `de-ai-data-engineer`, `de-qdrant-specialist` |
| `airflow` | `architect-pipeline`, `de-airflow-specialist` |
| `aws` | `cloud-ai-data-engineer-cloud`, `cloud-aws-data-architect`, `cloud-aws-deployer`, `cloud-aws-lambda-architect`, `cloud-ci-cd-specialist`, `cloud-lambda-builder` |
| `cloud-platforms` | `architect-data-platform-engineer`, `cloud-ai-data-engineer-cloud`, `cloud-ai-data-engineer-gcp`, `cloud-gcp-data-architect`, `de-spark-performance-analyzer`, `de-spark-specialist`, `ds-ml-deployer` |
| `data-modeling` | `architect-data-platform-engineer`, `architect-lakehouse`, `architect-medallion`, `architect-schema-designer`, `cloud-supabase-specialist`, `de-sql-optimizer`, `test-data-contracts-engineer`, `test-data-quality-analyst` |
| `data-quality` | `architect-medallion`, `architect-pipeline`, `architect-schema-designer`, `cloud-ai-data-engineer-cloud`, `cloud-ai-data-engineer-gcp`, `cloud-aws-data-architect`, `cloud-gcp-data-architect`, `de-ai-data-engineer`, `de-airflow-specialist`, `de-dbt-specialist`, `de-lakeflow-expert`, `de-lakeflow-pipeline-builder`, `de-lakeflow-specialist`, `ds-eda-analyst`, `ds-feature-engineer`, `ds-model-trainer`, `ds-statistician`, `ds-time-series-analyst`, `python-code-reviewer`, `test-data-contracts-engineer`, `test-data-quality-analyst`, `test-generator` |
| `dbt` | `architect-pipeline`, `de-dbt-specialist`, `de-sql-optimizer`, `python-code-reviewer`, `test-data-quality-analyst`, `test-generator` |
| `gcp` | `cloud-ai-data-engineer-cloud`, `cloud-ai-data-engineer-gcp`, `cloud-ai-prompt-specialist-gcp`, `cloud-gcp-data-architect` |
| `genai` | `architect-genai`, `cloud-ai-prompt-specialist-gcp`, `de-qdrant-specialist`, `python-ai-prompt-specialist`, `python-llm-specialist` |
| `lakeflow` | `cloud-ci-cd-specialist`, `de-lakeflow-architect`, `de-lakeflow-expert`, `de-lakeflow-pipeline-builder`, `de-lakeflow-specialist` |
| `lakehouse` | `architect-data-platform-engineer`, `architect-lakehouse`, `architect-medallion`, `de-lakeflow-architect`, `de-lakeflow-expert`, `de-lakeflow-pipeline-builder`, `de-lakeflow-specialist`, `de-spark-performance-analyzer`, `de-spark-streaming-architect` |
| `medallion` | `architect-medallion`, `de-lakeflow-architect`, `de-lakeflow-expert`, `de-lakeflow-pipeline-builder` |
| `microsoft-fabric` | `fabric-ai-specialist`, `fabric-architect`, `fabric-cicd-specialist`, `fabric-logging-specialist`, `fabric-pipeline-developer`, `fabric-security-specialist` |
| `prompt-engineering` | `architect-genai`, `cloud-ai-prompt-specialist-gcp`, `python-ai-prompt-specialist`, `python-llm-specialist` |
| `pydantic` | `cloud-ai-prompt-specialist-gcp`, `python-ai-prompt-specialist`, `python-developer`, `python-llm-specialist` |
| `python` | `cloud-lambda-builder`, `dev-prompt-crafter`, `ds-eda-analyst`, `ds-experiment-tracker`, `ds-feature-engineer`, `ds-ml-deployer`, `ds-model-evaluator`, `ds-model-trainer`, `ds-statistician`, `ds-time-series-analyst`, `python-code-cleaner`, `python-code-documenter`, `python-developer` |
| `spark` | `architect-lakehouse`, `de-lakeflow-architect`, `de-lakeflow-specialist`, `de-spark-engineer`, `de-spark-performance-analyzer`, `de-spark-specialist`, `de-spark-streaming-architect`, `de-spark-troubleshooter`, `de-streaming-engineer` |
| `sql-patterns` | `architect-schema-designer`, `de-airflow-specialist`, `de-dbt-specialist`, `de-spark-engineer`, `de-spark-specialist`, `de-spark-troubleshooter`, `de-sql-optimizer`, `de-streaming-engineer`, `python-code-reviewer` |
| `streaming` | `de-ai-data-engineer`, `de-spark-engineer`, `de-spark-streaming-architect`, `de-streaming-engineer` |
| `supabase` | `cloud-supabase-specialist` |
| `terraform` | `cloud-ai-data-engineer-cloud`, `cloud-ai-data-engineer-gcp`, `cloud-aws-data-architect`, `cloud-aws-deployer`, `cloud-aws-lambda-architect`, `cloud-ci-cd-specialist`, `cloud-gcp-data-architect` |
| `testing` | `cloud-lambda-builder`, `ds-model-evaluator`, `python-developer`, `test-generator` |
| `xgboost` | `ds-eda-analyst`, `ds-experiment-tracker`, `ds-feature-engineer`, `ds-ml-deployer`, `ds-model-evaluator`, `ds-model-trainer`, `ds-time-series-analyst` |
## C. Agent One-Liners

Single-sentence purpose per agent, derived from frontmatter `description`.

- **`agentspec:brainstorm-agent`** — Collaborative exploration specialist for clarifying intent and approach (Phase 0).
- **`agentspec:build-agent`** — Implementation executor with agent delegation (Phase 3).
- **`agentspec:define-agent`** — Requirements extraction and validation specialist (Phase 1).
- **`agentspec:design-agent`** — Architecture and technical specification specialist (Phase 2).
- **`agentspec:iterate-agent`** — Cross-phase document updater with cascade awareness (All Phases).
- **`agentspec:ship-agent`** — Feature archival and lessons learned specialist (Phase 4).
- **`architect-data-platform-engineer`** — Cloud data platform specialist for Snowflake, Databricks, BigQuery, and infrastructure decisions.
- **`architect-genai`** — GenAI Systems Architect for multi-agent orchestration, agentic workflows, and production AI systems.
- **`architect-kb`** — Knowledge base architect for creating validated, structured KB domains.
- **`architect-lakehouse`** — Open table format and catalog specialist for Iceberg, Delta Lake, and lakehouse governance.
- **`architect-medallion`** — Medallion Architecture specialist for Bronze/Silver/Gold layer design and data quality progression.
- **`architect-pipeline`** — Orchestration specialist for Airflow, Dagster, and pipeline design patterns.
- **`architect-schema-designer`** — Data modeling specialist for dimensional modeling, Data Vault, SCD types, and schema evolution.
- **`architect-the-planner`** — Strategic AI architect that creates comprehensive implementation plans.
- **`cloud-ai-data-engineer-cloud`** — Expert Data Engineer for cloud architectures and AI pipelines. Uses KB + MCP validation for best practices.
- **`cloud-ai-data-engineer-gcp`** — Elite GCP Data Engineering architect for serverless architectures, AI/ML pipelines, and document processing.
- **`cloud-ai-prompt-specialist-gcp`** — Elite Prompt Engineering architect for Google Gemini, Vertex AI, and multi-modal document extraction systems. Masters structured extraction, OCR optimization, and production prompt pipelines. Uses KB + MCP validation.
- **`cloud-aws-data-architect`** — AWS data architecture specialist for Lambda, S3, Glue, Redshift, MWAA, and serverless data pipelines.
- **`cloud-aws-deployer`** — Executes AWS CLI and SAM CLI deployment commands with validation. Uses KB + MCP validation for safe deployments.
- **`cloud-aws-lambda-architect`** — Creates SAM templates with embedded least-privilege IAM policies. Uses KB + MCP validation for secure Lambda deployments.
- **`cloud-ci-cd-specialist`** — DevOps expert for Azure DevOps, Terraform, and Databricks Asset Bundles. Builds CI/CD pipelines for Lambda and Lakeflow deployment with multi-environment promotion. Uses KB + MCP validation for production-ready automation.
- **`cloud-gcp-data-architect`** — Google Cloud data architecture specialist for BigQuery, Cloud Run, Pub/Sub, GCS, Dataflow, and Vertex AI.
- **`cloud-lambda-builder`** — AWS Lambda expert for Python serverless file processing. Builds S3-triggered Lambda functions with proper error handling, structured logging, and Parquet output. Uses KB + MCP validation for production-ready code.
- **`cloud-supabase-specialist`** — Elite Supabase specialist for pgvector, RLS, Edge Functions, Auth, Realtime, and database design.
- **`de-ai-data-engineer`** — AI data engineering specialist for RAG pipelines, vector databases, feature stores, and LLMOps.
- **`de-airflow-specialist`** — Apache Airflow 3.0 SME for DAG development, asset-aware scheduling, and event-driven pipelines.
- **`de-dbt-specialist`** — dbt Core and dbt Cloud specialist for model development, testing, macros, and project management.
- **`de-lakeflow-architect`** — Databricks Lakeflow expert for building Medallion architecture pipelines. Creates Bronze/Silver/Gold layers with DLT. Uses KB + MCP validation.
- **`de-lakeflow-expert`** — Databricks Lakeflow (DLT) SME for pipeline development, CDC, data quality, and production deployment. Uses KB + MCP validation.
- **`de-lakeflow-pipeline-builder`** — Builds Databricks Lakeflow (DLT) pipelines for Medallion Architecture. Uses KB + MCP validation for production-ready pipelines.
- **`de-lakeflow-specialist`** — Databricks Lakeflow (DLT) specialist for declarative pipelines, materialized views, streaming tables, and expectations.
- **`de-qdrant-specialist`** — Elite Qdrant vector database specialist for collection management, point operations, payload filtering, search optimization, and RAG pipeline integration.
- **`de-spark-engineer`** — PySpark and Spark SQL specialist for distributed data processing at scale.
- **`de-spark-performance-analyzer`** — Spark performance optimization specialist for tuning memory, partitioning, joins, and I/O.
- **`de-spark-specialist`** — Apache Spark SME for performance optimization, architecture design, and troubleshooting.
- **`de-spark-streaming-architect`** — Spark Structured Streaming expert for real-time pipelines, Kafka integration, and stream processing. Uses KB + MCP validation.
- **`de-spark-troubleshooter`** — Spark debugging specialist for diagnosing OOM errors, data skew, shuffle failures, and job hangs.
- **`de-sql-optimizer`** — Cross-dialect SQL optimization specialist for query plans, window functions, and performance tuning.
- **`de-streaming-engineer`** — Stream processing specialist for Flink, Kafka, Spark Streaming, RisingWave, and CDC pipelines.
- **`dev-codebase-explorer`** — Elite codebase analyst delivering Executive Summaries + Deep Dives.
- **`dev-meeting-analyst`** — Master communication analyst that transforms meetings into structured, actionable documentation.
- **`dev-prompt-crafter`** — PROMPT.md builder with SDD-lite phases and Agent Matching Engine.
- **`dev-shell-script-specialist`** — Elite shell scripting specialist for building production-grade Bash scripts with best practices, error handling, and cross-platform compatibility.
- **`ds-eda-analyst`** — Exploratory Data Analysis specialist for profiling datasets, detecting outliers, analyzing distributions and correlations, and generating actionable EDA summaries before modeling. Use when starting a new dataset, validating data quality, or preparing features for ML.
- **`ds-experiment-tracker`** — MLflow experiment tracking specialist — log training runs, compare experiments, register models, manage run hierarchies, and connect experimentation to the model registry for promotion workflows.
- **`ds-feature-engineer`** — Feature engineering specialist for building production-ready preprocessing pipelines: encoding, scaling, imputation, feature selection, and ColumnTransformer composition. Use when designing or implementing ML feature pipelines from raw tabular data.
- **`ds-ml-deployer`** — ML deployment specialist — promote models through the MLflow registry, serve via REST API or batch pipeline, wrap models in FastAPI, and add monitoring hooks for production observability.
- **`ds-model-evaluator`** — Model evaluation specialist for generating comprehensive classification and regression diagnostics: metrics, confusion matrices, ROC/PR curves, calibration plots, residual analysis, and model comparison reports. Use after training to fully characterize model performance.
- **`ds-model-trainer`** — Model training specialist for fitting scikit-learn pipelines, XGBoost, and LightGBM models with cross-validation, hyperparameter tuning, and reproducible experiment setup. Use when training, tuning, or comparing ML models on tabular data.
- **`ds-statistician`** — Statistical analysis specialist for hypothesis testing, A/B test design, distribution analysis, and effect-size reporting. Use when running statistical tests, designing experiments, analyzing group differences, or producing rigorous statistical summaries.
- **`ds-time-series-analyst`** — Time series analysis and forecasting specialist — stationarity testing, decomposition, ARIMA/SARIMA,
- **`fabric-ai-specialist`** — Expert in Microsoft Fabric AI capabilities - Copilot, ML models, AI Skills, and Azure OpenAI integration.
- **`fabric-architect`** — Strategic Fabric solution architect for end-to-end architectures using KB + MCP validation.
- **`fabric-cicd-specialist`** — Expert in Microsoft Fabric CI/CD, Git integration, and deployment pipelines.
- **`fabric-logging-specialist`** — Expert in Microsoft Fabric logging, monitoring, KQL queries, and observability.
- **`fabric-pipeline-developer`** — Expert in Fabric Data Factory pipelines, orchestration, and ETL workflows.
- **`fabric-security-specialist`** — Expert in Microsoft Fabric security, governance, and compliance.
- **`python-ai-prompt-specialist`** — Prompt engineering specialist for LLMs — extraction, structured output, chain-of-thought, few-shot.
- **`python-code-cleaner`** — Python code cleaning specialist for removing noise and applying modern patterns.
- **`python-code-documenter`** — Documentation specialist for creating comprehensive, production-ready documentation.
- **`python-code-reviewer`** — Expert code review specialist ensuring quality, security, and maintainability.
- **`python-developer`** — Python code architect for data engineering systems — clean patterns, dataclasses, type hints, generators.
- **`python-llm-specialist`** — Prompt engineering specialist and LLM expert. Masters structured prompting, chain-of-thought reasoning, and AI-powered extraction. Uses KB + MCP validation for optimized, production-ready prompts.
- **`test-data-contracts-engineer`** — Data contract specialist for ODCS, SLA enforcement, schema governance, and producer-consumer agreements.
- **`test-data-quality-analyst`** — Data quality specialist for Great Expectations, Soda, dbt tests, data contracts, and observability.
- **`test-generator`** — Test automation expert for Python. Generates pytest unit tests, integration tests, and fixtures.

## D. Model Routing Strategy

Cost-optimize by matching task complexity to model capability.
All multipliers are relative to the base premium request unit.

| Tier | Model | Multiplier | Agent Share | Use For |
|------|-------|-----------|-------------|---------|
| **Free** | `GPT-5 mini` | **0x** | ~10% | File exploration, meeting analysis, documentation generation, prompt crafting |
| **Standard** | `Claude Sonnet 4.6` ⭐ | 1x | ~50% | SDD workflow phases, data science, architecture design, Fabric, LLM/prompt agents |
| **Standard** | `GPT-5.3-Codex` | 1x | ~38% | Agentic execution chains: data engineering, cloud infra, code generation, testing |
| **Premium** | `Claude Opus 4.6` | 3x | ~2% | Security & compliance reviews only (`fabric-security-specialist`) |
| ⚠️ Avoid | `Claude Opus 4.7` | 15x | — | Never default; only on explicit user request |
| ⚠️ Avoid | `GPT-5.5` | 7.5x | — | Only on explicit user request |

**Category → default model:**

| Category | Model | Rationale |
|----------|-------|-----------|
| `workflow-brainstorm` | `GPT-5 mini` | Exploratory conversation, zero cost |
| `workflow-define/design/iterate/ship` | `Claude Sonnet 4.6` | Structured SDD document reasoning |
| `workflow-build` | `GPT-5.3-Codex` | Multi-tool agentic implementation |
| `de-*` (data engineering) | `GPT-5.3-Codex` | Agentic SQL/Spark/dbt/Lakeflow chains |
| `ds-*` (data science) | `Claude Sonnet 4.6` | Statistical and scientific reasoning |
| `architect-*` | `Claude Sonnet 4.6` | System design and trade-off analysis |
| `cloud-aws-deployer`, `cloud-lambda-builder`, `cloud-ci-cd-specialist` | `GPT-5.3-Codex` | CLI execution, IaC generation |
| `cloud-*` (architecture) | `Claude Sonnet 4.6` | Cloud platform design and analysis |
| `fabric-*` (except security) | `Claude Sonnet 4.6` | Microsoft Fabric platform reasoning |
| `fabric-security-specialist` | `Claude Opus 4.6` | Compliance, RLS, governance — escalate |
| `python-developer/cleaner/reviewer` | `GPT-5.3-Codex` | Code generation and refactoring |
| `python-ai-prompt-specialist`, `python-llm-specialist` | `Claude Sonnet 4.6` | LLM reasoning |
| `test-*` | `GPT-5.3-Codex` | Systematic test and contract generation |
| `dev-codebase-explorer/meeting-analyst/prompt-crafter` | `GPT-5 mini` | Discovery and docs, zero cost |
| `python-code-documenter`, `architect-kb` | `GPT-5 mini` | Background generation, zero cost |

**Override rules:**
- Agent frontmatter `model:` is the authoritative assignment; this table is the design rationale.
- Tasks touching production security/compliance escalate to `Claude Opus 4.6` (3x) at minimum.
- Confidence below 0.75 on first response → retry with `Claude Sonnet 4.6` before escalating.
- **Never use `Claude Opus 4.7` (15x) or `GPT-5.5` (7.5x) as an agent default.**
- Deprecated models (`GPT-4.1`, `GPT-5.2`) — do not assign to new agents.

## E. Composition Hints

**Parallel** (independent work, different files):
- `de-dbt-specialist` + `test-generator`
- `python-code-reviewer` + `test-data-quality-analyst`
- `architect-schema-designer` + `architect-pipeline`

**Serial** (output feeds next step):
- `architect-schema-designer` → `de-dbt-specialist`
- `architect-pipeline` → `de-airflow-specialist`
- `workflow-define` → `workflow-design` → `workflow-build`

**Background** (non-blocking):
- `dev-codebase-explorer`, `python-code-documenter`, `architect-kb`

## F. How Routing Works

1. **File-pattern signal** — agent's `kb_domains` implies file types (e.g., `dbt` → `models/**/*.sql`).
2. **Intent signal** — the one-liner in `description` is the semantic anchor.
3. **Context signal** — agent's `category` scopes the match to the right domain.
4. **Escalation signal** — `escalation_rules.target` provides the handoff graph.

To change routing, edit the **agent's frontmatter**, not this file. Then run:

```bash
python3 scripts/generate-agent-router.py
```
