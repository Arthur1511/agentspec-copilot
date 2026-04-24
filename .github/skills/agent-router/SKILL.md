---
name: agent-router
description: Intelligent agent routing -- automatically matches tasks to the best specialist agent based on file patterns, intent keywords, and domain context. Loaded every session to give Copilot explicit routing rules for all 58 AgentSpec agents.
---

<!-- =========================================================================
     GENERATED FILE — DO NOT EDIT BY HAND
     Source of truth: .github/agents/*.agent.md frontmatter
     Regenerate:      python3 scripts/generate-agent-router.py
     CI check:        python3 scripts/generate-agent-router.py --check
     ========================================================================= -->

# Agent Router

Explicit routing rules for matching tasks to the correct specialist agent. Generated from each agent's frontmatter, so any change to an agent's `description`, `kb_domains`, or `escalation_rules` flows here automatically.

**Agent count:** 58  |  **Categories:** 8  |  **Content hash:** `d5d808a0df75`

## A. Agents by Category

### SDD Workflow
*Brainstorm, Define, Design, Build, Ship, Iterate*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `agentspec:brainstorm-agent` | T2 | sonnet | — | — |
| `agentspec:build-agent` | T2 | opus | — | — |
| `agentspec:define-agent` | T2 | sonnet | — | — |
| `agentspec:design-agent` | T2 | opus | — | — |
| `agentspec:iterate-agent` | T2 | sonnet | — | — |
| `agentspec:ship-agent` | T2 | sonnet | — | — |

### Architecture & Design
*System-level design, schemas, pipelines, lakehouse*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `architect-data-platform-engineer` | T2 | sonnet | — | — |
| `architect-genai` | T2 | opus | — | — |
| `architect-kb` | T2 | sonnet | — | — |
| `architect-lakehouse` | T2 | sonnet | — | — |
| `architect-medallion` | T2 | sonnet | — | — |
| `architect-pipeline` | T2 | sonnet | — | — |
| `architect-schema-designer` | T2 | sonnet | — | — |
| `architect-the-planner` | T2 | opus | — | — |

### Cloud & Infrastructure
*AWS, GCP, CI/CD, deployment*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `cloud-ai-data-engineer-cloud` | T2 | sonnet | — | — |
| `cloud-ai-data-engineer-gcp` | T2 | sonnet | — | — |
| `cloud-ai-prompt-specialist-gcp` | T2 | sonnet | — | — |
| `cloud-aws-data-architect` | T2 | sonnet | — | — |
| `cloud-aws-deployer` | T2 | sonnet | — | — |
| `cloud-aws-lambda-architect` | T2 | sonnet | — | — |
| `cloud-ci-cd-specialist` | T2 | sonnet | — | — |
| `cloud-gcp-data-architect` | T2 | sonnet | — | — |
| `cloud-lambda-builder` | T2 | sonnet | — | — |
| `cloud-supabase-specialist` | T2 | opus | — | — |

### Data Engineering
*dbt, Spark, SQL, Airflow, streaming, data quality*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `de-ai-data-engineer` | T2 | sonnet | — | — |
| `de-airflow-specialist` | T2 | sonnet | — | — |
| `de-dbt-specialist` | T2 | sonnet | — | — |
| `de-lakeflow-architect` | T2 | sonnet | — | — |
| `de-lakeflow-expert` | T2 | sonnet | — | — |
| `de-lakeflow-pipeline-builder` | T2 | sonnet | — | — |
| `de-lakeflow-specialist` | T2 | sonnet | — | — |
| `de-qdrant-specialist` | T2 | opus | — | — |
| `de-spark-engineer` | T2 | sonnet | — | — |
| `de-spark-performance-analyzer` | T2 | sonnet | — | — |
| `de-spark-specialist` | T2 | opus | — | — |
| `de-spark-streaming-architect` | T2 | sonnet | — | — |
| `de-spark-troubleshooter` | T2 | sonnet | — | — |
| `de-sql-optimizer` | T2 | sonnet | — | — |
| `de-streaming-engineer` | T2 | sonnet | — | — |

### Developer Tools
*Codebase exploration, meeting analysis, shell, prompts*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `dev-codebase-explorer` | T2 | sonnet | — | — |
| `dev-meeting-analyst` | T2 | sonnet | — | — |
| `dev-prompt-crafter` | T2 | sonnet | — | — |
| `dev-shell-script-specialist` | T2 | sonnet | — | — |

### Microsoft Fabric
*Fabric lakehouse, pipelines, AI, security*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `fabric-ai-specialist` | T2 | sonnet | — | — |
| `fabric-architect` | T2 | opus | — | — |
| `fabric-cicd-specialist` | T2 | sonnet | — | — |
| `fabric-logging-specialist` | T2 | sonnet | — | — |
| `fabric-pipeline-developer` | T2 | sonnet | — | — |
| `fabric-security-specialist` | T2 | opus | — | — |

### Python & Code Quality
*Python dev, review, cleanup, documentation, LLM prompts*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `python-ai-prompt-specialist` | T2 | sonnet | — | — |
| `python-code-cleaner` | T2 | sonnet | — | — |
| `python-code-documenter` | T2 | sonnet | — | — |
| `python-code-reviewer` | T2 | sonnet | — | — |
| `python-developer` | T2 | sonnet | — | — |
| `python-llm-specialist` | T2 | opus | — | — |

### Testing & Contracts
*pytest, data quality, ODCS contracts*

| Agent | Tier | Model | KB Domains | Escalates To |
|-------|------|-------|-----------|--------------|
| `test-data-contracts-engineer` | T2 | sonnet | — | — |
| `test-data-quality-analyst` | T2 | sonnet | — | — |
| `test-generator` | T2 | sonnet | — | — |

## B. KB Domain → Agents

Which agents know which domain. Use this when the user names a technology.

| KB Domain | Agents |
|-----------|--------|
## C. Agent One-Liners

Single-sentence purpose per agent, derived from frontmatter `description`.

- **`agentspec:brainstorm-agent`** — Collaborative exploration specialist for clarifying intent and approach (Phase 0).
- **`agentspec:build-agent`** — Implementation executor with agent delegation (Phase 3).
- **`agentspec:define-agent`** — Requirements extraction and validation specialist (Phase 1).
- **`agentspec:design-agent`** — Architecture and technical specification specialist (Phase 2).
- **`agentspec:iterate-agent`** — Cross-phase document updater with cascade awareness (All Phases).
- **`agentspec:ship-agent`** — Feature archival and lessons learned specialist (Phase 4).
- **`architect-data-platform-engineer`** — Cloud data platform specialist for Snowflake, Databricks, BigQuery, and infrastructure decisions. Use when comparing platforms, optimizing costs, or provisioning data infrastructure.
- **`architect-genai`** — GenAI Systems Architect for multi-agent orchestration, agentic workflows, and production AI systems. Use when designing AI systems, multi-agent architectures, chatbots, or LLM workflows.
- **`architect-kb`** — Knowledge base architect for creating validated, structured KB domains with MCP-backed content. Use when creating new KB domains, auditing KB health, or adding concepts and patterns.
- **`architect-lakehouse`** — Open table format and catalog specialist for Iceberg, Delta Lake, and lakehouse governance. Use when working with Iceberg, Delta, catalog setup, or format migration decisions.
- **`architect-medallion`** — Medallion Architecture specialist for Bronze/Silver/Gold layer design and data quality progression. Use when designing lakehouse layers or implementing medallion patterns.
- **`architect-pipeline`** — Orchestration specialist for Airflow, Dagster, and pipeline design patterns. Use when creating DAGs, designing pipelines, or selecting orchestrators.
- **`architect-schema-designer`** — Data modeling specialist for dimensional modeling, Data Vault, SCD types, and schema evolution. Use when designing schemas, star schemas, or making modeling decisions.
- **`architect-the-planner`** — Strategic AI architect that creates comprehensive implementation plans and technology roadmaps. Use when planning complex tasks, system design, or architecture decisions requiring deep analysis.
- **`cloud-ai-data-engineer-cloud`** — Expert data engineer for cloud architectures and AI pipelines across AWS and GCP. Use when optimizing data pipelines, refactoring cloud functions, or designing multi-cloud data architectures.
- **`cloud-ai-data-engineer-gcp`** — Elite GCP data engineering architect for serverless architectures, AI/ML pipelines, and document processing. Use when building GCP Cloud Functions, BigQuery pipelines, Pub/Sub systems, or Dataflow jobs.
- **`cloud-ai-prompt-specialist-gcp`** — Elite prompt engineering architect for Google Gemini, Vertex AI, and multi-modal document extraction systems. Use when optimizing Gemini prompts, designing document extraction pipelines, or improving multi-modal AI accuracy.
- **`cloud-aws-data-architect`** — AWS data architecture specialist for Lambda, S3, Glue, Redshift, MWAA, and serverless data pipelines. Use when designing AWS data infrastructure or serverless data processing.
- **`cloud-aws-deployer`** — Executes AWS CLI and SAM CLI deployment commands with validation for safe Lambda and infrastructure deployments. Use when deploying Lambda functions, testing via CLI, or managing S3 operations.
- **`cloud-aws-lambda-architect`** — Creates SAM templates with embedded least-privilege IAM policies for secure Lambda deployments. Use when building Lambda functions, SAM templates, or configuring S3 triggers.
- **`cloud-ci-cd-specialist`** — DevOps expert for Azure DevOps, Terraform, and Databricks Asset Bundles with multi-environment deployment pipelines. Use when setting up CI/CD pipelines, configuring Terraform, or deploying with DABs.
- **`cloud-gcp-data-architect`** — Google Cloud data architecture specialist for BigQuery, Cloud Run, Pub/Sub, GCS, Dataflow, and Vertex AI. Use when designing GCP data infrastructure or AI pipelines on Google Cloud.
- **`cloud-lambda-builder`** — AWS Lambda expert for Python serverless file processing with Powertools logging and S3 integration. Use when building Lambda handlers, SAM templates, or S3 event processing code.
- **`cloud-supabase-specialist`** — Elite Supabase specialist for pgvector, RLS, Edge Functions, Auth, Realtime, and database design with live MCP instance access. Use when working with Supabase databases, vector storage, authentication, or serverless functions.
- **`de-ai-data-engineer`** — AI data engineering specialist for RAG pipelines, vector databases, feature stores, and LLMOps. Use when building RAG, embedding pipelines, feature engineering, or text-to-SQL systems.
- **`de-airflow-specialist`** — Apache Airflow 3.0 SME for DAG development, asset-aware scheduling, and event-driven pipelines. Use when building DAGs, configuring TaskFlow API, or implementing data pipeline orchestration.
- **`de-dbt-specialist`** — dbt Core and dbt Cloud specialist for model development, testing, macros, and project management. Use when working with dbt models, tests, macros, or project configuration.
- **`de-lakeflow-architect`** — Databricks Lakeflow expert for building Medallion architecture pipelines with DLT, Bronze/Silver/Gold layers, and DABs configuration. Use when designing DLT pipelines, creating streaming tables, or configuring DABs.
- **`de-lakeflow-expert`** — Databricks Lakeflow (DLT) SME for pipeline development, CDC, data quality, and production deployment. Use when troubleshooting Lakeflow pipelines or working with DLT operations at production scale.
- **`de-lakeflow-pipeline-builder`** — Builds Databricks Lakeflow (DLT) pipelines for Medallion Architecture with Bronze/Silver/Gold tables and DABs deployment. Use when creating DLT notebooks, implementing data quality expectations, or configuring pipeline deployments.
- **`de-lakeflow-specialist`** — Databricks Lakeflow (DLT) specialist for declarative pipelines, materialized views, streaming tables, and expectations. Use when building DLT pipelines or working with Databricks Lakeflow.
- **`de-qdrant-specialist`** — Elite Qdrant vector database specialist for collection management, point operations, payload filtering, search optimization, and RAG pipeline integration. Use when working with Qdrant collections, vector search, metadata filtering, or n8n vector store integration.
- **`de-spark-engineer`** — PySpark and Spark SQL specialist for distributed data processing at scale, performance tuning, and Delta/Iceberg integration. Use when working with Spark jobs, DataFrames, or performance optimization.
- **`de-spark-performance-analyzer`** — Spark performance optimization specialist for tuning memory, partitioning, joins, and I/O using AQE and profiling. Use when optimizing Spark job performance or reducing compute costs.
- **`de-spark-specialist`** — Apache Spark SME for performance optimization, architecture design, and troubleshooting at production scale. Use when working with Spark code, data pipelines, or encountering performance issues.
- **`de-spark-streaming-architect`** — Spark Structured Streaming expert for real-time pipelines, Kafka integration, watermarking, and stream processing. Use when building streaming applications, event processing, or real-time analytics.
- **`de-spark-troubleshooter`** — Spark debugging specialist for diagnosing OOM errors, data skew, shuffle failures, and job hangs. Use when a Spark job fails, is slow, or produces unexpected results.
- **`de-sql-optimizer`** — Cross-dialect SQL optimization specialist for query plans, window functions, deduplication, and performance tuning. Use when optimizing slow queries, writing complex SQL, or translating between SQL dialects.
- **`de-streaming-engineer`** — Stream processing specialist for Flink, Kafka, Spark Streaming, RisingWave, and CDC pipelines. Use when building real-time pipelines, CDC, or streaming SQL applications.
- **`dev-codebase-explorer`** — Elite codebase analyst delivering Executive Summaries and Deep Dives for unfamiliar repos. Use when exploring unfamiliar codebases, onboarding to a new project, or generating codebase health reports.
- **`dev-meeting-analyst`** — Master communication analyst that transforms meetings, Slack threads, and emails into structured, actionable documentation. Use when analyzing meeting transcripts, consolidating discussions, or creating SSOT docs.
- **`dev-prompt-crafter`** — PROMPT.md builder with SDD-lite phases (EXPLORE, DEFINE, DESIGN, GENERATE) and Agent Matching Engine for structured task execution. Use when needing to structure a task prompt or match agents to specific files and requirements.
- **`dev-shell-script-specialist`** — Elite shell scripting specialist for building production-grade Bash scripts with best practices, error handling, and cross-platform compatibility. Use when creating shell scripts, automating CLI tasks, building deployment scripts, or writing test harnesses.
- **`fabric-ai-specialist`** — Expert in Microsoft Fabric AI capabilities including Copilot, ML models, AI Skills, and Azure OpenAI integration. Use when working with Fabric Copilot, ML model deployment, PREDICT functions, or RAG in Fabric.
- **`fabric-architect`** — Strategic Fabric solution architect for end-to-end architectures using workload selection, Medallion design, and security planning. Use when designing Fabric architectures, selecting workloads, or planning solution designs.
- **`fabric-cicd-specialist`** — Expert in Microsoft Fabric CI/CD, Git integration, and deployment pipelines for multi-environment promotion. Use when setting up CI/CD for Fabric workspaces, configuring Git sync, or deploying to production.
- **`fabric-logging-specialist`** — Expert in Microsoft Fabric logging, monitoring, KQL queries, and observability using Eventhouse-based centralized logging. Use when setting up monitoring, writing KQL queries, or building observability dashboards in Fabric.
- **`fabric-pipeline-developer`** — Expert in Fabric Data Factory pipelines, orchestration, and ETL workflows including Copy Activity and Dataflow Gen2. Use when building data pipelines, implementing incremental loading with watermarks, or orchestrating ETL in Fabric.
- **`fabric-security-specialist`** — Expert in Microsoft Fabric security, governance, and compliance including RLS, data masking, encryption, and GDPR/HIPAA requirements. Use when implementing row-level security, data masking, permissions, or compliance controls in Fabric.
- **`python-ai-prompt-specialist`** — Prompt engineering specialist for LLMs covering extraction, structured output, chain-of-thought, and few-shot techniques. Use when optimizing prompts, designing extraction pipelines, or improving AI output consistency and accuracy.
- **`python-code-cleaner`** — Python code cleaning specialist for removing noise, applying DRY principles, and modernizing to Python 3.9+ patterns. Use when cleaning, refactoring, or modernizing Python code while preserving business logic and public APIs.
- **`python-code-documenter`** — Documentation specialist for creating comprehensive, production-ready READMEs, API docs, module docs, and docstrings. Use when creating or updating documentation for Python projects, APIs, or code libraries.
- **`python-code-reviewer`** — Expert code review specialist ensuring quality, security, and maintainability with severity-based issue classification. Use proactively after writing or modifying significant code, especially for security-sensitive code.
- **`python-developer`** — Python code architect for data engineering systems using clean patterns, dataclasses, type hints, and generators. Use when writing or reviewing Python code for data pipelines and parsers.
- **`python-llm-specialist`** — Prompt engineering and LLM optimization expert for structured prompting, chain-of-thought reasoning, and production AI systems. Use when crafting prompts, optimizing AI responses, or implementing advanced extraction techniques.
- **`test-data-contracts-engineer`** — Data contract specialist for ODCS authoring, SLA enforcement, schema governance, and producer-consumer agreements. Use when authoring data contracts, enforcing SLAs, or governing schema changes with breaking change detection.
- **`test-data-quality-analyst`** — Data quality specialist for Great Expectations, Soda, dbt tests, data contracts, and observability pipelines. Use when building quality checks, authoring data contracts, or investigating data quality issues.
- **`test-generator`** — Test automation expert for Python that generates pytest unit tests, integration tests, fixtures, and data quality suites. Use after code is written or when asked to add comprehensive tests.

## D. Model Routing Strategy

Cost-optimize by matching task complexity to model capability.

| Model | Share | Use For |
|-------|-------|---------|
| Haiku | ~70% | File exploration, pattern matching, documentation lookup, simple code generation |
| Sonnet | ~20% | Code review, feature implementation, refactoring, API development, most T1/T2 agents |
| Opus | ~10% | Architectural decisions, complex system design, security reviews, T3 agents |

**Override rules:**
- Agent frontmatter `model:` wins over task-complexity heuristics.
- Tasks touching production data or security escalate to Opus.
- Confidence below 0.75 on Sonnet → retry on Opus before asking user.

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
