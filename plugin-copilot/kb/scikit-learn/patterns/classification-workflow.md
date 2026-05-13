# Classification Workflow

> End-to-end binary/multiclass classification with sklearn Pipeline, evaluation, and threshold tuning.

---

## Full Classification Template

```python
import numpy as np
import pandas as pd
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.impute import SimpleImputer
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import StratifiedKFold, cross_validate
from sklearn.metrics import classification_report, roc_auc_score, RocCurveDisplay
import matplotlib.pyplot as plt

# ── 1. Feature setup ──────────────────────────────────────────────────────────
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
])

# ── 2. Pipeline ───────────────────────────────────────────────────────────────
pipe = Pipeline([
    ("prep", preprocessor),
    ("clf",  RandomForestClassifier(n_estimators=200, class_weight="balanced",
                                    random_state=42, n_jobs=-1)),
])

# ── 3. Cross-validation ───────────────────────────────────────────────────────
cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
results = cross_validate(
    pipe, X, y, cv=cv,
    scoring=["roc_auc", "f1_weighted", "accuracy"],
    return_train_score=True,
    n_jobs=-1,
)
print(f"ROC-AUC:  {results['test_roc_auc'].mean():.4f} ± {results['test_roc_auc'].std():.4f}")
print(f"F1:       {results['test_f1_weighted'].mean():.4f}")

# ── 4. Final fit + evaluation ─────────────────────────────────────────────────
pipe.fit(X_train, y_train)
y_pred  = pipe.predict(X_test)
y_proba = pipe.predict_proba(X_test)[:, 1]

print(classification_report(y_test, y_pred))
print(f"Test ROC-AUC: {roc_auc_score(y_test, y_proba):.4f}")
```

---

## Class Imbalance Strategies

| Strategy | When | Code |
|---------|------|------|
| `class_weight="balanced"` | Mild imbalance (< 10:1) | `RandomForestClassifier(class_weight="balanced")` |
| SMOTE oversampling | Moderate imbalance | `imblearn.over_sampling.SMOTE` |
| Threshold tuning | Optimizing precision/recall | See below |
| Use `average_precision` metric | Severe imbalance | `scoring="average_precision"` |

---

## Threshold Tuning

Default threshold is 0.5 — tune for precision/recall trade-off:

```python
from sklearn.metrics import precision_recall_curve

precisions, recalls, thresholds = precision_recall_curve(y_test, y_proba)

# Find threshold for target recall ≥ 0.80
idx = np.argmax(recalls >= 0.80)
best_threshold = thresholds[idx]
y_pred_tuned = (y_proba >= best_threshold).astype(int)
```

---

## Multiclass Pattern

```python
from sklearn.metrics import classification_report

# Works identically — sklearn handles multiclass automatically
pipe.fit(X_train, y_train)
y_pred = pipe.predict(X_test)
print(classification_report(y_test, y_pred))

# ROC-AUC for multiclass
roc_auc_score(y_test, pipe.predict_proba(X_test), multi_class="ovr")
```

---

## Saving and Loading

```python
import joblib

joblib.dump(pipe, "model.pkl")
pipe = joblib.load("model.pkl")
```

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| Fit preprocessor outside Pipeline | Leakage in CV | Wrap in Pipeline |
| Use accuracy on imbalanced data | Misleading | ROC-AUC or average_precision |
| Ignore class imbalance | Biased towards majority | `class_weight="balanced"` |
| Use same data for selection and final eval | Optimistic | Nested CV or holdout test set |
