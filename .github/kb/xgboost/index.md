# XGBoost Knowledge Base

> **MCP Validated:** 2026-04-17

## Purpose

Complete reference for **XGBoost** (eXtreme Gradient Boosting) — a scalable, production-ready gradient boosting library for tabular machine learning tasks including classification, regression, and ranking.

## Domain Overview

XGBoost implements gradient boosted decision trees with advanced features like regularization, early stopping, handling missing values, and parallel processing. It's the go-to algorithm for structured/tabular data in Kaggle competitions and production ML systems.

**Key Capabilities:**
- Binary and multiclass classification
- Regression (linear, logistic, Poisson, etc.)
- Ranking and learning-to-rank
- Built-in cross-validation
- Feature importance analysis
- Native GPU acceleration
- Early stopping and regularization

## Key Concepts

| Concept | Description | File |
|---------|-------------|------|
| **Gradient Boosting** | Additive model training via gradient descent in function space | [gradient-boosting.md](concepts/gradient-boosting.md) |
| **Tree Architecture** | Tree construction algorithms: exact, approximate, histogram-based | [tree-architecture.md](concepts/tree-architecture.md) |
| **Regularization** | L1/L2 penalties, gamma, subsample techniques to prevent overfitting | [regularization.md](concepts/regularization.md) |
| **Feature Importance** | Weight, gain, cover metrics; SHAP integration | [feature-importance.md](concepts/feature-importance.md) |

## Patterns

| Pattern | Use Case | File |
|---------|----------|------|
| **Training Pipeline** | Production-ready training with DMatrix, early stopping, model persistence | [training-pipeline.md](patterns/training-pipeline.md) |
| **Hyperparameter Tuning** | Optuna-based search for optimal XGBoost parameters | [hyperparameter-tuning.md](patterns/hyperparameter-tuning.md) |
| **Early Stopping** | Prevent overfitting by monitoring validation metrics | [early-stopping.md](patterns/early-stopping.md) |
| **Cross-Validation** | Native xgb.cv() and sklearn integration for model evaluation | [cross-validation.md](patterns/cross-validation.md) |

## Specifications

| Spec | Description | File |
|------|-------------|------|
| **XGBoost Parameters** | Complete parameter reference with types, ranges, defaults | [xgboost-params.yaml](specs/xgboost-params.yaml) |

## Learning Path

### Beginner
1. Read [gradient-boosting.md](concepts/gradient-boosting.md) — understand the core algorithm
2. Study [training-pipeline.md](patterns/training-pipeline.md) — basic training workflow
3. Review [quick-reference.md](quick-reference.md) — common parameters and metrics

### Intermediate
4. Learn [regularization.md](concepts/regularization.md) — prevent overfitting
5. Implement [early-stopping.md](patterns/early-stopping.md) — monitor validation metrics
6. Explore [feature-importance.md](concepts/feature-importance.md) — interpret model decisions

### Advanced
7. Master [hyperparameter-tuning.md](patterns/hyperparameter-tuning.md) — optimize performance
8. Study [tree-architecture.md](concepts/tree-architecture.md) — understand internal algorithms
9. Apply [cross-validation.md](patterns/cross-validation.md) — robust model evaluation

## Agent Usage

**Target Agents:**
- `data-scientist` — model development and experimentation
- `ml-engineer` — production pipeline implementation
- `python-developer` — integration with existing systems

**Common Tasks:**
- Binary classification: Use `binary:logistic` objective with `auc` metric
- Multiclass classification: Use `multi:softmax` with `merror` metric
- Regression: Use `reg:squarederror` with `rmse` metric
- Feature selection: Extract importance scores via `get_score()` or SHAP
- Production deployment: Save as `.ubj` format for language-agnostic loading

## Quick Start

```python
import xgboost as xgb
from sklearn.datasets import load_breast_cancer
from sklearn.model_selection import train_test_split

# Load data
X, y = load_breast_cancer(return_X_y=True)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

# Train
model = xgb.XGBClassifier(
    max_depth=6,
    learning_rate=0.1,
    n_estimators=100,
    objective='binary:logistic',
    tree_method='hist',
    eval_metric='auc'
)
model.fit(X_train, y_train, eval_set=[(X_test, y_test)], verbose=False)

# Predict
y_pred = model.predict_proba(X_test)[:, 1]
print(f"Model score: {model.score(X_test, y_test):.4f}")
```

## Related Domains

- **Python** — Core language for XGBoost API
- **Testing** — Unit tests for ML pipelines
- **Data Quality** — Feature engineering and validation

## References

- Official Docs: https://xgboost.readthedocs.io/
- GitHub: https://github.com/dmlc/xgboost
- Paper: Chen & Guestrin (2016) — "XGBoost: A Scalable Tree Boosting System"
