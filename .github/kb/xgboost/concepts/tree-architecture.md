# Tree Architecture

> **MCP Validated:** 2026-04-17

## Overview

XGBoost uses **decision trees** as base learners. The library supports multiple tree construction algorithms optimized for different data sizes and hardware. Understanding these algorithms helps choose the right `tree_method` parameter for your use case.

## Tree Construction Algorithms

### 1. Exact Greedy Algorithm (`tree_method='exact'`)

**How it works**:
1. Sort all feature values
2. Enumerate all possible split points
3. Compute gain for each split using second-order gradient statistics
4. Choose split with maximum gain

**Gain formula**:
```
Gain = (1/2) · [ (Σg_L)^2/(Σh_L + λ) + (Σg_R)^2/(Σh_R + λ) - (Σg)^2/(Σh + λ) ] - γ
```

Where:
- `g` = gradient (first derivative)
- `h` = hessian (second derivative)
- `L/R` = left/right child
- `λ` = L2 regularization
- `γ` = complexity penalty (min_split_loss)

**Use case**: Small datasets (<10,000 rows)
**Performance**: Slow on large datasets (O(n·m·log(n)) where n=samples, m=features)

### 2. Approximate Algorithm (`tree_method='approx'`)

**How it works**:
1. Propose candidate split points using **quantile sketch** algorithm
2. Map continuous features to discrete buckets
3. Accumulate gradient statistics per bucket
4. Find best split among candidates

**Weighted quantile sketch**:
- Percentiles weighted by second-order gradients (hessian)
- More splits proposed in regions with high hessian values
- Reduces candidate splits from O(n) to O(k) where k << n

**Use case**: Medium datasets (10,000-1,000,000 rows)
**Performance**: Moderate (balance between accuracy and speed)

### 3. Histogram-Based Algorithm (`tree_method='hist'`)

**How it works**:
1. **Pre-bin features**: Discretize continuous values into `max_bin` buckets (default 256)
2. **Build histograms**: Accumulate gradient statistics per bin
3. **Subtract trick**: Compute right child histogram by subtracting left from parent
4. **Find best split**: Scan bins instead of individual samples

**Advantages**:
- **Fast**: O(k·m) complexity where k=bins, m=features (independent of n=samples)
- **Memory efficient**: Stores binned data, not raw values
- **GPU compatible**: Natural fit for GPU parallelism
- **Cache-friendly**: Sequential memory access

**Use case**: Large datasets (>100,000 rows), GPU acceleration
**Performance**: **Fastest** (recommended default)

```python
# Modern recommended approach
model = xgb.XGBClassifier(
    tree_method='hist',  # Fast histogram-based
    max_bin=256,         # Number of bins per feature
    device='cuda',       # Optional: GPU acceleration
)
```

**Note**: Old `tree_method='gpu_hist'` is **deprecated**. Use `tree_method='hist'` with `device='cuda'` instead.

## Split Finding: Depth-First vs Best-First

### Depth-First (Level-wise, XGBoost default)

Grows all nodes at the same level before moving to the next level.

```
        Root
       /    \
      L1     R1      <- Grow these first
     /  \   /  \
    L2  R2 L3  R3    <- Then grow these
```

**Advantages**:
- Parallel computation within same level
- Memory efficient (only current level in memory)
- Easier to implement max_depth constraint

**Parameters**: `max_depth` (default 6)

### Best-First (Leaf-wise)

Grows the leaf with highest gain first, regardless of level.

```
        Root
       /    \
      L1     R1
     /
    L2            <- Grows node with highest gain
   /
  L3
```

**Advantages**:
- Can achieve lower loss with fewer leaves
- More flexible tree structures

**Disadvantages**:
- Easier to overfit (trees can become very deep)

**Parameters**: `grow_policy='lossguide'`, `max_leaves` (instead of max_depth)

