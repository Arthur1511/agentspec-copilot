# Hyperparameter Tuning

> **MCP Validated:** 2026-04-17

## Overview

Automated hyperparameter optimization for XGBoost using **Optuna**, a modern Bayesian optimization framework. Optuna is preferred over GridSearchCV for XGBoost due to better handling of early stopping and more efficient search strategies.

## Optuna-Based Tuning

### Complete Example

```python
import xgboost as xgb
from sklearn.datasets import load_breast_cancer
from sklearn.model_selection import train_test_split, cross_val_score
import optuna
from optuna.integration import XGBoostPruningCallback

# ═══════════════════════════════════════════════════════════════════
# DATA PREPARATION
# ═══════════════════════════════════════════════════════════════════

X, y = load_breast_cancer(return_X_y=True)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
X_train, X_val, y_train, y_val = train_test_split(X_train, y_train, test_size=0.2, random_state=42)

dtrain = xgb.DMatrix(X_train, label=y_train)
dval = xgb.DMatrix(X_val, label=y_val)

# ═══════════════════════════════════════════════════════════════════
# OBJECTIVE FUNCTION
# ═══════════════════════════════════════════════════════════════════

def objective(trial):
    """Optuna objective function for XGBoost hyperparameter tuning."""
    
    # Suggest hyperparameters
    params = {
        'objective': 'binary:logistic',
        'eval_metric': 'auc',
        'tree_method': 'hist',
        
        # Tree structure
        'max_depth': trial.suggest_int('max_depth', 3, 10),
        'min_child_weight': trial.suggest_int('min_child_weight', 1, 10),
        'gamma': trial.suggest_float('gamma', 0, 5),
        
        # Learning
        'learning_rate': trial.suggest_float('learning_rate', 1e-3, 1.0, log=True),
        'subsample': trial.suggest_float('subsample', 0.5, 1.0),
        'colsample_bytree': trial.suggest_float('colsample_bytree', 0.5, 1.0),
        
        # Regularization
        'lambda': trial.suggest_float('lambda', 1e-8, 10.0, log=True),
        'alpha': trial.suggest_float('alpha', 1e-8, 10.0, log=True),
        
        # Reproducibility
        'seed': 42,
    }
    
    # Pruning callback (stops unpromising trials early)
    pruning_callback = XGBoostPruningCallback(trial, 'val-auc')
    
    # Train with cross-validation
    cv_results = xgb.cv(
        params,
        dtrain,
        num_boost_round=1000,
        nfold=5,
        stratified=True,
        early_stopping_rounds=50,
        callbacks=[pruning_callback],
        seed=42,
        verbose_eval=False,
    )
    
    # Return best validation score
    return cv_results['test-auc-mean'].max()

# ═══════════════════════════════════════════════════════════════════
# RUN OPTIMIZATION
# ═══════════════════════════════════════════════════════════════════

# Create study
study = optuna.create_study(
    direction='maximize',           # Maximize AUC
    pruner=optuna.pruners.MedianPruner(n_warmup_steps=5),
    sampler=optuna.samplers.TPESampler(seed=42),
)

# Optimize
study.optimize(objective, n_trials=100, timeout=3600)  # 100 trials or 1 hour

# ═══════════════════════════════════════════════════════════════════
# RESULTS
# ═══════════════════════════════════════════════════════════════════

print("Best trial:")
trial = study.best_trial

print(f"  Value (AUC): {trial.value:.4f}")
print("\n  Best hyperparameters:")
for key, value in trial.params.items():
    print(f"    {key:20s}: {value}")

# ═══════════════════════════════════════════════════════════════════
# RETRAIN WITH BEST PARAMS
# ═══════════════════════════════════════════════════════════════════

best_params = trial.params
best_params.update({
    'objective': 'binary:logistic',
    'eval_metric': 'auc',
    'tree_method': 'hist',
    'seed': 42,
})

# Train final model
final_model = xgb.train(
    best_params,
    dtrain,
    num_boost_round=1000,
    evals=[(dtrain, 'train'), (dval, 'val')],
    early_stopping_rounds=50,
    verbose_eval=False,
)

# Evaluate
y_pred = final_model.predict(xgb.DMatrix(X_test))
from sklearn.metrics import roc_auc_score
test_auc = roc_auc_score(y_test, y_pred)
print(f"\nFinal test AUC: {test_auc:.4f}")

# Save best model
final_model.save_model("best_model.ubj")
```

## Search Space Recommendations

| Parameter | Type | Recommended Range | Strategy |
|-----------|------|-------------------|----------|
| `max_depth` | int | [3, 10] | Linear search |
| `learning_rate` | float | [1e-3, 1.0] | **Log scale** |
| `subsample` | float | [0.5, 1.0] | Linear search |
| `colsample_bytree` | float | [0.5, 1.0] | Linear search |
| `min_child_weight` | int | [1, 10] | Linear search |
| `gamma` | float | [0, 5] | Linear search |
| `lambda` | float | [1e-8, 10.0] | **Log scale** |
| `alpha` | float | [1e-8, 10.0] | **Log scale** |

**Why log scale?** Parameters like `learning_rate`, `lambda`, `alpha` span multiple orders of magnitude. Log scale ensures efficient sampling across the full range.

## Visualization

