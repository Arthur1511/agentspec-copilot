# Early Stopping

> **MCP Validated:** 2026-04-17

## Overview

**Early stopping** prevents overfitting by monitoring a validation metric and stopping training when performance stops improving. This allows setting a high `num_boost_round` without overfitting.

## How Early Stopping Works

1. **Monitor metric**: Track evaluation metric (e.g., AUC, RMSE) on validation set after each boosting round
2. **Compare to best**: Check if current metric is better than the best seen so far
3. **Count rounds**: If no improvement, increment counter
4. **Stop**: If counter reaches `early_stopping_rounds`, stop training
5. **Revert**: Use model from the best iteration, not the last

**Key insight**: Training can continue past the optimal point without harming the final model, as long as early stopping is enabled.

## Native API (xgb.train)

### Basic Usage

```python
import xgboost as xgb
from sklearn.datasets import load_diabetes
from sklearn.model_selection import train_test_split
import numpy as np

# Data
X, y = load_diabetes(return_X_y=True)
X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.2, random_state=42)

# DMatrix
dtrain = xgb.DMatrix(X_train, label=y_train)
dval = xgb.DMatrix(X_val, label=y_val)

# Parameters
params = {
    'objective': 'reg:squarederror',
    'eval_metric': 'rmse',
    'max_depth': 5,
    'learning_rate': 0.1,
    'tree_method': 'hist',
}

# Train with early stopping
model = xgb.train(
    params,
    dtrain,
    num_boost_round=1000,                    # High value — early stopping will stop earlier
    evals=[(dtrain, 'train'), (dval, 'val')],  # Monitor both sets
    early_stopping_rounds=50,                 # Stop if no improvement for 50 rounds
    verbose_eval=100,                         # Print every 100 rounds
)

print(f"\nBest iteration: {model.best_iteration}")
print(f"Best validation RMSE: {model.best_score:.2f}")

# Predict using best iteration (automatic)
y_pred = model.predict(dval)
```

**Output example**:
```
[0]     train-rmse:67.32   val-rmse:68.45
[100]   train-rmse:42.15   val-rmse:48.92
[200]   train-rmse:38.21   val-rmse:52.34
[250]   train-rmse:36.88   val-rmse:54.12
Stopping. Best iteration: [150] with val-rmse: 48.01

Best iteration: 150
Best validation RMSE: 48.01
```

### Monitoring Multiple Metrics

```python
params = {
    'objective': 'binary:logistic',
    'eval_metric': ['auc', 'logloss'],  # Monitor multiple metrics
    'max_depth': 6,
    'learning_rate': 0.1,
}

model = xgb.train(
    params,
    dtrain,
    num_boost_round=1000,
    evals=[(dtrain, 'train'), (dval, 'val')],
    early_stopping_rounds=50,
    verbose_eval=50,
)

# Early stopping uses the LAST metric in the list
print(f"Best iteration: {model.best_iteration}")
print(f"Best score (logloss): {model.best_score:.4f}")
```

**Note**: Early stopping uses the **last metric** in `eval_metric` list for stopping decisions.

## sklearn API (XGBClassifier/XGBRegressor)

### Basic Usage

```python
from xgboost import XGBRegressor

model = XGBRegressor(
    n_estimators=1000,
    max_depth=5,
    learning_rate=0.1,
    tree_method='hist',
    random_state=42,
)

# Fit with early stopping
model.fit(
    X_train, y_train,
    eval_set=[(X_val, y_val)],        # Validation set
    early_stopping_rounds=50,          # Stop if no improvement
    verbose=100,                       # Print frequency
)

print(f"Best iteration: {model.best_iteration}")
print(f"Best score: {model.best_score}")

# Predict (uses best iteration automatically)
y_pred = model.predict(X_val)
```

### Multiple Evaluation Sets

```python
from xgboost import XGBClassifier

model = XGBClassifier(
    n_estimators=1000,
    max_depth=6,
    learning_rate=0.1,
    eval_metric='auc',
    random_state=42,
)

# Monitor both train and validation
model.fit(
    X_train, y_train,
    eval_set=[(X_train, y_train), (X_val, y_val)],
    eval_metric=['logloss', 'auc'],
    early_stopping_rounds=50,
    verbose=50,
)

# Access training history
print("Validation AUC history:")
print(model.evals_result()['validation_1']['auc'][:10])  # First 10 rounds
```

## Callback API (Advanced Control)

```python
# Custom early stopping callback
early_stop = xgb.callback.EarlyStopping(
    rounds=50,                  # Patience
    metric_name='val-auc',      # Metric to monitor
    data_name='val',            # Dataset name
    maximize=True,              # True for AUC, False for RMSE/logloss
    save_best=True,             # Keep best model
)

model = xgb.train(
    params,
    dtrain,
    num_boost_round=1000,
    evals=[(dtrain, 'train'), (dval, 'val')],
    callbacks=[early_stop],
    verbose_eval=False,
)

print(f"Best iteration: {model.best_iteration}")
```

## Recovering Best Model

### Native API

