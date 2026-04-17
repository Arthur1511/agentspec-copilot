# Regularization

> **MCP Validated:** 2026-04-17

## Overview

**Regularization** prevents overfitting in XGBoost by penalizing model complexity. XGBoost provides multiple regularization techniques that can be combined for robust generalization.

## Regularization Techniques

### 1. L2 Regularization (`lambda` / `reg_lambda`)

Penalizes the **squared magnitude** of leaf weights.

**Objective term**:
```
Ω_L2(f) = (1/2) · λ · Σ(w_j^2)
```

Where:
- `w_j` = weight of leaf j
- `λ` = L2 penalty coefficient (default: 1.0)

**Effect**:
- Shrinks leaf weights toward zero
- Prefers many small weights over few large weights
- Increases denominator in leaf weight formula: `w = -Σg / (Σh + λ)`
- **Smooth regularization** (differentiable)

**When to increase λ**:
- Model overfits on training data
- Features are highly correlated
- Want more stable predictions

```python
model = xgb.XGBClassifier(
    reg_lambda=10.0,  # Increase from default 1.0 for stronger L2 penalty
)
```

### 2. L1 Regularization (`alpha` / `reg_alpha`)

Penalizes the **absolute magnitude** of leaf weights.

**Objective term**:
```
Ω_L1(f) = α · Σ|w_j|
```

Where:
- `α` = L1 penalty coefficient (default: 0.0)

**Effect**:
- Induces **sparsity**: drives some leaf weights to exactly zero
- Feature selection at the leaf level
- **Non-smooth regularization** (subgradient at zero)

**When to increase α**:
- Want sparse models (fewer active leaves)
- Suspect many features are irrelevant
- Need interpretability (fewer non-zero weights)

```python
model = xgb.XGBClassifier(
    reg_alpha=1.0,  # Enable L1 penalty for sparse leaves
)
```

### 3. Gamma (Minimum Split Loss / `gamma` / `min_split_loss`)

Minimum loss reduction required to make a split.

**Split gain threshold**:
```
Gain = [Gradient statistics term] - γ
```

A split is only made if `Gain > 0`.

**Effect**:
- **Structural regularization**: controls tree complexity
- Higher gamma → fewer splits → shallower trees
- Acts as **pre-pruning** (prevents splits from happening)

**Parameters**:
- Default: 0 (no penalty)
- Range: [0, ∞)
- Typical values: 0-5 for most tasks

**When to increase γ**:
- Trees are too complex (many splits)
- Overfitting with small gain splits
- Want to reduce training time

```python
model = xgb.XGBClassifier(
    gamma=0.1,  # Require at least 0.1 loss reduction per split
)
```

**Warning**: Setting gamma too high can prevent any splits, resulting in stumps (single-node trees).

### 4. Subsample

Randomly sample a fraction of training instances per tree.

**Mechanism**:
- Before building each tree, randomly select `subsample` fraction of rows
- Introduces **stochastic gradient boosting**
- Different trees see different data subsets

**Effect**:
- Reduces overfitting via bootstrap aggregation
- Speeds up training (fewer samples per tree)
- Increases diversity among trees

**Parameters**:
- Default: 1.0 (use all data)
- Range: (0, 1]
- Typical: 0.5-0.9

```python
model = xgb.XGBClassifier(
    subsample=0.8,  # Use 80% of samples per tree
)
```

### 5. Column Sampling (`colsample_bytree`, `colsample_bylevel`, `colsample_bynode`)

Randomly sample a fraction of features.

**Three levels of sampling**:

| Parameter | When Applied | Use Case |
|-----------|-------------|----------|
| `colsample_bytree` | Once per tree | Default feature sampling |
| `colsample_bylevel` | Per tree level | Increase diversity across depths |
| `colsample_bynode` | Per node split | Most aggressive, Random Forest-like |

**Effect**:
- Prevents feature dominance
- Increases tree diversity
- Reduces correlation between trees
- Inspired by Random Forests

**Parameters**:
- Default: 1.0 (use all features)
- Range: (0, 1]
- Typical: 0.6-1.0

```python
model = xgb.XGBClassifier(
    colsample_bytree=0.8,   # Sample 80% features per tree
    colsample_bylevel=0.9,  # Sample 90% features per level
)
```

### 6. Minimum Child Weight (`min_child_weight`)

Minimum sum of instance weights (hessian) required in a child node.

**Constraint**:
```
Σh_child ≥ min_child_weight
```

**Effect**:
- Prevents splits that create children with too few instances
- Larger values → more conservative (fewer splits)
- Acts as **regularization** and **early stopping** for splits

**Parameters**:
- Default: 1
- Range: [0, ∞)
- Typical: 1-10

**When to increase**:
- Data is noisy
- Avoid overfitting on small data subsets
- Classification with imbalanced classes

```python
model = xgb.XGBClassifier(
    min_child_weight=5,  # Require at least 5 hessian sum in child
)
```

