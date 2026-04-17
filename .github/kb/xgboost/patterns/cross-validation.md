# Cross-Validation

> **MCP Validated:** 2026-04-17

## Overview

**Cross-validation** provides robust model evaluation by training on multiple data splits. XGBoost provides native `xgb.cv()` for efficient cross-validation with early stopping, and integrates with sklearn's cross-validation tools.

## Native Cross-Validation (xgb.cv)

### Basic Usage

```python
import xgboost as xgb
from sklearn.datasets import load_diabetes
import numpy as np

# Load data
X, y = load_diabetes(return_X_y=True)
dtrain = xgb.DMatrix(X, label=y)

# Parameters
params = {
    'objective': 'reg:squarederror',
    'eval_metric': 'rmse',
    'max_depth': 5,
    'learning_rate': 0.1,
    'subsample': 0.8,
    'colsample_bytree': 0.8,
    'tree_method': 'hist',
}

# Cross-validation
cv_results = xgb.cv(
    params,
    dtrain,
    num_boost_round=1000,        # Max rounds
    nfold=5,                      # 5-fold CV
    metrics='rmse',               # Evaluation metric
    early_stopping_rounds=50,     # Stop if no improvement
    seed=42,                      # Reproducibility
    verbose_eval=100,             # Print every 100 rounds
)

print("\nCross-Validation Results:")
print(cv_results.tail())

# Best iteration
best_iteration = cv_results['test-rmse-mean'].idxmin()
best_rmse = cv_results['test-rmse-mean'].min()

print(f"\nBest iteration: {best_iteration}")
print(f"Best CV RMSE: {best_rmse:.2f} (± {cv_results.loc[best_iteration, 'test-rmse-std']:.2f})")
```

**Output**:
```
   train-rmse-mean  train-rmse-std  test-rmse-mean  test-rmse-std
0        67.234       0.123           68.456          1.234
1        65.123       0.112           67.234          1.156
...
146      52.345       0.089           56.789          1.023

Best iteration: 146
Best CV RMSE: 56.79 (± 1.02)
```

### Using CV Results for Final Training

```python
# 1. Find optimal num_boost_round via CV
cv_results = xgb.cv(
    params, dtrain,
    num_boost_round=1000,
    nfold=5,
    early_stopping_rounds=50,
    seed=42,
)

optimal_rounds = len(cv_results)  # Number of rows = optimal iterations
print(f"Optimal boosting rounds: {optimal_rounds}")

# 2. Retrain on full dataset with optimal rounds
final_model = xgb.train(
    params,
    dtrain,
    num_boost_round=optimal_rounds,
)

# 3. Predict
y_pred = final_model.predict(dtrain)
print(f"Final model RMSE: {np.sqrt(np.mean((y - y_pred)**2)):.2f}")
```

**Workflow**: CV → find optimal rounds → retrain on all data → production model.

## Stratified Cross-Validation

For classification, ensure class distribution is maintained in each fold:

```python
from sklearn.datasets import load_breast_cancer

X, y = load_breast_cancer(return_X_y=True)
dtrain = xgb.DMatrix(X, label=y)

params = {
    'objective': 'binary:logistic',
    'eval_metric': 'auc',
    'max_depth': 6,
    'learning_rate': 0.1,
}

# Stratified CV (default for classification)
cv_results = xgb.cv(
    params, dtrain,
    num_boost_round=500,
    nfold=5,
    stratified=True,          # Maintain class distribution
    metrics='auc',
    early_stopping_rounds=50,
    seed=42,
)

print(f"Best CV AUC: {cv_results['test-auc-mean'].max():.4f}")
```

## sklearn Integration (cross_val_score)

### Basic Cross-Validation