```python
# Train
model = xgb.train(
    params, dtrain,
    num_boost_round=1000,
    evals=[(dval, 'val')],
    early_stopping_rounds=50,
)

# Best iteration stored in model
print(f"Best iteration: {model.best_iteration}")
print(f"Best score: {model.best_score}")

# Prediction automatically uses best iteration
y_pred = model.predict(dval)

# To predict with different iteration (not recommended)
y_pred_iteration_100 = model.predict(dval, iteration_range=(0, 100))
```

### sklearn API

```python
# Train
model = XGBClassifier(n_estimators=1000, random_state=42)
model.fit(
    X_train, y_train,
    eval_set=[(X_val, y_val)],
    early_stopping_rounds=50,
)

# Best iteration
print(f"Best iteration: {model.best_iteration}")
print(f"Number of trees used: {model.best_iteration}")

# Get underlying Booster (if needed)
booster = model.get_booster()
print(f"Booster best iteration: {booster.best_iteration}")
```

## Choosing early_stopping_rounds

| Learning Rate | Typical early_stopping_rounds | Reasoning |
|---------------|------------------------------|-----------|
| 0.3 (high) | 20-30 | Fast learning → early convergence |
| 0.1 (default) | 30-50 | Balanced → moderate patience |
| 0.01-0.05 (low) | 50-100 | Slow learning → more patience |
| 0.001 (very low) | 100-200 | Very slow → long patience |

**Rule of thumb**: `early_stopping_rounds ≈ 1 / learning_rate` (with some minimum like 20).

## Visualization: Training Curves

```python
import matplotlib.pyplot as plt

# Train with history
model = xgb.train(
    params, dtrain,
    num_boost_round=500,
    evals=[(dtrain, 'train'), (dval, 'val')],
    early_stopping_rounds=50,
    verbose_eval=False,
)

# Extract history
results = model.evals_result()
train_rmse = results['train']['rmse']
val_rmse = results['val']['rmse']

# Plot
plt.figure(figsize=(10, 6))
plt.plot(train_rmse, label='Train RMSE')
plt.plot(val_rmse, label='Validation RMSE')
plt.axvline(model.best_iteration, color='red', linestyle='--', label=f'Best iteration ({model.best_iteration})')
plt.xlabel('Boosting Round')
plt.ylabel('RMSE')
plt.title('Training Curves with Early Stopping')
plt.legend()
plt.grid(True)
plt.show()
```

**Expected pattern**:
- Train RMSE: Continuously decreases
- Val RMSE: Decreases, then plateaus or increases (overfitting)
- Best iteration: Where val RMSE is lowest

## Common Mistakes

| Mistake | Why It's Wrong | Correct Approach |
|---------|----------------|------------------|
| **No eval_set provided** | Early stopping has nothing to monitor | Always provide `eval_set` or `evals` |
| **eval_set = train set** | Can't detect overfitting | Use held-out validation set |
| **early_stopping_rounds too small** | Stops too early (underfitting) | Increase to 30-50 or more for low LR |
| **early_stopping_rounds too large** | Wastes computation time | Lower to 20-30 if using high LR |
| **Not using best_iteration** | Manual prediction uses last iteration | Let XGBoost handle it automatically |
| **Multiple metrics, wrong order** | Stops based on wrong metric | Put primary metric last in `eval_metric` list |

## Early Stopping Without Validation Set

If you don't have a separate validation set, use cross-validation:

```python
# Cross-validation with early stopping
cv_results = xgb.cv(
    params,
    dtrain,
    num_boost_round=1000,
    nfold=5,
    early_stopping_rounds=50,
    metrics='rmse',
    seed=42,
    verbose_eval=50,
)

print(f"Best iteration: {len(cv_results)}")
print(f"Best CV RMSE: {cv_results['test-rmse-mean'].min():.2f}")

# Now retrain on full data with optimal num_boost_round
optimal_rounds = len(cv_results)
final_model = xgb.train(
    params,
    dtrain,
    num_boost_round=optimal_rounds,
)
```

## Configuration Table

| API | Parameter | Type | Default | Purpose |
|-----|-----------|------|---------|---------|
| Native | `early_stopping_rounds` | int | None | Patience (rounds without improvement) |
| Native | `evals` | list | None | List of (DMatrix, name) tuples to monitor |
| Native | `verbose_eval` | int/bool | True | Print frequency (False=silent, True=every round, int=every N rounds) |
| sklearn | `early_stopping_rounds` | int | None | Patience |
| sklearn | `eval_set` | list | None | List of (X, y) tuples to monitor |
| sklearn | `verbose` | int/bool | True | Print frequency |

## Related Patterns

- [training-pipeline.md](training-pipeline.md) — Integrate early stopping in production
- [cross-validation.md](cross-validation.md) — Find optimal num_boost_round without validation set
- [hyperparameter-tuning.md](hyperparameter-tuning.md) — Combine with hyperparameter search

## References

- XGBoost Callbacks: https://xgboost.readthedocs.io/en/stable/python/callbacks.html
- Early Stopping Guide: https://xgboost.readthedocs.io/en/stable/python/python_intro.html#early-stopping
