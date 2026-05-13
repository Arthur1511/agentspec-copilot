# Scikit-Learn Integration Pattern

## Purpose

Production-ready template for integrating MLflow tracking into scikit-learn training workflows — combining autologging with manual metric logging and artifact capture.

---

## Setup: Autologging vs Manual

```python
import mlflow
import mlflow.sklearn

# Option A — Autologging (fastest; logs params, metrics, model, feature importances)
mlflow.sklearn.autolog(
    log_input_examples=True,
    log_model_signatures=True,
    max_tuning_runs=10,           # child runs for GridSearchCV
    silent=True,
)

# Option B — Manual (full control; required for custom metrics)
# Call mlflow.log_param / log_metric / log_model explicitly
```

---

## Full Training Template

```python
import mlflow
import mlflow.sklearn
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.ensemble import RandomForestClassifier
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import (accuracy_score, roc_auc_score,
                              f1_score, average_precision_score)
from sklearn.model_selection import cross_val_score
from mlflow.models import infer_signature

def train_sklearn_run(
    pipeline: Pipeline,
    X_train, X_test, y_train, y_test,
    params: dict,
    experiment_name: str = "default",
    run_name: str | None = None,
    register_as: str | None = None,
) -> str:
    mlflow.set_experiment(experiment_name)

    with mlflow.start_run(run_name=run_name) as run:
        # ── Log parameters ─────────────────────────────────────────
        mlflow.log_params(params)
        mlflow.log_param("train_n", len(X_train))
        mlflow.log_param("test_n", len(X_test))
        mlflow.log_param("n_features", X_train.shape[1])

        # ── Train ──────────────────────────────────────────────────
        pipeline.set_params(**{k: v for k, v in params.items()
                               if "__" in k})  # only pipeline params
        pipeline.fit(X_train, y_train)

        # ── Evaluate ───────────────────────────────────────────────
        y_pred = pipeline.predict(X_test)
        y_prob = pipeline.predict_proba(X_test)[:, 1]
        metrics = {
            "accuracy":  accuracy_score(y_test, y_pred),
            "roc_auc":   roc_auc_score(y_test, y_prob),
            "f1":        f1_score(y_test, y_pred),
            "avg_prec":  average_precision_score(y_test, y_prob),
        }
        mlflow.log_metrics(metrics)

        # ── Cross-validation ───────────────────────────────────────
        cv_auc = cross_val_score(pipeline, X_train, y_train,
                                  cv=5, scoring="roc_auc", n_jobs=-1)
        mlflow.log_metric("cv_auc_mean", cv_auc.mean())
        mlflow.log_metric("cv_auc_std", cv_auc.std())

        # ── Figures ────────────────────────────────────────────────
        from sklearn.metrics import RocCurveDisplay
        fig, ax = plt.subplots(figsize=(6, 5))
        RocCurveDisplay.from_predictions(y_test, y_prob, ax=ax)
        mlflow.log_figure(fig, "plots/roc_curve.png")
        plt.close(fig)

        # ── Feature importance ─────────────────────────────────────
        if hasattr(pipeline[-1], "feature_importances_"):
            step_name = pipeline.steps[-1][0]
            importances = pipeline[-1].feature_importances_
            feat_df = pd.DataFrame(
                {"feature": X_train.columns if hasattr(X_train, "columns") else range(len(importances)),
                 "importance": importances}
            ).sort_values("importance", ascending=False)
            mlflow.log_text(feat_df.to_csv(index=False), "data/feature_importances.csv")

        # ── Log model ──────────────────────────────────────────────
        signature = infer_signature(X_train, pipeline.predict(X_train))
        mlflow.sklearn.log_model(
            pipeline, "model",
            signature=signature,
            input_example=X_train.iloc[:3] if hasattr(X_train, "iloc") else X_train[:3],
            registered_model_name=register_as,
        )

        print(f"Run {run.info.run_id[:8]}: AUC={metrics['roc_auc']:.4f}, "
              f"CV-AUC={cv_auc.mean():.4f}±{cv_auc.std():.4f}")
        return run.info.run_id
```

---

## GridSearchCV Integration

```python
from sklearn.model_selection import GridSearchCV

mlflow.sklearn.autolog(max_tuning_runs=20)

param_grid = {
    "classifier__n_estimators": [50, 100, 200],
    "classifier__max_depth": [4, 6, 8, None],
}

with mlflow.start_run(run_name="rf-gridsearch"):
    grid = GridSearchCV(pipeline, param_grid, cv=5,
                        scoring="roc_auc", n_jobs=-1, verbose=1)
    grid.fit(X_train, y_train)

    # Best params and score logged automatically by autolog
    mlflow.log_metric("best_cv_auc", grid.best_score_)
    mlflow.log_params({f"best_{k}": v for k, v in grid.best_params_.items()})

print(f"Best params: {grid.best_params_}")
```

---

## Regression Template

```python
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

with mlflow.start_run(run_name=run_name):
    # ... train pipeline ...
    y_pred = pipeline.predict(X_test)
    mlflow.log_metrics({
        "rmse":  mean_squared_error(y_test, y_pred, squared=False),
        "mae":   mean_absolute_error(y_test, y_pred),
        "r2":    r2_score(y_test, y_pred),
        "mape":  np.mean(np.abs((y_test - y_pred) / y_test)) * 100,
    })
    mlflow.sklearn.log_model(pipeline, "model",
                              registered_model_name=register_as)
```

---

## Output Checklist

```
□ Experiment name set before start_run
□ All hyperparameters logged as params
□ Train/test sizes logged as params
□ Evaluation metrics logged (accuracy, AUC, F1 for clf; RMSE, MAE, R² for reg)
□ CV metrics logged (cv_mean, cv_std)
□ ROC/PR curve figures logged as artifacts
□ Feature importance logged if available
□ Model logged with signature and input_example
□ register_as set for production candidates
```
