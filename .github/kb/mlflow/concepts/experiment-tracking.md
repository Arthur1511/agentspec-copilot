# Experiment Tracking

## Core Concepts

| Term | Definition |
|------|-----------|
| **Tracking Server** | Central store for runs; local `mlruns/` or remote HTTP/DB server |
| **Experiment** | Named collection of related runs (e.g., "fraud-detection-v2") |
| **Run** | A single execution of training code; has params, metrics, artifacts, tags |
| **Parameter** | Input config value — immutable once logged (string/number) |
| **Metric** | Scalar measurement that can be logged per step (float) |
| **Artifact** | Files associated with a run: models, plots, data samples |
| **Tag** | Key-value string metadata; searchable and mutable |

## Tracking Architecture

```
Tracking Server (REST API)
├── Experiment A
│   ├── Run 1 — params, metrics, artifacts, tags
│   ├── Run 2 — ...
│   └── Run 3 — ...
└── Experiment B
    └── ...
```

**Storage backends:**
- `mlruns/` — local filesystem (default; not shareable)
- `sqlite:///mlflow.db` — SQLite (single-user team sharing)
- `postgresql://...` — PostgreSQL (production teams)
- `s3://bucket/mlflow` — remote artifact store

## Basic Tracking Workflow

```python
import mlflow
from sklearn.metrics import accuracy_score, roc_auc_score, f1_score
from sklearn.model_selection import cross_val_score
import numpy as np

mlflow.set_tracking_uri("http://localhost:5000")   # env: MLFLOW_TRACKING_URI
mlflow.set_experiment("churn-prediction")

def train_and_log(X_train, X_test, y_train, y_test,
                  n_estimators: int = 100,
                  max_depth: int = 6) -> str:
    with mlflow.start_run(run_name=f"rf-n{n_estimators}-d{max_depth}") as run:
        # ── Parameters ───────────────────────────────────────────────
        mlflow.log_params({
            "n_estimators": n_estimators,
            "max_depth": max_depth,
            "train_size": len(X_train),
            "n_features": X_train.shape[1],
        })

        # ── Training ─────────────────────────────────────────────────
        from sklearn.ensemble import RandomForestClassifier
        model = RandomForestClassifier(
            n_estimators=n_estimators,
            max_depth=max_depth,
            random_state=42,
            n_jobs=-1
        )
        model.fit(X_train, y_train)

        # ── Metrics ──────────────────────────────────────────────────
        y_pred = model.predict(X_test)
        y_prob = model.predict_proba(X_test)[:, 1]
        mlflow.log_metrics({
            "accuracy": accuracy_score(y_test, y_pred),
            "roc_auc":  roc_auc_score(y_test, y_prob),
            "f1":       f1_score(y_test, y_pred),
        })

        # ── CV score (optional, but valuable) ────────────────────────
        cv_scores = cross_val_score(model, X_train, y_train, cv=5, scoring="roc_auc")
        mlflow.log_metric("cv_auc_mean", cv_scores.mean())
        mlflow.log_metric("cv_auc_std", cv_scores.std())

        # ── Tags ─────────────────────────────────────────────────────
        mlflow.set_tags({
            "model_type": "RandomForest",
            "data_version": "v2.1",
            "author": "ds-team",
        })

        # ── Model ────────────────────────────────────────────────────
        mlflow.sklearn.log_model(model, artifact_path="model")

        return run.info.run_id
```

## Logging Training Curves (Step Metrics)

```python
with mlflow.start_run():
    for epoch in range(1, 51):
        train_loss = train_one_epoch(model, loader)
        val_loss = evaluate(model, val_loader)
        mlflow.log_metrics({
            "train_loss": train_loss,
            "val_loss": val_loss,
        }, step=epoch)
        # Early stopping check
        if val_loss < best_val:
            best_val = val_loss
            mlflow.log_metric("best_val_loss", best_val, step=epoch)
```

## Autologging

```python
# Enable BEFORE calling fit()
mlflow.sklearn.autolog(
    log_input_examples=True,     # log sample input rows
    log_model_signatures=True,   # infer input/output schema
    log_models=True,
    log_datasets=False,          # set True for data lineage
    max_tuning_runs=5,           # for GridSearchCV child runs
    silent=True,
)

# XGBoost
mlflow.xgboost.autolog(log_every_n_iter=5)

# Disable after training to avoid unwanted logging
mlflow.sklearn.autolog(disable=True)
```

## Environment Capture

```python
with mlflow.start_run():
    # Log conda/pip environment
    mlflow.log_text("\n".join([f"{p.project_name}=={p.version}"
                                for p in __import__("pkg_resources").working_set]),
                    "requirements.txt")

    # Log git commit (if in a repo)
    import subprocess
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip()
    mlflow.set_tag("git_commit", commit)
```

## Best Practices

| Practice | Rationale |
|---------|-----------|
| Set experiment before `start_run` | Keeps runs organized by task |
| Always use `run_name` | Human-readable identification |
| Log `data_version` tag | Reproducibility — what data was used |
| Log `git_commit` tag | Reproducibility — what code was used |
| Log CV metrics, not just test metrics | CV is less biased than single train/test split |
| Use `with mlflow.start_run()` context | Ensures run ends cleanly on exception |
| Use `nested=True` for sweeps | Clean parent/child hierarchy |
