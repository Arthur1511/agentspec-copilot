# Preprocessing

> Scalers, encoders, imputers, and the ColumnTransformer for mixed feature types.

---

## Scalers

| Scaler | Formula | Use Case |
|--------|---------|---------|
| `StandardScaler` | (x - mean) / std | Normally distributed, no outliers |
| `MinMaxScaler` | (x - min) / (max - min) | Bounded range needed [0, 1] |
| `RobustScaler` | (x - median) / IQR | Outliers present — robust |
| `MaxAbsScaler` | x / max(\|x\|) | Sparse data, preserves zero |
| `Normalizer` | x / \|\|x\|\| | Normalize each row (not column) |

```python
from sklearn.preprocessing import RobustScaler

scaler = RobustScaler()
X_train_sc = scaler.fit_transform(X_train)
X_test_sc  = scaler.transform(X_test)
```

---

## Encoders

### OneHotEncoder (nominal categories)

```python
from sklearn.preprocessing import OneHotEncoder

enc = OneHotEncoder(
    handle_unknown="ignore",  # Unseen categories → all zeros
    sparse_output=False,      # Dense array (pandas-friendly)
    drop="first",             # Drop one column to avoid multicollinearity
)
```

### OrdinalEncoder (ordered categories)

```python
from sklearn.preprocessing import OrdinalEncoder

enc = OrdinalEncoder(
    categories=[["low", "medium", "high"]],  # Explicit order
    handle_unknown="use_encoded_value",
    unknown_value=-1,
)
```

### TargetEncoder (high-cardinality, sklearn ≥ 1.3)

```python
from sklearn.preprocessing import TargetEncoder

enc = TargetEncoder(smooth="auto", cv=5)  # Regularized mean encoding
```

---

## Imputers

| Imputer | Strategy | Notes |
|---------|---------|-------|
| `SimpleImputer(strategy="mean")` | Column mean | Numeric |
| `SimpleImputer(strategy="median")` | Column median | Numeric + outliers |
| `SimpleImputer(strategy="most_frequent")` | Mode | Numeric or categorical |
| `SimpleImputer(strategy="constant", fill_value=0)` | Fixed value | Any type |
| `KNNImputer(n_neighbors=5)` | KNN-based | Captures correlations |
| `IterativeImputer` | MICE / regression-based | Best quality, slow |

```python
from sklearn.impute import SimpleImputer, KNNImputer

imp = SimpleImputer(strategy="median")
X_imputed = imp.fit_transform(X_train)
```

---

## Adding Missing Indicator

```python
from sklearn.impute import MissingIndicator

indicator = MissingIndicator(features="missing-only")
X_indicators = indicator.fit_transform(X)
```

Pair with an imputer using `FeatureUnion` or in a `ColumnTransformer`.

---

## FunctionTransformer

Apply any NumPy-compatible function as a scikit-learn transformer.

```python
from sklearn.preprocessing import FunctionTransformer
import numpy as np

log_transformer = FunctionTransformer(np.log1p, validate=True)
```

---

## ColumnTransformer Summary

```python
from sklearn.compose import ColumnTransformer, make_column_selector

preprocessor = ColumnTransformer([
    ("num",  StandardScaler(), make_column_selector(dtype_include="number")),
    ("cat",  OneHotEncoder(handle_unknown="ignore"),
             make_column_selector(dtype_include="object")),
], remainder="drop", verbose_feature_names_out=False)
```

`make_column_selector` auto-detects columns by dtype — no hardcoded lists.

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| `fit` scaler on all data before CV | Leakage | Fit inside Pipeline/CV |
| Drop rows with nulls blindly | Lose data, bias results | Impute or add indicator |
| Ordinal encode nominal categories | Implies false order | OneHotEncoder |
| Encode target variable | Not a feature | Keep `y` separate |
