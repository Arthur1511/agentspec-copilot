# Run Management

## Querying Runs Programmatically

```python
import mlflow
import pandas as pd

# Search runs across experiments
runs_df = mlflow.search_runs(
    experiment_names=["churn-prediction", "fraud-detection"],
    filter_string="metrics.roc_auc > 0.90 AND params.model_type = 'RandomForest'",
    order_by=["metrics.roc_auc DESC", "start_time DESC"],
    max_results=50,
)
# Returns DataFrame with columns: run_id, status, start_time,
# metrics.*, params.*, tags.*
print(runs_df[["run_id", "metrics.roc_auc", "params.n_estimators"]].head(10))
```

## Filter String Syntax

```
# Metric comparisons
"metrics.accuracy > 0.85"
"metrics.f1 BETWEEN 0.80 AND 0.95"

# Parameter comparisons (params are stored as strings)
"params.n_estimators = '100'"
"params.model_type LIKE 'Random%'"

# Tag filters
"tags.author = 'alice'"
"tags.env != 'dev'"

# Status
"attributes.status = 'FINISHED'"

# Combining
"metrics.roc_auc > 0.90 AND params.model_type = 'XGBoost' AND tags.validated = 'true'"
```

## Tagging and Annotating Runs

```python
from mlflow import MlflowClient

client = MlflowClient()

# Set tags on active run
with mlflow.start_run() as run:
    mlflow.set_tag("model_type", "RandomForest")
    mlflow.set_tags({"dataset": "v2.1", "author": "ds-team", "env": "dev"})

# Update tags after run
client.set_tag(run_id, "validated", "true")
client.set_tag(run_id, "notes", "Best run so far; overfits slightly at epoch 40")

# Delete a tag
client.delete_tag(run_id, "temp_note")
```

## Run Lifecycle: Active / Deleted

```python
# Delete a run (moves to "Deleted" status, not permanent)
client.delete_run(run_id)

# Restore a deleted run
client.restore_run(run_id)

# Permanently delete (use with caution)
# mlflow gc --backend-store-uri sqlite:///mlflow.db
```

## Comparing Runs: Best Model Selection

```python
def find_best_run(experiment_name: str,
                  metric: str = "roc_auc",
                  min_metric: float = 0.0,
                  require_tags: dict | None = None) -> pd.Series:
    """Return the best run row from an experiment."""
    filter_parts = [f"metrics.{metric} > {min_metric}",
                    "attributes.status = 'FINISHED'"]
    if require_tags:
        for k, v in require_tags.items():
            filter_parts.append(f"tags.{k} = '{v}'")

    runs = mlflow.search_runs(
        experiment_names=[experiment_name],
        filter_string=" AND ".join(filter_parts),
        order_by=[f"metrics.{metric} DESC"],
        max_results=1,
    )
    if runs.empty:
        raise ValueError(f"No qualifying runs in '{experiment_name}'")
    return runs.iloc[0]

best = find_best_run("churn-prediction", metric="roc_auc",
                     require_tags={"validated": "true"})
print(f"Best run: {best['run_id']} | AUC={best['metrics.roc_auc']:.4f}")
```

## Nested Runs (Hyperparameter Sweeps)

```python
import mlflow

def run_sweep(param_grid: list[dict], X_train, y_train, X_val, y_val):
    with mlflow.start_run(run_name="sweep") as parent_run:
        mlflow.set_tag("run_type", "sweep")
        results = []

        for i, params in enumerate(param_grid):
            with mlflow.start_run(run_name=f"trial-{i}", nested=True):
                mlflow.log_params(params)
                score = train_and_evaluate(params, X_train, y_train, X_val, y_val)
                mlflow.log_metric("val_auc", score)
                results.append({"params": params, "val_auc": score, "run_id": mlflow.active_run().info.run_id})

        # Log best result to parent run
        best = max(results, key=lambda x: x["val_auc"])
        mlflow.log_params({f"best_{k}": v for k, v in best["params"].items()})
        mlflow.log_metric("best_val_auc", best["val_auc"])
        mlflow.set_tag("best_child_run_id", best["run_id"])

    return best
```

## Run Cleanup

```python
# Delete all runs in an experiment older than 30 days
from datetime import datetime, timedelta

cutoff_ms = int((datetime.utcnow() - timedelta(days=30)).timestamp() * 1000)
old_runs = mlflow.search_runs(
    experiment_names=["dev-experiments"],
    filter_string=f"attributes.start_time < {cutoff_ms}",
)
for run_id in old_runs["run_id"]:
    client.delete_run(run_id)
print(f"Deleted {len(old_runs)} old runs")
```
