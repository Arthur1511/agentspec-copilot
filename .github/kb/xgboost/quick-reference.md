# XGBoost Quick Reference

> **MCP Validated:** 2026-04-17

Fast lookup tables for XGBoost parameters, objectives, metrics, and common patterns.

---

## Core Parameters

| Parameter | Type | Default | Range | Purpose |
|-----------|------|---------|-------|---------|
| `n_estimators` | int | 100 | [1, ∞) | Number of boosting rounds |
| `max_depth` | int | 6 | [0, ∞) | Maximum tree depth (0 = unlimited with max_leaves) |
| `learning_rate` | float | 0.3 | (0, 1] | Step size shrinkage (aka `eta`) |
| `subsample` | float | 1.0 | (0, 1] | Fraction of samples per tree |
| `colsample_bytree` | float | 1.0 | (0, 1] | Fraction of features per tree |
| `min_child_weight` | float | 1 | [0, ∞) | Min sum of instance weights in child |
| `gamma` | float | 0 | [0, ∞) | Min loss reduction for split |
| `lambda` | float | 1 | [0, ∞) | L2 regularization (aka `reg_lambda`) |
| `alpha` | float | 0 | [0, ∞) | L1 regularization (aka `reg_alpha`) |
| `tree_method` | str | auto | see below | Tree construction algorithm |

### tree_method Options

| Value | Use Case | Performance |
|-------|----------|-------------|
| `auto` | Default heuristic | Varies |
| `exact` | Small datasets (<10k rows) | Slow, accurate |
| `approx` | Medium datasets | Moderate |
| `hist` | Large datasets, CPU/GPU | **Fast, recommended** |

**Note:** `gpu_hist` is deprecated. Use `tree_method='hist'` with `device='cuda'` for GPU acceleration.

---

## Objective Functions

| Objective | Task | Output |
|-----------|------|--------|
| `binary:logistic` | Binary classification | Probability [0, 1] |
| `binary:hinge` | Binary classification | Decision boundary |
| `multi:softmax` | Multiclass classification | Class label |
| `multi:softprob` | Multiclass classification | Class probabilities |
| `reg:squarederror` | Regression | Continuous value |
| `reg:squaredlogerror` | Regression (log scale) | Continuous value |
| `reg:absoluteerror` | Regression (robust to outliers) | Continuous value |
| `rank:pairwise` | Learning-to-rank | Ranking score |
| `rank:ndcg` | Learning-to-rank | NDCG-optimized score |

---

## Evaluation Metrics

| Metric | Task | Formula | Best Value |
|--------|------|---------|------------|
| `logloss` | Binary/multiclass | Log loss | Lower |
| `auc` | Binary classification | Area under ROC curve | Higher (max 1.0) |
| `aucpr` | Binary classification | Area under PR curve | Higher |
| `error` | Binary classification | Misclassification rate | Lower |
| `merror` | Multiclass | Multiclass error rate | Lower |
| `mlogloss` | Multiclass | Multiclass log loss | Lower |
| `rmse` | Regression | Root mean squared error | Lower |
| `mae` | Regression | Mean absolute error | Lower |
| `rmsle` | Regression | Root mean squared log error | Lower |
| `ndcg` | Ranking | Normalized DCG | Higher |
| `map` | Ranking | Mean average precision | Higher |

---

## Decision Matrix

| Task | Objective | Metric | Typical Params |
|------|-----------|--------|----------------|
| **Binary Classification** | `binary:logistic` | `auc` | `max_depth=6, eta=0.1, subsample=0.8` |
| **Multiclass Classification** | `multi:softmax` | `merror` | `max_depth=6, eta=0.1, subsample=0.8` |
| **Regression** | `reg:squarederror` | `rmse` | `max_depth=5, eta=0.05, subsample=0.9` |
| **Ranking** | `rank:pairwise` | `ndcg` | `max_depth=8, eta=0.05, subsample=0.7` |

---

## Common Pitfalls

| Mistake | Symptom | Solution |
|---------|---------|----------|
| No early stopping | Overfitting on training data | Add `early_stopping_rounds` with `eval_set` |
| `learning_rate` too high | Poor generalization, unstable | Lower to 0.01-0.1; increase `n_estimators` |
| Not scaling features | Unnecessary (XGBoost is scale-invariant) | No action needed |
| Not using `eval_set` | Can't detect overfitting | Provide validation set in `fit()` |
| Using `tree_method='exact'` on large data | Slow training | Switch to `tree_method='hist'` |
| Setting `gamma` too high | No tree splits at all | Start with 0, tune carefully |
| Using `weight` importance | Ignores actual gain | Use `gain` or `total_gain` instead |

---

## sklearn API vs Native API

| Feature | sklearn API | Native API |
|---------|-------------|------------|
| **Import** | `from xgboost import XGBClassifier` | `import xgboost as xgb` |
| **Data Format** | NumPy, pandas | `xgb.DMatrix` |
| **Training** | `model.fit(X, y)` | `xgb.train(params, dtrain)` |
| **Prediction** | `model.predict(X)` | `model.predict(dtest)` |
| **Early Stopping** | `fit(..., early_stopping_rounds=50)` | `xgb.train(..., early_stopping_rounds=50)` |
| **Cross-Validation** | `cross_val_score(model, X, y)` | `xgb.cv(params, dtrain)` |
| **Use Case** | sklearn pipelines, simple workflows | Production, advanced control |

---

## Training Checklist

```python
# ✓ 1. Prepare data
X_train, X_val, X_test, y_train, y_val, y_test = prepare_data()

# ✓ 2. Define parameters
params = {
    'objective': 'binary:logistic',
    'eval_metric': 'auc',
    'max_depth': 6,
    'learning_rate': 0.1,
    'tree_method': 'hist',
}

# ✓ 3. Convert to DMatrix (optional but faster)
dtrain = xgb.DMatrix(X_train, label=y_train)
dval = xgb.DMatrix(X_val, label=y_val)

# ✓ 4. Train with early stopping
model = xgb.train(
    params,
    dtrain,
    num_boost_round=1000,
    evals=[(dtrain, 'train'), (dval, 'val')],
    early_stopping_rounds=50,
    verbose_eval=100
)

# ✓ 5. Evaluate
y_pred = model.predict(xgb.DMatrix(X_test))

# ✓ 6. Save model
model.save_model('model.ubj')
```

---

## Related

- [training-pipeline.md](patterns/training-pipeline.md) — Complete production pipeline
- [hyperparameter-tuning.md](patterns/hyperparameter-tuning.md) — Optuna-based search
- [xgboost-params.yaml](specs/xgboost-params.yaml) — Full parameter specification