## Combining Regularization Techniques

```python
import xgboost as xgb
from sklearn.datasets import load_breast_cancer
from sklearn.model_selection import train_test_split

X, y = load_breast_cancer(return_X_y=True)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
X_train, X_val, y_train, y_val = train_test_split(X_train, y_train, test_size=0.2, random_state=42)

# No regularization (baseline - likely overfits)
model_baseline = xgb.XGBClassifier(
    n_estimators=200,
    max_depth=10,
    learning_rate=0.3,
    subsample=1.0,
    colsample_bytree=1.0,
    reg_lambda=1.0,
    reg_alpha=0.0,
    gamma=0,
    min_child_weight=1,
)
model_baseline.fit(X_train, y_train)

# Heavy regularization (prevents overfitting)
model_regularized = xgb.XGBClassifier(
    n_estimators=200,
    max_depth=6,              # Shallower trees
    learning_rate=0.05,       # Smaller steps
    subsample=0.8,            # 80% row sampling
    colsample_bytree=0.8,     # 80% feature sampling
    reg_lambda=5.0,           # Strong L2
    reg_alpha=0.5,            # Some L1 (sparsity)
    gamma=0.1,                # Require 0.1 gain per split
    min_child_weight=3,       # At least 3 instances per child
)
model_regularized.fit(X_train, y_train, eval_set=[(X_val, y_val)], verbose=False)

# Compare
print("Baseline - Train:", model_baseline.score(X_train, y_train))
print("Baseline - Test: ", model_baseline.score(X_test, y_test))
print("\nRegularized - Train:", model_regularized.score(X_train, y_train))
print("Regularized - Test: ", model_regularized.score(X_test, y_test))
```

**Expected behavior**:
- Baseline: High train score (>0.99), lower test score (overfitting)
- Regularized: Lower train score (~0.97), **higher test score** (better generalization)

## Regularization Parameter Tuning Order

1. **Start with defaults**:
   ```python
   max_depth=6, lambda=1.0, alpha=0, gamma=0, subsample=1.0, colsample_bytree=1.0
   ```

2. **Add stochastic sampling** (biggest impact, easiest to tune):
   ```python
   subsample=0.8, colsample_bytree=0.8
   ```

3. **Tune L2 regularization**:
   ```python
   reg_lambda in [0.1, 1, 5, 10, 50]
   ```

4. **Add gamma if trees are still complex**:
   ```python
   gamma in [0, 0.1, 0.5, 1.0]
   ```

5. **Add L1 if want sparsity**:
   ```python
   reg_alpha in [0.1, 0.5, 1.0]
   ```

6. **Tune min_child_weight for noisy data**:
   ```python
   min_child_weight in [1, 3, 5, 10]
   ```

## Common Mistakes

| Mistake | Why It's Wrong | Correct Approach |
|---------|----------------|------------------|
| **Setting gamma too high** | No splits made → stumps only | Start with 0, tune up slowly (0.1, 0.5, 1.0) |
| **Using only L2 when want sparse model** | L2 shrinks but doesn't zero out weights | Add L1 (alpha > 0) for sparsity |
| **Not using subsample/colsample** | Missing easiest regularization | Always try 0.8 for both as starting point |
| **Over-regularizing with low learning_rate** | Model underfits + trains forever | Balance: lower LR → less regularization needed |
| **Ignoring min_child_weight on small data** | Overfits on individual samples | Increase to 3-10 on datasets <10k rows |

## Visualization: Effect of Lambda

```python
import numpy as np
import matplotlib.pyplot as plt

lambdas = [0.01, 0.1, 1.0, 10.0, 100.0]
train_scores = []
test_scores = []

for lam in lambdas:
    model = xgb.XGBClassifier(
        n_estimators=100,
        max_depth=8,
        learning_rate=0.1,
        reg_lambda=lam,
        random_state=42
    )
    model.fit(X_train, y_train)
    train_scores.append(model.score(X_train, y_train))
    test_scores.append(model.score(X_test, y_test))

plt.semilogx(lambdas, train_scores, marker='o', label='Train')
plt.semilogx(lambdas, test_scores, marker='s', label='Test')
plt.xlabel('reg_lambda (L2 penalty)')
plt.ylabel('Accuracy')
plt.title('Effect of L2 Regularization')
plt.legend()
plt.grid(True)
plt.show()

# Typical pattern: train decreases, test increases then plateaus
```

## Related Concepts

- [gradient-boosting.md](gradient-boosting.md) — How regularization fits into the objective function
- [tree-architecture.md](tree-architecture.md) — How gamma affects split decisions
- [hyperparameter-tuning.md](../patterns/hyperparameter-tuning.md) — Automated search for optimal regularization

## References

- XGBoost Parameters: https://xgboost.readthedocs.io/en/stable/parameter.html
- Regularization Notes: https://xgboost.readthedocs.io/en/stable/tutorials/model.html
