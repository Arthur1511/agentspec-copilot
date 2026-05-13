# Model Selection

> GridSearchCV, RandomizedSearchCV, Optuna integration, and model comparison patterns.

---

## GridSearchCV

Exhaustive search over a parameter grid. Best for small grids (< 50 combinations).

```python
from sklearn.model_selection import GridSearchCV
from sklearn.pipeline import Pipeline
from sklearn.svm import SVC
from sklearn.preprocessing import StandardScaler

pipe = Pipeline([("scaler", StandardScaler()), ("clf", SVC())])

param_grid = {
    "clf__C":      [0.1, 1, 10, 100],
    "clf__kernel": ["rbf", "linear"],
    "clf__gamma":  ["scale", "auto"],
}

search = GridSearchCV(
    pipe, param_grid,
    cv=5,
    scoring="roc_auc",
    n_jobs=-1,
    verbose=1,
    refit=True,    # Refit best estimator on full training data
)
search.fit(X_train, y_train)

print(search.best_params_)
print(f"Best CV score: {search.best_score_:.4f}")
print(f"Test score:    {search.score(X_test, y_test):.4f}")
```

---

## RandomizedSearchCV

Sample random combinations. Best for large search spaces.

```python
from sklearn.model_selection import RandomizedSearchCV
from scipy.stats import randint, uniform

param_dist = {
    "clf__n_estimators":     randint(100, 500),
    "clf__max_depth":        [None, 5, 10, 20],
    "clf__min_samples_leaf": randint(1, 10),
    "clf__max_features":     uniform(0.3, 0.7),
}

search = RandomizedSearchCV(
    pipe, param_dist,
    n_iter=50,        # Try 50 random combinations
    cv=5,
    scoring="roc_auc",
    n_jobs=-1,
    random_state=42,
)
search.fit(X_train, y_train)
```

---

## Optuna Integration (Recommended for Complex Spaces)

```python
import optuna
from sklearn.model_selection import cross_val_score

def objective(trial):
    n_estimators = trial.suggest_int("n_estimators", 50, 500)
    max_depth    = trial.suggest_int("max_depth", 2, 20)
    min_samples  = trial.suggest_int("min_samples_leaf", 1, 10)

    clf = RandomForestClassifier(
        n_estimators=n_estimators,
        max_depth=max_depth,
        min_samples_leaf=min_samples,
        random_state=42,
    )
    pipe = Pipeline([("prep", preprocessor), ("clf", clf)])
    scores = cross_val_score(pipe, X_train, y_train, cv=5, scoring="roc_auc")
    return scores.mean()

study = optuna.create_study(direction="maximize")
study.optimize(objective, n_trials=100, n_jobs=-1)

print(study.best_params)
print(f"Best score: {study.best_value:.4f}")
```

---

## Comparing Multiple Models

```python
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.model_selection import cross_val_score
import pandas as pd

models = {
    "LogisticRegression": LogisticRegression(max_iter=1000),
    "RandomForest":       RandomForestClassifier(n_estimators=100, random_state=42),
    "GradientBoosting":   GradientBoostingClassifier(n_estimators=100, random_state=42),
}

results = {}
for name, clf in models.items():
    pipe = Pipeline([("prep", preprocessor), ("clf", clf)])
    scores = cross_val_score(pipe, X, y, cv=5, scoring="roc_auc", n_jobs=-1)
    results[name] = {"mean": scores.mean(), "std": scores.std()}

pd.DataFrame(results).T.sort_values("mean", ascending=False)
```

---

## Reading Search Results

```python
import pandas as pd

results_df = pd.DataFrame(search.cv_results_)
(
    results_df
    .sort_values("mean_test_score", ascending=False)
    [["params", "mean_test_score", "std_test_score"]]
    .head(10)
)
```

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| Tune on test set | Optimistic bias | Tune on train/val, evaluate once on test |
| `GridSearchCV` with > 100 combos | Slow | `RandomizedSearchCV` or Optuna |
| Ignore `std_test_score` | High variance model | Pick simpler model with similar mean |
| Compare models without same CV splits | Unfair comparison | Use same `cv` object |
