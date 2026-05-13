# Regression Workflow

> End-to-end continuous target modeling with sklearn Pipeline, residual analysis, and evaluation.

---

## Full Regression Template

```python
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.impute import SimpleImputer
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import KFold, cross_validate
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

# ── 1. Preprocessing ──────────────────────────────────────────────────────────
num_cols = ["sqft", "age", "rooms"]
cat_cols = ["neighborhood", "type"]

preprocessor = ColumnTransformer([
    ("num", Pipeline([
        ("impute", SimpleImputer(strategy="median")),
        ("scale",  StandardScaler()),
    ]), num_cols),
    ("cat", Pipeline([
        ("impute", SimpleImputer(strategy="most_frequent")),
        ("encode", OneHotEncoder(handle_unknown="ignore", sparse_output=False)),
    ]), cat_cols),
])

# ── 2. Pipeline ───────────────────────────────────────────────────────────────
pipe = Pipeline([
    ("prep", preprocessor),
    ("reg",  RandomForestRegressor(n_estimators=200, random_state=42, n_jobs=-1)),
])

# ── 3. Cross-validation ───────────────────────────────────────────────────────
cv = KFold(n_splits=5, shuffle=True, random_state=42)
results = cross_validate(
    pipe, X, y, cv=cv,
    scoring=["neg_mean_squared_error", "neg_mean_absolute_error", "r2"],
    return_train_score=True,
)
rmse = np.sqrt(-results["test_neg_mean_squared_error"])
print(f"RMSE: {rmse.mean():.2f} ± {rmse.std():.2f}")
print(f"MAE:  {(-results['test_neg_mean_absolute_error']).mean():.2f}")
print(f"R²:   {results['test_r2'].mean():.4f}")

# ── 4. Final fit ──────────────────────────────────────────────────────────────
pipe.fit(X_train, y_train)
y_pred = pipe.predict(X_test)
```

---

## Regression Metrics

| Metric | Formula | Interpretation |
|--------|---------|---------------|
| RMSE | √MSE | Same units as target, penalizes large errors |
| MAE | mean(\|y - ŷ\|) | Robust to outliers |
| R² | 1 - SS_res/SS_tot | Proportion of variance explained (1.0 = perfect) |
| MAPE | mean(\|y - ŷ\|/y) | Percentage error — avoid with near-zero targets |

```python
rmse = mean_squared_error(y_test, y_pred, squared=False)
mae  = mean_absolute_error(y_test, y_pred)
r2   = r2_score(y_test, y_pred)
```

---

## Residual Analysis

```python
residuals = y_test - y_pred

# Plot residuals vs predicted
plt.scatter(y_pred, residuals, alpha=0.4)
plt.axhline(0, color="red", linestyle="--")
plt.xlabel("Predicted")
plt.ylabel("Residual")
plt.title("Residual Plot")
plt.show()

# Distribution of residuals
import seaborn as sns
sns.histplot(residuals, kde=True)
```

**Ideal residual plot:** Random scatter around zero — no patterns.
**Warning signs:** Funnel shape (heteroscedasticity), curves (non-linearity).

---

## Target Transformation

When target is right-skewed (e.g., house prices):

```python
from sklearn.preprocessing import PowerTransformer
from sklearn.compose import TransformedTargetRegressor

model = TransformedTargetRegressor(
    regressor=pipe,
    transformer=PowerTransformer(method="yeo-johnson"),
)
model.fit(X_train, y_train)
y_pred = model.predict(X_test)  # Auto back-transformed
```

---

## Handling Outliers in Target

```python
# Cap extreme values
q99 = y.quantile(0.99)
y_capped = y.clip(upper=q99)

# Or remove for training, evaluate on all
mask = y < q99
pipe.fit(X_train[mask], y_train[mask])
```

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| Optimize only RMSE | Large errors dominate | Check MAE too |
| Skip residual analysis | Misses non-linearity and heteroscedasticity | Always plot residuals |
| Apply `log` to target manually | Must manually inverse on predict | Use `TransformedTargetRegressor` |
| R² as sole metric | Can be high with poor predictions | Use RMSE + residual plot |
| Use `KFold` without shuffle | Ordered data causes fold leakage | Always `shuffle=True` |
