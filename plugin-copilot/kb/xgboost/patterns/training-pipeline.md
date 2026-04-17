# Training Pipeline

> **MCP Validated:** 2026-04-17

## Overview

Production-ready XGBoost training pipeline with DMatrix format, early stopping, validation monitoring, and model persistence.

## Complete Pipeline

```python
import xgboost as xgb
from sklearn.model_selection import train_test_split
from sklearn.datasets import load_breast_cancer
from sklearn.metrics import roc_auc_score, classification_report
import numpy as np

# ═══════════════════════════════════════════════════════════════════
# 1. DATA PREPARATION
# ═══════════════════════════════════════════════════════════════════

# Load data
data = load_breast_cancer()
X, y = data.data, data.target
feature_names = data.feature_names

# Split: train (64%), validation (16%), test (20%)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
X_train, X_val, y_train, y_val = train_test_split(
    X_train, y_train, test_size=0.2, random_state=42, stratify=y_train
)

print(f"Train size: {X_train.shape[0]}")
print(f"Val size:   {X_val.shape[0]}")
print(f"Test size:  {X_test.shape[0]}")

# Convert to DMatrix (native XGBoost format — faster than DataFrame)
dtrain = xgb.DMatrix(X_train, label=y_train, feature_names=feature_names)
dval = xgb.DMatrix(X_val, label=y_val, feature_names=feature_names)
dtest = xgb.DMatrix(X_test, feature_names=feature_names)

# ═══════════════════════════════════════════════════════════════════
# 2. HYPERPARAMETERS
# ═══════════════════════════════════════════════════════════════════

params = {
    # Task
    "objective": "binary:logistic",
    "eval_metric": "auc",
    
    # Tree structure
    "max_depth": 6,
    "min_child_weight": 1,
    "gamma": 0.1,
    
    # Learning
    "learning_rate": 0.1,
    "subsample": 0.8,
    "colsample_bytree": 0.8,
    
    # Regularization
    "lambda": 1.0,
    "alpha": 0.0,
    
    # Performance
    "tree_method": "hist",
    
    # Reproducibility
    "seed": 42,
}

# ═══════════════════════════════════════════════════════════════════
# 3. TRAINING WITH EARLY STOPPING
# ═══════════════════════════════════════════════════════════════════

# Evaluation sets for monitoring
evals = [(dtrain, "train"), (dval, "val")]

# Train
model = xgb.train(
    params,
    dtrain,
    num_boost_round=1000,              # Max iterations
    evals=evals,                        # Monitor both sets
    early_stopping_rounds=50,           # Stop if no improvement for 50 rounds
    verbose_eval=100,                   # Print every 100 rounds
)

print(f"\nBest iteration: {model.best_iteration}")
print(f"Best validation AUC: {model.best_score:.4f}")

# ═══════════════════════════════════════════════════════════════════
# 4. PREDICTION
# ═══════════════════════════════════════════════════════════════════

# Predict probabilities
y_pred_proba = model.predict(dtest)

# Predict classes (threshold 0.5)
y_pred_class = (y_pred_proba > 0.5).astype(int)

# ═══════════════════════════════════════════════════════════════════
# 5. EVALUATION
# ═══════════════════════════════════════════════════════════════════

test_auc = roc_auc_score(y_test, y_pred_proba)
print(f"\nTest AUC: {test_auc:.4f}")

print("\nClassification Report:")
print(classification_report(y_test, y_pred_class, target_names=data.target_names))

# ═══════════════════════════════════════════════════════════════════
# 6. FEATURE IMPORTANCE
# ═══════════════════════════════════════════════════════════════════

importance = model.get_score(importance_type='gain')
sorted_importance = sorted(importance.items(), key=lambda x: x[1], reverse=True)

print("\nTop 10 Features (by gain):")
for feature, gain in sorted_importance[:10]:
    print(f"  {feature:30s}: {gain:.2f}")

# ═══════════════════════════════════════════════════════════════════
# 7. MODEL PERSISTENCE
# ═══════════════════════════════════════════════════════════════════

# Save model (Universal Binary JSON format — language-agnostic)
model.save_model("xgboost_model.ubj")
print("\n✓ Model saved to xgboost_model.ubj")

# Save feature names (important for later)
with open("feature_names.txt", "w") as f:
    f.write("\n".join(feature_names))

# Load model
loaded_model = xgb.Booster()
loaded_model.load_model("xgboost_model.ubj")

# Verify loaded model produces same predictions
y_pred_loaded = loaded_model.predict(dtest)
assert np.allclose(y_pred_proba, y_pred_loaded), "Loaded model predictions differ!"
print("✓ Model loaded successfully, predictions match")
```

