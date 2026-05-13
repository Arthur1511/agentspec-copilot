# Model Registry

## Overview

The MLflow Model Registry provides a central store for managing the full lifecycle of ML models: versioning, stage transitions, annotations, and lineage.

```
Model Registry
└── Registered Model: "fraud-classifier"
    ├── Version 1 — Archived
    ├── Version 2 — Staging (testing)
    └── Version 3 — Production (live)
```

**Stage Lifecycle:**
```
None → Staging → Production → Archived
```

## Registering a Model

```python
import mlflow

# Method 1: Register during training run
with mlflow.start_run():
    # ... train model ...
    mlflow.sklearn.log_model(
        model,
        artifact_path="model",
        registered_model_name="fraud-classifier",     # creates if not exists
        input_example=X_train[:5],                    # sample input schema
        signature=mlflow.models.infer_signature(X_train, model.predict(X_train)),
    )

# Method 2: Register from existing run
run_id = "abc123..."
model_uri = f"runs:/{run_id}/model"
mv = mlflow.register_model(model_uri, "fraud-classifier")
print(f"Registered as version {mv.version}")
```

## Stage Transitions

```python
from mlflow import MlflowClient

client = MlflowClient()

# Promote version 3 to Staging
client.transition_model_version_stage(
    name="fraud-classifier",
    version=3,
    stage="Staging",
    archive_existing_versions=False,   # keep old staging
)

# Promote Staging → Production (archive existing Production)
client.transition_model_version_stage(
    name="fraud-classifier",
    version=3,
    stage="Production",
    archive_existing_versions=True,    # archive current Production
)

# Archive manually
client.transition_model_version_stage(
    name="fraud-classifier",
    version=1,
    stage="Archived",
)
```

## Annotations and Metadata

```python
# Add description to registered model
client.update_registered_model(
    name="fraud-classifier",
    description="Binary fraud classifier for transactions > $500."
)

# Add description to specific version
client.update_model_version(
    name="fraud-classifier",
    version=3,
    description="RF n=200, d=8, trained on 2026-05 data. AUC=0.934."
)

# Add tags
client.set_registered_model_tag("fraud-classifier", "team", "ds-payments")
client.set_model_version_tag("fraud-classifier", "3", "validated_by", "qa-pipeline")
```

## Querying the Registry

```python
# List all versions of a model
versions = client.search_model_versions("name='fraud-classifier'")
for v in versions:
    print(f"v{v.version} — {v.current_stage} — run_id={v.run_id[:8]}")

# Get current Production version
prod_versions = client.get_latest_versions("fraud-classifier", stages=["Production"])
latest_prod = prod_versions[0]
print(f"Production: v{latest_prod.version}")

# List all registered models
models = client.search_registered_models(
    filter_string="tags.team = 'ds-payments'"
)
```

## Model Signatures and Input Examples

```python
from mlflow.models import infer_signature
import pandas as pd

# Infer signature from training data
signature = infer_signature(X_train, model.predict(X_train))
# signature.inputs: Schema([ColSpec('double', 'feature_1'), ...])
# signature.outputs: Schema([TensorSpec(np.dtype('int64'), (-1,))])

# Input example (stored as artifact for documentation)
input_example = X_train.iloc[:3]

with mlflow.start_run():
    mlflow.sklearn.log_model(
        model, "model",
        signature=signature,
        input_example=input_example,
        registered_model_name="fraud-classifier",
    )
```

## Registry Decision Guide

| Situation | Action |
|-----------|--------|
| New model outperforms on validation | Register + promote to Staging |
| Staging passes CI/CD tests | Promote to Production |
| Production degrading in monitoring | Archive + rollback to previous version |
| Experimenting only | Don't register; use run artifacts |
| Multiple models for same task | Use same registered model name, different versions |
