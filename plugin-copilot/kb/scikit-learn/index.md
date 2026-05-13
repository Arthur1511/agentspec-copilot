# scikit-learn Knowledge Base

> **MCP Validated:** 2026-05-08

## Purpose

Complete reference for **scikit-learn** — the standard Python library for machine learning. Covers the Estimator API, Pipelines, preprocessing, model selection, cross-validation, and evaluation for classification, regression, and clustering tasks.

## Domain Overview

scikit-learn provides a consistent `fit`/`transform`/`predict` API across hundreds of algorithms, transformers, and utilities. Its `Pipeline` abstraction enables reproducible, leak-free ML workflows from raw features to trained models.

**Key Capabilities:**
- Supervised learning: classification, regression
- Unsupervised learning: clustering, dimensionality reduction
- Feature preprocessing and engineering
- Model selection: cross-validation, hyperparameter search
- Evaluation metrics for all task types
- Pipeline composition with `Pipeline` and `ColumnTransformer`
- Integration with pandas, NumPy, joblib, and MLflow

## Key Concepts

| Concept | Description | File |
|---------|-------------|------|
| **Estimator API** | fit/transform/predict contract, cloning, get_params | [estimator-api.md](concepts/estimator-api.md) |
| **Pipeline** | Chain transformers and estimators, prevent data leakage | [pipeline.md](concepts/pipeline.md) |
| **Cross-Validation** | KFold, StratifiedKFold, cross_val_score, nested CV | [cross-validation.md](concepts/cross-validation.md) |
| **Preprocessing** | Scalers, encoders, imputers, ColumnTransformer | [preprocessing.md](concepts/preprocessing.md) |

## Patterns

| Pattern | Use Case | File |
|---------|----------|------|
| **Classification Workflow** | Binary/multiclass: pipeline, fit, threshold tuning, evaluation | [classification-workflow.md](patterns/classification-workflow.md) |
| **Regression Workflow** | Continuous target: pipeline, fit, residual analysis | [regression-workflow.md](patterns/regression-workflow.md) |
| **Model Selection** | GridSearchCV, RandomizedSearchCV, Optuna integration | [model-selection.md](patterns/model-selection.md) |
| **Feature Engineering Pipeline** | ColumnTransformer with mixed numeric/categorical features | [feature-pipeline.md](patterns/feature-pipeline.md) |

## Learning Path

### Beginner
1. Read [estimator-api.md](concepts/estimator-api.md) — understand the contract
2. Study [classification-workflow.md](patterns/classification-workflow.md) — end-to-end example
3. Review [quick-reference.md](quick-reference.md) — most-used classes

### Intermediate
4. Learn [pipeline.md](concepts/pipeline.md) — leak-free composition
5. Master [preprocessing.md](concepts/preprocessing.md) — feature transformers
6. Apply [cross-validation.md](concepts/cross-validation.md) — robust evaluation

### Advanced
7. Build [feature-pipeline.md](patterns/feature-pipeline.md) — ColumnTransformer patterns
8. Tune with [model-selection.md](patterns/model-selection.md) — hyperparameter search
9. Combine with XGBoost/LightGBM via sklearn-compatible wrappers

## Agent Usage

**Target Agents:**
- `ds-model-trainer` — training classification/regression models
- `ds-feature-engineer` — preprocessing pipelines
- `ds-model-evaluator` — metrics and diagnostics
- `ds-eda-analyst` — quick baseline models during EDA

**Common Tasks:**
- Quick baseline: `LogisticRegression`, `RandomForestClassifier`
- Feature prep: `StandardScaler`, `OneHotEncoder`, `SimpleImputer`
- Evaluation: `classification_report`, `roc_auc_score`, `mean_squared_error`
- Tuning: `GridSearchCV`, `RandomizedSearchCV`

## Quick Start

```python
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score
from sklearn.datasets import load_breast_cancer

X, y = load_breast_cancer(return_X_y=True)

pipe = Pipeline([
    ("scaler", StandardScaler()),
    ("clf", LogisticRegression(max_iter=1000)),
])

scores = cross_val_score(pipe, X, y, cv=5, scoring="roc_auc")
print(f"ROC-AUC: {scores.mean():.4f} ± {scores.std():.4f}")
```

## Related Domains

- **pandas** — DataFrame to NumPy array conversion
- **xgboost** — sklearn-compatible wrapper
- **data-quality** — Feature validation before fitting
- **python** — Code quality and type hints
- **testing** — Unit tests for ML pipelines

## References

- Official Docs: https://scikit-learn.org/stable/
- User Guide: https://scikit-learn.org/stable/user_guide.html
- API Reference: https://scikit-learn.org/stable/modules/classes.html
