# MLflow — Quick Reference

## Server Setup

```bash
# Local file store (development)
mlflow ui                               # http://localhost:5000

# Remote tracking server
mlflow server \
  --backend-store-uri postgresql://... \
  --default-artifact-root s3://my-bucket/mlflow \
  --host 0.0.0.0 --port 5000
```

```python
import mlflow
mlflow.set_tracking_uri("http://localhost:5000")   # or env var MLFLOW_TRACKING_URI
mlflow.set_experiment("experiment-name")            # creates if not exists
```

## Core Logging API

```python
with mlflow.start_run(run_name="my-run", tags={"env": "dev"}):
    # Parameters (hyperparams, config)
    mlflow.log_param("n_estimators", 100)
    mlflow.log_params({"lr": 0.01, "max_depth": 6})

    # Metrics (scalars, per step)
    mlflow.log_metric("accuracy", 0.92)
    mlflow.log_metric("loss", 0.123, step=10)
    mlflow.log_metrics({"precision": 0.91, "recall": 0.88})

    # Artifacts (files, directories)
    mlflow.log_artifact("report.html")
    mlflow.log_artifacts("plots/", artifact_path="plots")
    mlflow.log_figure(fig, "confusion_matrix.png")   # matplotlib Figure

    # Model
    mlflow.sklearn.log_model(model, "model")
```

## Autologging

```python
mlflow.sklearn.autolog()       # params, metrics, model, feature importances
mlflow.xgboost.autolog()       # eval metrics per round, feature importance
mlflow.pytorch.autolog()       # loss per epoch
mlflow.autolog()               # enable for all supported frameworks

# Disable selectively
mlflow.sklearn.autolog(log_models=False, log_input_examples=False)
```

## Experiment Management

```python
exp = mlflow.set_experiment("fraud-detection-v2")
exp_id = exp.experiment_id

# Get or create
exp = mlflow.get_experiment_by_name("fraud-detection-v2")
if exp is None:
    mlflow.create_experiment("fraud-detection-v2",
                              artifact_location="s3://bucket/exp")
```

## Run Search

```python
client = mlflow.MlflowClient()

runs = mlflow.search_runs(
    experiment_names=["fraud-detection-v2"],
    filter_string="metrics.f1 > 0.85 AND params.n_estimators = '100'",
    order_by=["metrics.f1 DESC"],
    max_results=10,
)
best_run = runs.iloc[0]
print(best_run[["run_id", "metrics.f1", "params.n_estimators"]])
```

## Model Registry

```python
# Register
mlflow.sklearn.log_model(model, "model",
                          registered_model_name="fraud-classifier")

# Transition stage
client.transition_model_version_stage(
    name="fraud-classifier", version=3, stage="Production",
    archive_existing_versions=True
)

# Load
model = mlflow.sklearn.load_model("models:/fraud-classifier/Production")
model = mlflow.sklearn.load_model("models:/fraud-classifier/3")  # by version
```

## Artifact Access

```python
# Download artifact
local_path = client.download_artifacts(run_id, "plots/roc_curve.png", "/tmp/")

# List artifacts
artifacts = client.list_artifacts(run_id, path="plots")
for a in artifacts:
    print(a.path, a.file_size)
```

## Run Context

```python
# Nested runs (hyperparameter sweeps)
with mlflow.start_run(run_name="sweep") as parent:
    for lr in [0.01, 0.001, 0.0001]:
        with mlflow.start_run(run_name=f"lr={lr}", nested=True):
            mlflow.log_param("lr", lr)
            mlflow.log_metric("val_loss", train_with_lr(lr))
```
