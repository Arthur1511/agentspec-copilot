# Artifact Logging

## What Are Artifacts?

Artifacts are files associated with a run: model binaries, figures, datasets, configuration files, and reports. They are stored in the artifact store (local or remote S3/GCS/Azure Blob).

## Logging Artifacts

```python
import mlflow
import matplotlib.pyplot as plt
import pandas as pd

with mlflow.start_run():

    # ── Single file ──────────────────────────────────────────────────
    mlflow.log_artifact("model_report.html")
    mlflow.log_artifact("feature_importance.csv", artifact_path="data")

    # ── Directory ────────────────────────────────────────────────────
    mlflow.log_artifacts("outputs/", artifact_path="outputs")

    # ── String/text content (no temp file needed) ────────────────────
    mlflow.log_text("col1,col2\n1,2\n3,4", "sample_data.csv")
    mlflow.log_text(model_config_json, "config.json")

    # ── Dict → JSON ──────────────────────────────────────────────────
    mlflow.log_dict({"threshold": 0.42, "model_type": "RF"}, "run_config.json")

    # ── Matplotlib Figure ────────────────────────────────────────────
    fig, ax = plt.subplots()
    ax.plot(fpr, tpr)
    ax.set_title("ROC Curve")
    mlflow.log_figure(fig, "plots/roc_curve.png")
    plt.close(fig)

    # ── Pandas DataFrame ─────────────────────────────────────────────
    # Save to temp file first, then log
    import tempfile, os
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, "eval_results.csv")
        eval_df.to_csv(path, index=False)
        mlflow.log_artifact(path, artifact_path="evaluation")
```

## Logging Standard EDA Artifacts

```python
import mlflow
import seaborn as sns, matplotlib.pyplot as plt
import numpy as np

def log_eda_artifacts(df, target: str, run):
    """Log standard EDA figures as MLflow artifacts."""
    import tempfile, pathlib

    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)

        # Correlation heatmap
        fig, ax = plt.subplots(figsize=(10, 8))
        corr = df.select_dtypes("number").corr()
        mask = np.triu(np.ones_like(corr, dtype=bool))
        sns.heatmap(corr, mask=mask, annot=True, fmt=".2f",
                    cmap="coolwarm", center=0, ax=ax)
        fig.savefig(tmp / "correlation_heatmap.png", dpi=120, bbox_inches="tight")
        plt.close(fig)

        # Class distribution
        fig, ax = plt.subplots(figsize=(6, 4))
        df[target].value_counts().plot.bar(ax=ax, color="steelblue")
        ax.set_title("Target Distribution")
        fig.savefig(tmp / "target_distribution.png", dpi=120, bbox_inches="tight")
        plt.close(fig)

        mlflow.log_artifacts(str(tmp), artifact_path="eda")
```

## Accessing Artifacts After a Run

```python
from mlflow import MlflowClient

client = MlflowClient()

# List all artifacts in a run
artifacts = client.list_artifacts(run_id)
for a in artifacts:
    print(a.path, a.is_dir, a.file_size)

# Download a specific artifact to local path
local_path = client.download_artifacts(run_id, "plots/roc_curve.png", "/tmp/")

# Load model artifact directly
model = mlflow.sklearn.load_model(f"runs:/{run_id}/model")

# Load custom artifact (JSON)
import json
path = client.download_artifacts(run_id, "run_config.json", "/tmp/")
with open(path) as f:
    config = json.load(f)
```

## Dataset Tracking (MLflow 2.4+)

```python
import mlflow

# Track dataset used in a run
dataset = mlflow.data.from_pandas(
    df, source="s3://bucket/data/train_v2.parquet",
    name="churn-train-v2", targets="churned"
)

with mlflow.start_run():
    mlflow.log_input(dataset, context="training")
    # Stored as run input with schema, digest, source URI
```

## Artifact Organization Best Practices

```
run artifacts/
├── model/          ← MLflow model directory (auto-created by log_model)
├── plots/          ← Evaluation figures (ROC, PR, calibration)
│   ├── roc_curve.png
│   └── calibration.png
├── eda/            ← EDA figures
├── data/           ← Sample data, feature names
│   ├── feature_names.txt
│   └── sample_input.csv
└── reports/        ← HTML / PDF reports
    └── model_card.html
```

```python
# Enforce structure by always passing artifact_path
mlflow.log_figure(roc_fig, "plots/roc_curve.png")
mlflow.log_figure(cal_fig, "plots/calibration.png")
mlflow.log_artifact("feature_names.txt", artifact_path="data")
```