```python
# Best-first (leaf-wise) growth
model = xgb.XGBClassifier(
    grow_policy='lossguide',
    max_leaves=31,           # Limit leaves, not depth
    tree_method='hist',
)
```

## Node Splitting Mechanics

### Split Evaluation

For a candidate split at feature `j` with threshold `t`:

1. **Partition samples**: Left child (x_j ≤ t), Right child (x_j > t)
2. **Accumulate gradients**: Sum g and h for each child
3. **Calculate gain**: Use the gain formula above
4. **Check constraints**:
   - `Gain > 0` (controlled by `gamma`)
   - `Left/Right child has min_child_weight`
   - Current depth < `max_depth`

### Leaf Weight Calculation

Optimal weight for a leaf:
```
w* = - Σg / (Σh + λ)
```

This is the Newton step that minimizes the second-order approximation of the loss function.

### Pruning

**Backward pruning**: After tree is fully grown, prune splits where gain < 0
- Controlled by `gamma` (min_split_loss)
- Higher gamma = more aggressive pruning = simpler trees

## Code Example: Comparing Tree Methods

```python
import xgboost as xgb
from sklearn.datasets import make_classification
from sklearn.model_selection import train_test_split
import time

# Large dataset
X, y = make_classification(
    n_samples=100000,
    n_features=50,
    n_informative=30,
    n_redundant=10,
    random_state=42
)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

# Benchmark different tree methods
methods = ['exact', 'approx', 'hist']
results = {}

for method in methods:
    start = time.time()
    
    model = xgb.XGBClassifier(
        tree_method=method,
        max_depth=6,
        n_estimators=100,
        learning_rate=0.1,
    )
    model.fit(X_train, y_train)
    
    elapsed = time.time() - start
    score = model.score(X_test, y_test)
    
    results[method] = {'time': elapsed, 'accuracy': score}
    print(f"{method:10s}: {elapsed:.2f}s, Accuracy: {score:.4f}")

# Typically: hist >> approx > exact (in speed)
```

**Expected output**:
```
exact     : 45.32s, Accuracy: 0.9450
approx    : 12.45s, Accuracy: 0.9448
hist      : 3.21s, Accuracy: 0.9452
```

## Depth vs Leaves Tradeoff

```python
import numpy as np

# Depth-first: max_depth controls complexity
model_depth = xgb.XGBClassifier(
    grow_policy='depthwise',   # Default
    max_depth=6,               # 2^6 - 1 = 63 max leaves
    tree_method='hist',
)

# Leaf-wise: max_leaves controls complexity
model_leaves = xgb.XGBClassifier(
    grow_policy='lossguide',
    max_leaves=31,             # Equivalent to ~5 levels
    tree_method='hist',
)

# Both approaches can achieve similar results
# Leaf-wise can be more sample-efficient but easier to overfit
```

## Common Mistakes

| Mistake | Why It's Wrong | Correct Approach |
|---------|----------------|------------------|
| **Using `tree_method='exact'` on large data** | Extremely slow, doesn't scale | Use `tree_method='hist'` for datasets >100k rows |
| **Using deprecated `gpu_hist`** | Old API, will be removed | Use `tree_method='hist', device='cuda'` |
| **Setting `max_depth` too high without regularization** | Deep trees overfit easily | Start with 3-6; increase with more data + regularization |
| **Using leaf-wise growth without `max_leaves`** | Uncontrolled tree size, overfitting | Always set `max_leaves` when using `grow_policy='lossguide'` |

## Related Concepts

- [gradient-boosting.md](gradient-boosting.md) — Overall boosting algorithm
- [regularization.md](regularization.md) — Techniques to control tree complexity
- [training-pipeline.md](../patterns/training-pipeline.md) — Production implementation

## References

- XGBoost Paper: https://arxiv.org/abs/1603.02754
- Tree Methods: https://xgboost.readthedocs.io/en/stable/treemethod.html
- GPU Support: https://xgboost.readthedocs.io/en/stable/gpu/index.html