## Configuration Table

| Parameter | Type | Value | Purpose |
|-----------|------|-------|---------|
| `objective` | str | `binary:logistic` | Binary classification with probabilities |
| `eval_metric` | str | `auc` | Area under ROC curve |
| `max_depth` | int | 6 | Maximum tree depth |
| `learning_rate` | float | 0.1 | Step size shrinkage |
| `subsample` | float | 0.8 | Row sampling ratio |
| `colsample_bytree` | float | 0.8 | Column sampling ratio |
| `lambda` | float | 1.0 | L2 regularization |
| `gamma` | float | 0.1 | Minimum split loss |
| `tree_method` | str | `hist` | Fast histogram-based algorithm |
| `num_boost_round` | int | 1000 | Maximum boosting rounds |
| `early_stopping_rounds` | int | 50 | Stop if no improvement for 50 rounds |

## sklearn API Alternative

For simple use cases, sklearn API is more concise:

```python
from xgboost import XGBClassifier

# Train
model = XGBClassifier(
    objective='binary:logistic',
    eval_metric='auc',
    max_depth=6,
    learning_rate=0.1,
    n_estimators=1000,
    subsample=0.8,
    colsample_bytree=0.8,
    reg_lambda=1.0,
    gamma=0.1,
    tree_method='hist',
    random_state=42,
)

model.fit(
    X_train, y_train,
    eval_set=[(X_val, y_val)],
    early_stopping_rounds=50,
    verbose=100,
)

# Predict
y_pred = model.predict_proba(X_test)[:, 1]

# Save
model.save_model("model.ubj")
```

**When to use sklearn API**:
- Integration with sklearn pipelines
- Simple workflows
- Cross-validation with `cross_val_score`

**When to use native API**:
- Production systems (more control)
- Custom objectives/metrics
- Need DMatrix optimizations

## Pipeline with Preprocessing

```python
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.compose import ColumnTransformer

# XGBoost doesn't need scaling, but useful for mixed pipelines
preprocessor = ColumnTransformer(
    transformers=[
        ('num', StandardScaler(), list(range(X.shape[1]))),
    ]
)

pipeline = Pipeline([
    ('preprocessor', preprocessor),
    ('classifier', XGBClassifier(
        max_depth=6,
        learning_rate=0.1,
        n_estimators=1000,
        tree_method='hist',
        random_state=42,
    ))
])

# Train pipeline
pipeline.fit(X_train, y_train)

# Predict
y_pred = pipeline.predict(X_test)

# Save entire pipeline
import joblib
joblib.dump(pipeline, 'pipeline.pkl')
```

## Error Handling

```python
try:
    model = xgb.train(params, dtrain, num_boost_round=1000, evals=evals)
except xgb.core.XGBoostError as e:
    print(f"XGBoost training failed: {e}")
    # Handle specific errors:
    if "check failed" in str(e):
        print("Data validation error — check for NaN/Inf values")
    elif "GPU" in str(e):
        print("GPU error — falling back to CPU")
        params['tree_method'] = 'hist'
        model = xgb.train(params, dtrain, num_boost_round=1000)
```

## Production Checklist

- [ ] Data split: train / validation / test
- [ ] Use DMatrix for performance
- [ ] Enable early stopping with validation set
- [ ] Monitor both train and validation metrics
- [ ] Save model in `.ubj` format (language-agnostic)
- [ ] Save feature names separately
- [ ] Log hyperparameters and metrics
- [ ] Extract feature importance
- [ ] Verify loaded model predictions match

## When to Use This Pattern

| Use Case | Fit |
|----------|-----|
| **Binary classification** | ✓ Perfect (adjust objective to `binary:logistic`) |
| **Multiclass classification** | ✓ Change objective to `multi:softmax` |
| **Regression** | ✓ Change objective to `reg:squarederror` |
| **Ranking** | Partial (need query groups) |
| **Production deployment** | ✓ Perfect (ubj format + DMatrix) |
| **Quick experimentation** | Use sklearn API instead |

## Related Patterns

- [early-stopping.md](early-stopping.md) — Detailed early stopping configurations
- [hyperparameter-tuning.md](hyperparameter-tuning.md) — Optimize pipeline parameters
- [cross-validation.md](cross-validation.md) — Robust model evaluation

## References

- XGBoost Python API: https://xgboost.readthedocs.io/en/stable/python/python_api.html
- DMatrix Documentation: https://xgboost.readthedocs.io/en/stable/python/python_intro.html#data-interface
