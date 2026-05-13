# MLflow Knowledge Base

> **MCP Validated:** 2026-05-08

## Purpose

Complete reference for **MLflow** — open-source platform for the end-to-end ML lifecycle: experiment tracking, model registry, artifact management, and model serving.

## Domain Overview

MLflow provides four core components that cover the full ML workflow from experimentation to production deployment. Integrates natively with scikit-learn, XGBoost, PyTorch, TensorFlow, and most ML frameworks via autologging.

**Key Capabilities:**

- Log parameters, metrics, and artifacts per run
- Compare runs across experiments with UI and API
- Register and version models in the Model Registry
- Promote models through Staging → Production lifecycle
- Serve models as REST APIs or load for batch inference
- Track datasets, code versions, and environment specs

## Key Concepts

| Concept | Description | File |
|---------|-------------|------|
| **Experiment Tracking** | Runs, experiments, parameters, metrics, tags | [experiment-tracking.md](concepts/experiment-tracking.md) |
| **Model Registry** | Versioning, stage transitions, annotations | [model-registry.md](concepts/model-registry.md) |
| **Artifact Logging** | Files, figures, datasets, model binaries | [artifact-logging.md](concepts/artifact-logging.md) |
| **Run Management** | Search, compare, delete, tag runs programmatically | [run-management.md](concepts/run-management.md) |

## Patterns

| Pattern | Use Case | File |
|---------|----------|------|
| **Sklearn Integration** | Autologging + manual logging for sklearn pipelines | [sklearn-integration.md](patterns/sklearn-integration.md) |
| **Model Versioning** | Register, transition, and load model versions | [model-versioning.md](patterns/model-versioning.md) |
| **Experiment Comparison** | Query and compare runs; find best model | [experiment-comparison.md](patterns/experiment-comparison.md) |
| **Production Serving** | REST API serving, batch inference, input validation | [production-serving.md](patterns/production-serving.md) |

## Learning Path

### Beginner

1. Read [experiment-tracking.md](concepts/experiment-tracking.md) — core tracking API
2. Study [sklearn-integration.md](patterns/sklearn-integration.md) — log your first run
3. Review [quick-reference.md](quick-reference.md) — key API at a glance

### Intermediate

1. Learn [artifact-logging.md](concepts/artifact-logging.md) — log figures and datasets
2. Apply [experiment-comparison.md](patterns/experiment-comparison.md) — find best run
3. Study [model-registry.md](concepts/model-registry.md) — version your models

### Advanced

1. Master [model-versioning.md](patterns/model-versioning.md) — registry lifecycle
2. Implement [run-management.md](concepts/run-management.md) — programmatic run search
3. Deploy with [production-serving.md](patterns/production-serving.md) — serve models

## Agent Usage

**Target Agents:**

- `ds-experiment-tracker` — primary consumer; logs runs and compares experiments
- `ds-ml-deployer` — registry promotion, model loading, serving deployment
- `ds-model-trainer` — autologging integration during training

**Common Tasks:**

- Log a training run: use `sklearn-integration.md`
- Find best model across experiments: use `experiment-comparison.md`
- Promote model to production: use `model-versioning.md`
- Serve model as REST API: use `production-serving.md`

## Quick Start

```python
import mlflow
import mlflow.sklearn
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

mlflow.set_tracking_uri("http://localhost:5000")   # or "mlruns" for local
mlflow.set_experiment("my-experiment")

with mlflow.start_run(run_name="rf-baseline"):
    # Params
    n_estimators = 100
    mlflow.log_param("n_estimators", n_estimators)

    # Train
    model = RandomForestClassifier(n_estimators=n_estimators, random_state=42)
    model.fit(X_train, y_train)

    # Metrics
    acc = accuracy_score(y_test, model.predict(X_test))
    mlflow.log_metric("accuracy", acc)

    # Model
    mlflow.sklearn.log_model(model, "model",
                              registered_model_name="my-classifier")
    print(f"Run logged: accuracy={acc:.4f}")
```

## Related Domains

- **scikit-learn** — primary framework for logged models
- **xgboost** — autologging support via `mlflow.xgboost.autolog()`
- **python** — Python packaging for model serving
- **data-visualization** — log matplotlib figures as artifacts

## References

- MLflow Docs: <https://mlflow.org/docs/latest/>
- MLflow GitHub: <https://github.com/mlflow/mlflow>
- Tracking API: <https://mlflow.org/docs/latest/tracking.html>
- Model Registry: <https://mlflow.org/docs/latest/model-registry.html>