```python
import optuna.visualization as vis

# Optimization history
fig = vis.plot_optimization_history(study)
fig.show()

# Parameter importances
fig = vis.plot_param_importances(study)
fig.show()

# Parallel coordinate plot
fig = vis.plot_parallel_coordinate(study, params=['max_depth', 'learning_rate', 'lambda'])
fig.show()

# Contour plot (2D parameter relationships)
fig = vis.plot_contour(study, params=['max_depth', 'learning_rate'])
fig.show()
```

## Alternative: scikit-optimize (Bayesian Optimization)

```python
from skopt import BayesSearchCV
from skopt.space import Real, Integer

# Define search space
search_spaces = {
    'max_depth': Integer(3, 10),
    'learning_rate': Real(1e-3, 1.0, prior='log-uniform'),
    'subsample': Real(0.5, 1.0),
    'colsample_bytree': Real(0.5, 1.0),
    'min_child_weight': Integer(1, 10),
    'gamma': Real(0, 5),
    'reg_lambda': Real(1e-8, 10.0, prior='log-uniform'),
    'reg_alpha': Real(1e-8, 10.0, prior='log-uniform'),
}

# Create model
model = xgb.XGBClassifier(
    objective='binary:logistic',
    eval_metric='auc',
    tree_method='hist',
    n_estimators=1000,
    random_state=42,
)

# Bayesian search
opt = BayesSearchCV(
    model,
    search_spaces,
    n_iter=50,
    cv=5,
    n_jobs=-1,
    random_state=42,
)

# Fit
opt.fit(X_train, y_train)

print("Best parameters:", opt.best_params_)
print("Best CV score:", opt.best_score_)

# Use best model
best_model = opt.best_estimator_
```

## Grid Search (Not Recommended for XGBoost)

GridSearchCV is exhaustive and slow for XGBoost. Use only for coarse initial search.

```python
from sklearn.model_selection import GridSearchCV

param_grid = {
    'max_depth': [3, 6, 9],
    'learning_rate': [0.01, 0.1, 0.3],
    'subsample': [0.7, 0.9],
}

model = xgb.XGBClassifier(
    objective='binary:logistic',
    tree_method='hist',
    n_estimators=100,
)

grid = GridSearchCV(
    model,
    param_grid,
    cv=3,
    scoring='roc_auc',
    n_jobs=-1,
)

grid.fit(X_train, y_train)

print("Best params:", grid.best_params_)
```

**Why not GridSearch?**
- Exhaustive: tests all combinations (exponentially slow)
- No early stopping integration
- No pruning of unpromising trials
- Doesn't learn from previous trials

## Tuning Strategy

### 1. Coarse Search (Quick)

```python
# Fix some params, tune others
def quick_objective(trial):
    params = {
        'objective': 'binary:logistic',
        'eval_metric': 'auc',
        'tree_method': 'hist',
        
        # Tune these first
        'max_depth': trial.suggest_int('max_depth', 3, 8),
        'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.3, log=True),
        
        # Fixed for now
        'subsample': 0.8,
        'colsample_bytree': 0.8,
        'lambda': 1.0,
        'alpha': 0.0,
        'gamma': 0,
    }
    
    # ... rest of objective
```

### 2. Fine-Grained Search (After coarse)

```python
# Fix best values from coarse search, tune regularization
def fine_objective(trial):
    params = {
        'objective': 'binary:logistic',
        'eval_metric': 'auc',
        'tree_method': 'hist',
        
        # Fixed from coarse search
        'max_depth': 6,
        'learning_rate': 0.1,
        
        # Now tune these
        'subsample': trial.suggest_float('subsample', 0.6, 1.0),
        'colsample_bytree': trial.suggest_float('colsample_bytree', 0.6, 1.0),
        'lambda': trial.suggest_float('lambda', 0.1, 10.0, log=True),
        'alpha': trial.suggest_float('alpha', 1e-5, 1.0, log=True),
        'gamma': trial.suggest_float('gamma', 0, 2),
    }
    
    # ... rest of objective
```

## Configuration Table

| Stage | Parameters Tuned | Trials | Expected Time |
|-------|------------------|--------|---------------|
| **Coarse** | max_depth, learning_rate | 20-30 | 10-20 min |
| **Medium** | + subsample, colsample_bytree | 30-50 | 20-40 min |
| **Fine** | + lambda, alpha, gamma, min_child_weight | 50-100 | 40-90 min |

## Common Mistakes

| Mistake | Why It's Wrong | Correct Approach |
|---------|----------------|------------------|
| **Using GridSearchCV** | Exponentially slow, no learning | Use Optuna or BayesSearchCV |
| **Not using log scale for learning_rate** | Most search in narrow range | `suggest_float(..., log=True)` |
| **Tuning all params at once** | High-dimensional search is inefficient | Coarse → medium → fine approach |
| **Too few trials** | May not find good region | At least 30-50 trials for coarse search |
| **Not using pruning** | Wastes time on bad trials | Enable `XGBoostPruningCallback` |

## Related Patterns

- [training-pipeline.md](training-pipeline.md) — Use best params in production pipeline
- [cross-validation.md](cross-validation.md) — Robust evaluation during tuning
- [early-stopping.md](early-stopping.md) — Integrate with tuning for efficiency

## References

- Optuna Documentation: https://optuna.readthedocs.io/
- XGBoost Parameters: https://xgboost.readthedocs.io/en/stable/parameter.html
- Scikit-Optimize: https://scikit-optimize.github.io/