```python
from xgboost import XGBClassifier
from sklearn.model_selection import cross_val_score
from sklearn.datasets import load_breast_cancer

X, y = load_breast_cancer(return_X_y=True)

model = XGBClassifier(
    n_estimators=100,
    max_depth=6,
    learning_rate=0.1,
    tree_method='hist',
    random_state=42,
)

# 5-fold cross-validation
scores = cross_val_score(
    model, X, y,
    cv=5,
    scoring='roc_auc',
    n_jobs=-1,              # Parallel
)

print(f"CV AUC scores: {scores}")
print(f"Mean AUC: {scores.mean():.4f} (± {scores.std():.4f})")
```

### Stratified K-Fold

```python
from sklearn.model_selection import StratifiedKFold

# Custom stratified split
skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)

scores = cross_val_score(
    model, X, y,
    cv=skf,
    scoring='roc_auc',
)

print(f"Stratified CV AUC: {scores.mean():.4f}")
```

## Time Series Cross-Validation

For time-series data, use **TimeSeriesSplit** to maintain temporal order:

```python
from sklearn.model_selection import TimeSeriesSplit
import pandas as pd

# Time series data (example)
dates = pd.date_range('2020-01-01', periods=1000, freq='D')
X_timeseries = np.random.randn(1000, 10)
y_timeseries = np.random.randn(1000)

# Time series split
tscv = TimeSeriesSplit(n_splits=5)

model = XGBRegressor(
    n_estimators=100,
    max_depth=5,
    learning_rate=0.1,
)

scores = cross_val_score(
    model, X_timeseries, y_timeseries,
    cv=tscv,
    scoring='neg_mean_squared_error',
)

rmse_scores = np.sqrt(-scores)
print(f"Time Series CV RMSE: {rmse_scores.mean():.2f} (± {rmse_scores.std():.2f})")
```

**TimeSeriesSplit behavior**:
```
Split 1: Train [0:200], Test [200:400]
Split 2: Train [0:400], Test [400:600]
Split 3: Train [0:600], Test [600:800]
Split 4: Train [0:800], Test [800:1000]
```

**Important**: Each test set is future data relative to training set (no data leakage).

## Cross-Validation with Pipelines

```python
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

pipeline = Pipeline([
    ('scaler', StandardScaler()),
    ('model', XGBClassifier(
        n_estimators=100,
        max_depth=6,
        learning_rate=0.1,
        random_state=42,
    ))
])

# CV on entire pipeline
scores = cross_val_score(
    pipeline, X, y,
    cv=5,
    scoring='accuracy',
)

print(f"Pipeline CV Accuracy: {scores.mean():.4f}")
```

## Custom Scoring Metrics

```python
from sklearn.metrics import make_scorer, f1_score

# Custom F1 score
f1_scorer = make_scorer(f1_score, pos_label=1)

scores = cross_val_score(
    model, X, y,
    cv=5,
    scoring=f1_scorer,
)

print(f"CV F1 Score: {scores.mean():.4f}")
```

## Nested Cross-Validation (Hyperparameter Tuning + Evaluation)

```python
from sklearn.model_selection import GridSearchCV

# Outer CV: model evaluation
outer_cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)

# Inner CV: hyperparameter tuning
inner_cv = StratifiedKFold(n_splits=3, shuffle=True, random_state=42)

# Parameter grid
param_grid = {
    'max_depth': [3, 6, 9],
    'learning_rate': [0.01, 0.1, 0.3],
}

model = XGBClassifier(n_estimators=100, random_state=42)

# Nested CV
nested_scores = []

for train_idx, test_idx in outer_cv.split(X, y):
    X_train, X_test = X[train_idx], X[test_idx]
    y_train, y_test = y[train_idx], y[test_idx]
    
    # Inner CV: tune hyperparameters
    grid = GridSearchCV(model, param_grid, cv=inner_cv, scoring='roc_auc')
    grid.fit(X_train, y_train)
    
    # Evaluate best model on outer test set
    best_model = grid.best_estimator_
    score = best_model.score(X_test, y_test)
    nested_scores.append(score)

print(f"Nested CV Score: {np.mean(nested_scores):.4f} (± {np.std(nested_scores):.4f})")
```

