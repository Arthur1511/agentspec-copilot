# Estimator API

> The fit/transform/predict contract, parameter conventions, and the BaseEstimator interface.

---

## The Three-Method Contract

Every scikit-learn estimator follows the same interface:

| Method | Who has it | Purpose |
|--------|-----------|---------|
| `fit(X, y)` | All estimators | Learn parameters from training data |
| `predict(X)` | Supervised | Return labels or values |
| `predict_proba(X)` | Probabilistic classifiers | Return class probabilities |
| `transform(X)` | Transformers | Return transformed features |
| `fit_transform(X)` | Transformers | `fit` + `transform` in one pass |
| `score(X, y)` | All | Default metric (accuracy / R²) |

---

## Estimator Conventions

1. **No data in `__init__`** — only hyperparameters
2. **All hyperparameters set via `__init__`** — no hidden state
3. **Learned attributes end with `_`** — e.g., `model.coef_`, `scaler.mean_`
4. **Input validation in `fit`** — call `check_is_fitted` in `predict`
5. **`set_params(**params)` / `get_params()`** — used by search and pipelines

```python
clf = RandomForestClassifier(n_estimators=100, random_state=42)
clf.fit(X_train, y_train)

# Learned attributes
clf.feature_importances_
clf.n_features_in_
clf.classes_
```

---

## Transformer vs Estimator

```python
from sklearn.preprocessing import StandardScaler

scaler = StandardScaler()
scaler.fit(X_train)           # Computes mean_ and scale_
X_train_sc = scaler.transform(X_train)
X_test_sc  = scaler.transform(X_test)  # Uses training statistics

# Shortcut (only on training data)
X_train_sc = scaler.fit_transform(X_train)
```

**Never `fit_transform` on test data** — it leaks statistics.

---

## clone()

Creates a new, unfitted estimator with the same hyperparameters.

```python
from sklearn.base import clone

fresh = clone(fitted_model)  # No learned attributes
```

Used internally by cross-validation to avoid state contamination.

---

## Custom Estimator Skeleton

```python
from sklearn.base import BaseEstimator, TransformerMixin

class LogTransformer(BaseEstimator, TransformerMixin):
    def __init__(self, shift: float = 1.0):
        self.shift = shift  # hyperparameter — no processing here

    def fit(self, X, y=None):
        return self           # Stateless transformer

    def transform(self, X):
        return np.log1p(X + self.shift - 1)
```

- Inherit `BaseEstimator` for `get_params` / `set_params`
- Inherit `TransformerMixin` for `fit_transform`
- Inherit `ClassifierMixin` or `RegressorMixin` for appropriate `score`

---

## Parameter Naming Conventions

| Convention | Example |
|-----------|---------|
| Hyperparameter | `n_estimators`, `max_depth`, `C` |
| Learned attribute | `coef_`, `feature_importances_`, `n_features_in_` |
| Pipeline step param | `clf__C`, `preprocessor__num__scaler__with_mean` |

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| `fit` on test data | Data leakage | Only `transform` on test set |
| Store data in `__init__` | Violates API | Only hyperparameters in `__init__` |
| Mutate input `X` | Unexpected side effects | Use `X.copy()` inside `transform` |
| Skip `check_is_fitted` | Cryptic errors on un-fitted model | Call in `predict`/`transform` |
