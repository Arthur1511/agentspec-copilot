# Gradient Boosting

> **MCP Validated:** 2026-04-17

## Overview

**Gradient boosting** is an ensemble learning technique that builds a strong predictive model by sequentially adding weak learners (typically decision trees) that correct the errors of previous models. Each new model is trained to predict the residual errors (gradients) of the combined ensemble.

## Mathematical Foundation

### Additive Model

Gradient boosting constructs a model as a sum of weak learners:

```
F(x) = Σ(f_t(x))  for t = 1 to T
```

Where:
- `F(x)` is the final ensemble model
- `f_t(x)` is the t-th weak learner (tree)
- `T` is the total number of trees

### Gradient Descent in Function Space

At each iteration, gradient boosting:

1. **Computes gradients**: Calculate the negative gradient of the loss function with respect to current predictions
2. **Fits weak learner**: Train a new tree to predict these gradients
3. **Updates ensemble**: Add the new tree with a learning rate (shrinkage)

```
F_t(x) = F_{t-1}(x) + η · f_t(x)
```

Where `η` is the learning rate (step size).

### Loss Function Minimization

For regression (squared error):
```
L(y, F(x)) = (y - F(x))^2
∂L/∂F = -2(y - F(x)) = -2 · residual
```

For classification (logistic loss):
```
L(y, F(x)) = log(1 + exp(-y · F(x)))
∂L/∂F = -y / (1 + exp(y · F(x)))
```

## XGBoost Improvements Over Vanilla GBM

### 1. Second-Order Gradients (Newton Boosting)

**Traditional GBM** uses first-order gradients (Taylor expansion to 1st order):
```
L(y, F + f) ≈ L(y, F) + g · f
```

**XGBoost** uses second-order gradients (Taylor expansion to 2nd order):
```
L(y, F + f) ≈ L(y, F) + g · f + (1/2) · h · f^2
```

Where:
- `g = ∂L/∂F` (first derivative / gradient)
- `h = ∂²L/∂F²` (second derivative / hessian)

**Benefit**: More accurate approximation, faster convergence, better handling of loss functions.

### 2. Regularized Objective

XGBoost adds regularization to prevent overfitting:

```
Objective = Σ(Loss) + Σ(Ω(f_t))
```

Where regularization term:
```
Ω(f) = γ · T + (1/2) · λ · Σ(w_j^2) + α · Σ(|w_j|)
```

- `γ`: Complexity penalty per leaf (min_split_loss)
- `λ`: L2 regularization on leaf weights (reg_lambda)
- `α`: L1 regularization on leaf weights (reg_alpha)
- `w_j`: Weight of leaf j
- `T`: Number of leaves

### 3. Tree Pruning

**Vanilla GBM**: Grows trees to max_depth then prunes
**XGBoost**: Uses "max depth" first with backward pruning via gain-based stopping

Split gain formula:
```
Gain = (1/2) · [ (Σg_L)^2/(Σh_L + λ) + (Σg_R)^2/(Σh_R + λ) - (Σg)^2/(Σh + λ) ] - γ
```

If `Gain < 0`, the split is not made (controlled by `gamma` parameter).

### 4. Parallel Computation

- **Feature-level parallelism**: Sorts features in parallel for split finding
- **Histogram-based method**: Pre-bins continuous features for faster splits
- **GPU acceleration**: Native CUDA kernels for tree construction

## Code Example

```python
import xgboost as xgb
from sklearn.datasets import load_diabetes
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
import numpy as np

# Load regression dataset
X, y = load_diabetes(return_X_y=True)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# XGBoost with default settings
model = xgb.XGBRegressor(
    n_estimators=100,
    learning_rate=0.1,
    max_depth=5,
    objective='reg:squarederror',
    tree_method='hist',
    random_state=42
)

# Train
model.fit(X_train, y_train)

# Predict
y_pred = model.predict(X_test)
rmse = np.sqrt(mean_squared_error(y_test, y_pred))

print(f"RMSE: {rmse:.2f}")
print(f"Number of trees: {model.n_estimators}")
print(f"Best iteration: {model.best_iteration if hasattr(model, 'best_iteration') else 'N/A'}")

# Inspect learned function (first few trees)
print(f"\nFirst tree structure:")
print(model.get_booster().get_dump()[0])
```

**Output interpretation**:
- Each tree corrects residuals from previous trees
- Learning rate controls the contribution of each tree
- Total prediction = sum of all tree predictions

## Iteration Breakdown

```python
# Visualize gradual improvement
import matplotlib.pyplot as plt

predictions_per_iter = []
for i in range(1, 101, 10):
    model_partial = xgb.XGBRegressor(
        n_estimators=i,
        learning_rate=0.1,
        max_depth=5,
        objective='reg:squarederror',
        random_state=42
    )
    model_partial.fit(X_train, y_train)
    y_pred_partial = model_partial.predict(X_test)
    rmse_partial = np.sqrt(mean_squared_error(y_test, y_pred_partial))
    predictions_per_iter.append((i, rmse_partial))

# Plot RMSE vs number of trees
iters, rmses = zip(*predictions_per_iter)
plt.plot(iters, rmses, marker='o')
plt.xlabel('Number of Trees')
plt.ylabel('RMSE')
plt.title('Model Performance vs Boosting Iterations')
plt.grid(True)
plt.show()
```

## Common Mistakes

| Mistake | Why It's Wrong | Correct Approach |
|---------|----------------|------------------|
| **Confusing n_estimators with epochs** | XGBoost builds trees sequentially, not in parallel epochs | Each tree is added one at a time; n_estimators = total trees |
| **Using very high learning_rate** | Large steps can overshoot optimal solution | Start with 0.01-0.1; lower rate + more trees = better generalization |
| **Ignoring second-order info** | XGBoost's strength is using Hessian | Trust the default objective; custom losses need grad + hess |
| **Not monitoring training** | Can't see if model is overfitting | Always use `eval_set` to track validation metrics |

## Related Concepts

- [tree-architecture.md](tree-architecture.md) — How XGBoost constructs individual trees
- [regularization.md](regularization.md) — Techniques to prevent overfitting in gradient boosting
- [early-stopping.md](../patterns/early-stopping.md) — Stop training when validation metric stops improving

## References

- Chen & Guestrin (2016): "XGBoost: A Scalable Tree Boosting System"
- Friedman (2001): "Greedy Function Approximation: A Gradient Boosting Machine"
- XGBoost Tutorials: https://xgboost.readthedocs.io/en/stable/tutorials/model.html