## Comparing xgb.cv vs sklearn cross_val_score

| Feature | `xgb.cv()` | `cross_val_score()` |
|---------|-----------|---------------------|
| **API** | Native XGBoost | sklearn-compatible |
| **Data format** | DMatrix | NumPy/pandas |
| **Early stopping** | ✓ Built-in | ✗ Not automatic |
| **Speed** | ✓ Faster (native) | Slower (wrapping) |
| **Returns** | DataFrame with history | Array of scores |
| **Custom metrics** | Via XGBoost metrics | Via sklearn scorers |
| **Stratification** | `stratified=True` | Via `StratifiedKFold` |
| **Use case** | Finding optimal rounds | Pipeline evaluation, custom splits |

## Configuration Table

| Parameter | Type | Default | Purpose |
|-----------|------|---------|---------|
| `nfold` | int | 3 | Number of CV folds |
| `stratified` | bool | False | Stratify splits (classification) |
| `metrics` | str/list | None | Evaluation metric(s) |
| `early_stopping_rounds` | int | None | Stop if no improvement |
| `seed` | int | 0 | Reproducibility |
| `shuffle` | bool | True | Shuffle data before splitting |
| `verbose_eval` | int/bool | True | Print frequency |

## Common Mistakes

| Mistake | Why It's Wrong | Correct Approach |
|---------|----------------|------------------|
| **Not using stratified CV for classification** | Unbalanced folds | Set `stratified=True` in `xgb.cv()` |
| **Using random CV for time series** | Data leakage (future in training) | Use `TimeSeriesSplit` |
| **Tuning hyperparameters on CV results** | Overfitting to CV | Use nested CV or separate validation |
| **Ignoring CV std** | Overconfident in single mean | Always report mean ± std |
| **Not setting seed** | Non-reproducible results | Always set `seed` parameter |

## Visualization: CV Results

```python
import matplotlib.pyplot as plt

# Run CV
cv_results = xgb.cv(
    params, dtrain,
    num_boost_round=500,
    nfold=5,
    metrics=['rmse', 'mae'],
    seed=42,
)

# Plot train/test curves
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# RMSE
axes[0].plot(cv_results['train-rmse-mean'], label='Train')
axes[0].fill_between(
    range(len(cv_results)),
    cv_results['train-rmse-mean'] - cv_results['train-rmse-std'],
    cv_results['train-rmse-mean'] + cv_results['train-rmse-std'],
    alpha=0.3
)
axes[0].plot(cv_results['test-rmse-mean'], label='Test')
axes[0].fill_between(
    range(len(cv_results)),
    cv_results['test-rmse-mean'] - cv_results['test-rmse-std'],
    cv_results['test-rmse-mean'] + cv_results['test-rmse-std'],
    alpha=0.3
)
axes[0].set_xlabel('Boosting Round')
axes[0].set_ylabel('RMSE')
axes[0].set_title('Cross-Validation RMSE')
axes[0].legend()
axes[0].grid(True)

# MAE
axes[1].plot(cv_results['train-mae-mean'], label='Train')
axes[1].plot(cv_results['test-mae-mean'], label='Test')
axes[1].set_xlabel('Boosting Round')
axes[1].set_ylabel('MAE')
axes[1].set_title('Cross-Validation MAE')
axes[1].legend()
axes[1].grid(True)

plt.tight_layout()
plt.show()
```

## Related Patterns

- [training-pipeline.md](training-pipeline.md) — Use CV to find optimal rounds
- [hyperparameter-tuning.md](hyperparameter-tuning.md) — Combine CV with parameter search
- [early-stopping.md](early-stopping.md) — Integrate early stopping in CV

## References

- XGBoost CV: https://xgboost.readthedocs.io/en/stable/python/python_api.html#xgboost.cv
- sklearn CV: https://scikit-learn.org/stable/modules/cross_validation.html
