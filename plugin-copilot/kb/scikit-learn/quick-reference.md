# scikit-learn Quick Reference

> **MCP Validated:** 2026-05-08

Fast lookup for the most-used scikit-learn classes and patterns.

---

## Estimator API

| Operation | Code |
|-----------|------|
| Fit | `model.fit(X_train, y_train)` |
| Predict | `model.predict(X_test)` |
| Predict proba | `model.predict_proba(X_test)[:, 1]` |
| Transform | `transformer.fit_transform(X_train)` |
| Score | `model.score(X_test, y_test)` |
| Clone | `from sklearn.base import clone; clone(model)` |

---

## Common Estimators

### Classification
| Model | Import |
|-------|--------|
| Logistic Regression | `from sklearn.linear_model import LogisticRegression` |
| Random Forest | `from sklearn.ensemble import RandomForestClassifier` |
| Gradient Boosting | `from sklearn.ensemble import GradientBoostingClassifier` |
| SVC | `from sklearn.svm import SVC` |
| KNN | `from sklearn.neighbors import KNeighborsClassifier` |

### Regression
| Model | Import |
|-------|--------|
| Linear Regression | `from sklearn.linear_model import LinearRegression` |
| Ridge / Lasso | `from sklearn.linear_model import Ridge, Lasso` |
| Random Forest | `from sklearn.ensemble import RandomForestRegressor` |
| SVR | `from sklearn.svm import SVR` |

---

## Preprocessing

| Transformer | Purpose | Class |
|-------------|---------|-------|
| StandardScaler | Zero mean, unit variance | `preprocessing.StandardScaler` |
| MinMaxScaler | Scale to [0, 1] | `preprocessing.MinMaxScaler` |
| RobustScaler | Median/IQR (outlier-safe) | `preprocessing.RobustScaler` |
| OneHotEncoder | Nominal categories | `preprocessing.OneHotEncoder` |
| OrdinalEncoder | Ordinal categories | `preprocessing.OrdinalEncoder` |
| SimpleImputer | Fill nulls | `impute.SimpleImputer` |
| KNNImputer | KNN-based imputation | `impute.KNNImputer` |
| PolynomialFeatures | Interaction terms | `preprocessing.PolynomialFeatures` |

---

## Pipeline

```python
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer

num_pipe = Pipeline([("impute", SimpleImputer()), ("scale", StandardScaler())])
cat_pipe = Pipeline([("impute", SimpleImputer(strategy="most_frequent")),
                     ("encode", OneHotEncoder(handle_unknown="ignore"))])

preprocessor = ColumnTransformer([
    ("num", num_pipe, num_cols),
    ("cat", cat_pipe, cat_cols),
])

pipe = Pipeline([("prep", preprocessor), ("clf", LogisticRegression())])
```

---

## Cross-Validation

| Splitter | Use Case |
|----------|----------|
| `KFold(n_splits=5)` | Regression, balanced classes |
| `StratifiedKFold(n_splits=5)` | Classification (preserves class ratio) |
| `TimeSeriesSplit(n_splits=5)` | Time-ordered data |
| `GroupKFold` | No group leakage (subject-level splits) |

```python
from sklearn.model_selection import cross_val_score
scores = cross_val_score(pipe, X, y, cv=StratifiedKFold(5), scoring="roc_auc")
```

---

## Model Selection

```python
from sklearn.model_selection import GridSearchCV, RandomizedSearchCV

param_grid = {"clf__C": [0.01, 0.1, 1, 10], "clf__penalty": ["l1", "l2"]}
search = GridSearchCV(pipe, param_grid, cv=5, scoring="roc_auc", n_jobs=-1)
search.fit(X_train, y_train)
print(search.best_params_, search.best_score_)
```

---

## Evaluation Metrics

### Classification
| Metric | Function |
|--------|----------|
| Accuracy | `accuracy_score(y, y_pred)` |
| ROC-AUC | `roc_auc_score(y, y_proba)` |
| F1 | `f1_score(y, y_pred, average="weighted")` |
| Full report | `classification_report(y, y_pred)` |
| Confusion matrix | `confusion_matrix(y, y_pred)` |

### Regression
| Metric | Function |
|--------|----------|
| RMSE | `mean_squared_error(y, y_pred, squared=False)` |
| MAE | `mean_absolute_error(y, y_pred)` |
| R² | `r2_score(y, y_pred)` |

---

## Common Pitfalls

| Mistake | Fix |
|---------|-----|
| Fit scaler on full data | Always fit transformers **only** on training fold |
| Not using Pipeline | Wrap all steps — prevents leakage in CV |
| `predict_proba` unavailable | Use `SVC(probability=True)` |
| Ignoring class imbalance | Use `class_weight="balanced"` or SMOTE |
| Wrong CV for time series | Use `TimeSeriesSplit`, not `KFold` |
