---
name: model-training
description: Model training for data scientists — delegates to ds-model-trainer agent. Use when training classification or regression models, tuning hyperparameters with Optuna, running cross-validation, or comparing multiple algorithms.
---

# Model Training Command

> Train, tune, and compare ML models with cross-validation and experiment logging

## Usage

```bash
/ds-model-training <description-or-file>
```

## Examples

```bash
/ds-model-training "Binary classification for customer churn with XGBoost"
/ds-model-training "Regression model for house price prediction — tune with Optuna"
/ds-model-training "Compare RandomForest vs LightGBM vs LogisticRegression on this dataset"
/ds-model-training notebooks/training_spec.md
```

---

## What This Command Does

1. Invokes the **ds-model-trainer** agent
2. Reads dataset description or spec to identify problem type and target
3. Loads KB patterns from `scikit-learn` and `xgboost` domains
4. Generates:
   - Baseline model (DummyClassifier / mean predictor)
   - Primary model with cross-validation (stratified KFold or TimeSeriesSplit)
   - Optuna hyperparameter search with MLflow nested run logging
   - Model comparison table (AUC, F1, RMSE per fold)

## Agent Delegation

| Agent | Role |
|-------|------|
| `ds-model-trainer` | Primary — estimators, cross-val, Optuna tuning, model comparison |
| `ds-experiment-tracker` | Escalation — when runs must be logged to MLflow |
| `ds-model-evaluator` | Escalation — when full evaluation suite is needed after training |
| `ds-time-series-analyst` | Escalation — when target is a time series |

## KB Domains Used

- `scikit-learn` — estimators, cross-validation, model selection
- `xgboost` — XGBoost and LightGBM training patterns
- `mlflow` — autologging, run logging, experiment tracking

## Output

The agent generates training code with cross-validation, a model comparison table, and the best-performing pipeline object ready for evaluation.
