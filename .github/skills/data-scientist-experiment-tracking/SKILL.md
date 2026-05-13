---
name: ds-experiment-tracking
description: Experiment tracking and ML deployment for data scientists — delegates to ds-experiment-tracker and ds-ml-deployer agents. Use when logging MLflow runs, comparing experiments, registering models, promoting to production, serving via API, or running batch inference.
---

# Experiment Tracking Command

> Log training runs, compare experiments, register models, and deploy to production

## Usage

```bash
/ds-experiment-tracking <description-or-file>
```

## Examples

```bash
/ds-experiment-tracking "Set up MLflow autologging for my sklearn training loop"
/ds-experiment-tracking "Find the best run across churn-prediction experiments and register it"
/ds-experiment-tracking "Promote fraud-classifier from Staging to Production"
/ds-experiment-tracking "Serve the registered model as a FastAPI endpoint"
```

---

## What This Command Does

1. Invokes **ds-experiment-tracker** or **ds-ml-deployer** depending on task
2. Identifies stage: tracking → registry → serving
3. Loads KB patterns from `mlflow` and `scikit-learn` domains
4. Generates:
   - MLflow `start_run` block with params, metrics, artifacts, and model signature
   - Experiment comparison leaderboard from `mlflow.search_runs`
   - Model registry registration + stage transition code
   - FastAPI wrapper or batch inference pipeline

## Agent Delegation

| Agent | Role |
|-------|------|
| `ds-experiment-tracker` | Primary — run logging, autologging, experiment comparison, registry |
| `ds-ml-deployer` | Primary — stage promotion, REST serving, batch inference, monitoring |
| `ds-model-evaluator` | Escalation — when validation metrics are needed before promotion |

## KB Domains Used

- `mlflow` — run logging, autologging, registry, artifact management, serving
- `scikit-learn` — model signatures, sklearn autolog integration
- `xgboost` — XGBoost autolog patterns

## Output

The agent generates MLflow tracking code, a registry promotion workflow, or a production serving module depending on the requested stage.
