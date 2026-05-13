# Pipeline

> Chain transformers and estimators into a single, leak-free, CV-compatible object.

---

## Why Pipeline?

Without Pipeline, you risk **data leakage**: fitting a scaler on the full dataset before cross-validation means test-fold statistics contaminate training.

Pipeline ensures `fit_transform` is called **only on the training fold** at every CV split.

---

## Basic Pipeline

```python
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression

pipe = Pipeline([
    ("scaler", StandardScaler()),
    ("clf",    LogisticRegression(max_iter=1000)),
])

pipe.fit(X_train, y_train)
y_pred = pipe.predict(X_test)
score  = pipe.score(X_test, y_test)
```

- All steps except the last must implement `transform`
- Last step can be any estimator (including transformers if building a feature pipeline)

---

## make_pipeline (no-name shortcut)

```python
from sklearn.pipeline import make_pipeline

pipe = make_pipeline(StandardScaler(), LogisticRegression())
# Step names are auto-generated: "standardscaler", "logisticregression"
```

Use `Pipeline` when you need named steps for `set_params`.

---

## ColumnTransformer — Mixed Feature Types

Apply different transformations to numeric vs categorical columns.

```python
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.impute import SimpleImputer

num_cols = ["age", "salary", "tenure"]
cat_cols = ["city", "department"]

num_pipe = Pipeline([
    ("impute", SimpleImputer(strategy="median")),
    ("scale",  StandardScaler()),
])
cat_pipe = Pipeline([
    ("impute", SimpleImputer(strategy="most_frequent")),
    ("encode", OneHotEncoder(handle_unknown="ignore", sparse_output=False)),
])

preprocessor = ColumnTransformer([
    ("num", num_pipe, num_cols),
    ("cat", cat_pipe, cat_cols),
], remainder="drop")

full_pipe = Pipeline([
    ("prep", preprocessor),
    ("clf",  LogisticRegression()),
])
```

---

## Accessing Steps

```python
# By name
pipe["scaler"]               # StandardScaler object
pipe.named_steps["scaler"]   # Same

# Set hyperparameters (double underscore notation)
pipe.set_params(clf__C=0.1)
pipe.set_params(prep__num__scale__with_mean=False)
```

---

## Feature Names After Transform

```python
# Get output feature names (sklearn ≥ 1.0)
preprocessor.fit(X_train)
feature_names = preprocessor.get_feature_names_out()
```

---

## Pipeline in Cross-Validation

```python
from sklearn.model_selection import cross_val_score, GridSearchCV

# CV — leakage-free
scores = cross_val_score(full_pipe, X, y, cv=5, scoring="roc_auc")

# Hyperparameter search over pipeline params
param_grid = {
    "clf__C":           [0.01, 0.1, 1],
    "prep__num__scale": [StandardScaler(), RobustScaler()],
}
search = GridSearchCV(full_pipe, param_grid, cv=5, scoring="roc_auc")
search.fit(X_train, y_train)
```

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| `fit_transform` outside Pipeline before CV | Leakage | Put transformer inside Pipeline |
| Access `.steps[-1]` by index in prod | Brittle | Use `pipe["clf"]` by name |
| Forget `remainder="drop"` | Passes through raw columns unexpectedly | Be explicit |
