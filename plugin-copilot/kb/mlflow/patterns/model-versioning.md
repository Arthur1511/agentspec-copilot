# Model Versioning Pattern

## Purpose

End-to-end workflow for registering, versioning, promoting, and loading models through the MLflow Model Registry — from experiment to production deployment.

---

## Step 1 — Register Best Model

```python
import mlflow
from mlflow import MlflowClient

client = MlflowClient()

def register_best_model(
    experiment_name: str,
    registered_name: str,
    metric: str = "roc_auc",
    min_score: float = 0.85,
    require_tags: dict | None = None,
) -> "ModelVersion":
    """Find best run and register its model."""
    filter_parts = [
        f"metrics.{metric} > {min_score}",
        "attributes.status = 'FINISHED'",
    ]
    if require_tags:
        for k, v in (require_tags or {}).items():
            filter_parts.append(f"tags.{k} = '{v}'")

    runs = mlflow.search_runs(
        experiment_names=[experiment_name],
        filter_string=" AND ".join(filter_parts),
        order_by=[f"metrics.{metric} DESC"],
        max_results=1,
    )
    if runs.empty:
        raise ValueError(f"No qualifying runs (metric={metric} > {min_score})")

    best_run = runs.iloc[0]
    model_uri = f"runs:/{best_run['run_id']}/model"

    mv = mlflow.register_model(model_uri, registered_name)
    client.update_model_version(
        name=registered_name,
        version=mv.version,
        description=(
            f"Auto-registered from run {best_run['run_id'][:8]}. "
            f"{metric}={best_run[f'metrics.{metric}']:.4f}"
        ),
    )
    print(f"Registered {registered_name} v{mv.version} "
          f"({metric}={best_run[f'metrics.{metric}']:.4f})")
    return mv
```

---

## Step 2 — Validate and Promote to Staging

```python
def promote_to_staging(
    model_name: str,
    version: int,
    validation_fn,           # callable: model → bool
    X_val, y_val,
) -> bool:
    """Load model version, validate, and promote to Staging if passes."""
    model = mlflow.sklearn.load_model(f"models:/{model_name}/{version}")
    passed = validation_fn(model, X_val, y_val)

    if passed:
        client.transition_model_version_stage(
            name=model_name,
            version=version,
            stage="Staging",
            archive_existing_versions=False,
        )
        client.set_model_version_tag(model_name, str(version), "validation", "passed")
        print(f"✅ {model_name} v{version} → Staging")
    else:
        client.set_model_version_tag(model_name, str(version), "validation", "failed")
        print(f"❌ {model_name} v{version} — validation FAILED; not promoted")
    return passed


def default_classifier_validation(model, X_val, y_val,
                                   min_auc: float = 0.85) -> bool:
    from sklearn.metrics import roc_auc_score
    y_prob = model.predict_proba(X_val)[:, 1]
    auc = roc_auc_score(y_val, y_prob)
    print(f"  Validation AUC: {auc:.4f} (threshold: {min_auc})")
    return auc >= min_auc
```

---

## Step 3 — Promote to Production

```python
def promote_to_production(model_name: str, version: int,
                           approval_note: str = "") -> None:
    """Promote Staging version to Production, archive previous Production."""
    # Verify it's in Staging
    mv = client.get_model_version(model_name, str(version))
    if mv.current_stage != "Staging":
        raise RuntimeError(f"v{version} is in {mv.current_stage}, not Staging")

    client.transition_model_version_stage(
        name=model_name,
        version=version,
        stage="Production",
        archive_existing_versions=True,   # archive old Production
    )
    if approval_note:
        client.set_model_version_tag(model_name, str(version),
                                      "approval_note", approval_note)
    print(f"🚀 {model_name} v{version} → Production")
```

---

## Step 4 — Load Model for Inference

```python
import mlflow

# Load current Production model (always latest Production version)
model = mlflow.sklearn.load_model(f"models:/fraud-classifier/Production")

# Load specific version
model = mlflow.sklearn.load_model(f"models:/fraud-classifier/3")

# Load as generic Python function (framework-agnostic)
pyfunc_model = mlflow.pyfunc.load_model(f"models:/fraud-classifier/Production")
predictions = pyfunc_model.predict(X_new)

# Batch inference with logging
def batch_predict(model_name: str, X: pd.DataFrame,
                  stage: str = "Production") -> pd.DataFrame:
    model = mlflow.sklearn.load_model(f"models:/{model_name}/{stage}")
    preds = model.predict(X)
    probs = model.predict_proba(X)[:, 1] if hasattr(model, "predict_proba") else None
    result = X.copy()
    result["prediction"] = preds
    if probs is not None:
        result["probability"] = probs
    return result
```

---

## Step 5 — Rollback

```python
def rollback_production(model_name: str) -> None:
    """Rollback to the most recent Archived version (previous Production)."""
    archived = client.search_model_versions(
        f"name='{model_name}' AND version_stage='Archived'"
    )
    archived_sorted = sorted(archived, key=lambda v: int(v.version), reverse=True)
    if not archived_sorted:
        raise RuntimeError("No archived versions to rollback to")

    rollback_version = archived_sorted[0].version
    client.transition_model_version_stage(
        name=model_name,
        version=rollback_version,
        stage="Production",
        archive_existing_versions=True,
    )
    print(f"⏪ Rolled back {model_name} → v{rollback_version}")
```

---

## Versioning Checklist

```
□ Model registered with signature and input_example
□ Version description includes key metrics and data version
□ Validation function run before Staging promotion
□ Approval note added before Production promotion
□ archive_existing_versions=True when promoting to Production
□ Rollback procedure documented and tested
□ Model version tag "validated=true" set after CI/CD passes
```
