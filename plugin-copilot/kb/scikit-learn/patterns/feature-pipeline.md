# Feature Engineering Pipeline

> ColumnTransformer with mixed numeric/categorical features, custom transformers, and feature selection.

---

## The Standard Feature Pipeline

```python
import numpy as np
import pandas as pd
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer, make_column_selector
from sklearn.preprocessing import StandardScaler, OneHotEncoder, PolynomialFeatures
from sklearn.impute import SimpleImputer, KNNImputer
from sklearn.feature_selection import SelectFromModel
from sklearn.ensemble import RandomForestClassifier

# ── Column groups ─────────────────────────────────────────────────────────────
num_cols = ["age", "salary", "tenure", "revenue"]
cat_cols = ["city", "department", "job_title"]
binary   = ["is_manager", "has_contract"]

# ── Sub-pipelines ─────────────────────────────────────────────────────────────
num_pipe = Pipeline([
    ("impute", KNNImputer(n_neighbors=5)),
    ("scale",  StandardScaler()),
])

cat_pipe = Pipeline([
    ("impute", SimpleImputer(strategy="most_frequent")),
    ("encode", OneHotEncoder(handle_unknown="ignore", sparse_output=False,
                              min_frequency=0.01)),  # Rare categories → "infrequent_sklearn"
])

# ── ColumnTransformer ─────────────────────────────────────────────────────────
preprocessor = ColumnTransformer([
    ("num",    num_pipe, num_cols),
    ("cat",    cat_pipe, cat_cols),
    ("binary", "passthrough", binary),
], remainder="drop", verbose_feature_names_out=False)
```

---

## Auto Column Detection (pandas dtypes)

```python
from sklearn.compose import make_column_selector

preprocessor = ColumnTransformer([
    ("num", num_pipe, make_column_selector(dtype_include="number")),
    ("cat", cat_pipe, make_column_selector(dtype_include=["object", "category"])),
])
```

Requires consistent pandas dtypes — cast at load time.

---

## Custom Transformer

```python
from sklearn.base import BaseEstimator, TransformerMixin

class DateFeatureExtractor(BaseEstimator, TransformerMixin):
    """Extract year, month, day-of-week from a datetime column."""
    def __init__(self, col: str):
        self.col = col

    def fit(self, X, y=None):
        return self

    def transform(self, X):
        X = X.copy()
        dt = pd.to_datetime(X[self.col])
        X[f"{self.col}_year"]  = dt.dt.year
        X[f"{self.col}_month"] = dt.dt.month
        X[f"{self.col}_dow"]   = dt.dt.dayofweek
        return X.drop(columns=[self.col])
```

---

## Interaction Features

```python
# Polynomial interactions for numeric features
num_pipe_poly = Pipeline([
    ("impute", SimpleImputer(strategy="median")),
    ("scale",  StandardScaler()),
    ("poly",   PolynomialFeatures(degree=2, interaction_only=True,
                                  include_bias=False)),
])
```

---

## Feature Selection Inside Pipeline

```python
# Select features by model importance
selection_pipe = Pipeline([
    ("prep",   preprocessor),
    ("select", SelectFromModel(RandomForestClassifier(n_estimators=100,
                                                      random_state=42),
                               threshold="median")),
    ("clf",    LogisticRegression()),
])
```

---

## Getting Feature Names After Fit

```python
preprocessor.fit(X_train)
feature_names = preprocessor.get_feature_names_out()
print(f"Total features: {len(feature_names)}")
```

---

## Logging Feature Counts

```python
pipe.fit(X_train, y_train)
n_in  = X_train.shape[1]
n_out = pipe[:-1].transform(X_train).shape[1]
print(f"Input features:  {n_in}")
print(f"Output features: {n_out}")
```

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| Fit preprocessor outside Pipeline | Leakage in CV | Always inside Pipeline |
| One-hot encode high-cardinality cols without `min_frequency` | Explodes features | Use `min_frequency` or TargetEncoder |
| Polynomial on all features | Combinatorial explosion | Select key features first |
| Manual feature scaling on test set | Different statistics | `transform` via fitted Pipeline |
| Drop ID/date columns after Pipeline | Forgotten remainder | `remainder="drop"` explicitly |
