# Cross-Validation

> KFold, StratifiedKFold, cross_val_score, cross_validate, and nested CV patterns.

---

## Why Cross-Validation?

A single train/test split is high-variance. Cross-validation gives a more reliable estimate of generalization performance by averaging over multiple splits.

---

## Splitter Reference

| Splitter | When to Use |
|----------|-------------|
| `KFold(n_splits=5)` | Regression, balanced classification |
| `StratifiedKFold(n_splits=5)` | Classification — preserves class ratio in each fold |
| `TimeSeriesSplit(n_splits=5)` | Time-ordered data — no future leakage |
| `GroupKFold(n_splits=5)` | Samples belong to groups (e.g., patients) — no group appears in both train and test |
| `RepeatedStratifiedKFold` | Average over multiple random seeds |

```python
from sklearn.model_selection import StratifiedKFold
cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
```

---

## cross_val_score

```python
from sklearn.model_selection import cross_val_score

scores = cross_val_score(
    estimator=pipe,
    X=X,
    y=y,
    cv=StratifiedKFold(5, shuffle=True, random_state=42),
    scoring="roc_auc",
    n_jobs=-1,
)
print(f"ROC-AUC: {scores.mean():.4f} ± {scores.std():.4f}")
```

---

## cross_validate — Multiple Metrics

```python
from sklearn.model_selection import cross_validate

results = cross_validate(
    pipe, X, y,
    cv=5,
    scoring=["roc_auc", "f1_weighted", "accuracy"],
    return_train_score=True,
    n_jobs=-1,
)
# Keys: test_roc_auc, train_roc_auc, test_f1_weighted, fit_time, score_time
```

---

## Nested Cross-Validation

Use when tuning hyperparameters AND estimating generalization — prevents optimistic bias from leaking search results.

```python
from sklearn.model_selection import GridSearchCV, cross_val_score

inner_cv = StratifiedKFold(n_splits=3, shuffle=True, random_state=0)
outer_cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=0)

search = GridSearchCV(pipe, param_grid, cv=inner_cv, scoring="roc_auc")
nested_scores = cross_val_score(search, X, y, cv=outer_cv, scoring="roc_auc")

print(f"Nested CV ROC-AUC: {nested_scores.mean():.4f}")
```

---

## Scoring Strings Reference

| Task | Scoring String |
|------|---------------|
| Binary classification | `"roc_auc"`, `"f1"`, `"accuracy"`, `"average_precision"` |
| Multiclass | `"f1_weighted"`, `"f1_macro"`, `"accuracy"` |
| Regression | `"neg_mean_squared_error"`, `"neg_mean_absolute_error"`, `"r2"` |

**Note:** Regression metrics return **negative** values in sklearn (higher = better convention). Negate to get RMSE:

```python
neg_mse = cross_val_score(pipe, X, y, scoring="neg_mean_squared_error")
rmse = np.sqrt(-neg_mse)
```

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| Tune then CV on same data | Optimistic bias | Use nested CV |
| `KFold` for imbalanced classification | Wrong class ratios in folds | `StratifiedKFold` |
| `KFold` for time-series | Future leakage | `TimeSeriesSplit` |
| `n_jobs=1` on large search | Slow | `n_jobs=-1` (all cores) |
