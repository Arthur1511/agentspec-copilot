# Feature Importance

> **MCP Validated:** 2026-04-17

## Overview

**Feature importance** quantifies the contribution of each feature to the model's predictions. XGBoost provides multiple importance metrics and integrates with SHAP for advanced interpretability.

## Importance Types

### 1. Weight (Split Count)

**Definition**: Number of times a feature is used to split data across all trees.

**Formula**:
```
weight(f) = Σ(1 if feature f is used for split in tree t)
```

**Interpretation**:
- Higher weight → feature used more frequently
- **Does not consider split quality** (gain)
- Can be misleading if splits provide little improvement

**When to use**: Quick overview of feature usage frequency

### 2. Gain (Average Gain)

**Definition**: Average gain of splits using this feature.

**Formula**:
```
gain(f) = (1/n_splits) · Σ(gain of splits using feature f)
```

**Interpretation**:
- Higher gain → feature provides more predictive power
- **Recommended default** — considers split quality
- Measures actual contribution to loss reduction

**When to use**: Understanding which features improve model most

### 3. Cover (Average Coverage)

**Definition**: Average number of samples affected by splits using this feature.

**Formula**:
```
cover(f) = (1/n_splits) · Σ(number of samples in splits using feature f)
```

**Interpretation**:
- Higher cover → feature affects more samples
- Useful for understanding feature breadth vs depth

**When to use**: Identifying features that impact large portions of data

### 4. Total Gain

**Definition**: Total gain from all splits using this feature.

**Formula**:
```
total_gain(f) = Σ(gain of splits using feature f)
```

**Interpretation**:
- Similar to `gain` but not normalized
- Can be dominated by features with many splits

### 5. Total Cover

**Definition**: Total number of samples affected by splits using this feature.

**Formula**:
```
total_cover(f) = Σ(number of samples in splits using feature f)
```

## Extracting Importance

### Method 1: `feature_importances_` Attribute (sklearn API)

```python
import xgboost as xgb
from sklearn.datasets import load_breast_cancer

X, y = load_breast_cancer(return_X_y=True)
feature_names = load_breast_cancer().feature_names

model = xgb.XGBClassifier(n_estimators=100, max_depth=5, random_state=42)
model.fit(X, y)

# Default importance type: 'weight' (split count)
importances = model.feature_importances_
feature_importance_dict = dict(zip(feature_names, importances))

# Sort by importance
sorted_features = sorted(feature_importance_dict.items(), key=lambda x: x[1], reverse=True)

print("Top 10 Features (by split count):")
for feature, importance in sorted_features[:10]:
    print(f"{feature:30s}: {importance:.4f}")
```

### Method 2: `get_score()` Method (native API)

```python
# Access native booster
booster = model.get_booster()

# Get importance with different metrics
importance_weight = booster.get_score(importance_type='weight')
importance_gain = booster.get_score(importance_type='gain')
importance_cover = booster.get_score(importance_type='cover')
importance_total_gain = booster.get_score(importance_type='total_gain')
importance_total_cover = booster.get_score(importance_type='total_cover')

print("\nTop 5 Features by Gain:")
sorted_gain = sorted(importance_gain.items(), key=lambda x: x[1], reverse=True)
for feature, gain in sorted_gain[:5]:
    print(f"  {feature:30s}: {gain:.2f}")
```

### Method 3: `plot_importance()` Visualization

```python
import matplotlib.pyplot as plt

# Plot top 15 features by gain
fig, ax = plt.subplots(figsize=(10, 8))
xgb.plot_importance(
    model,
    importance_type='gain',
    max_num_features=15,
    ax=ax,
    title='Feature Importance (Gain)'
)
plt.tight_layout()
plt.show()
```

## SHAP Integration

**SHAP (SHapley Additive exPlanations)** provides more sophisticated feature importance based on game theory.

### Global SHAP Importance

```python
import shap

# Create explainer
explainer = shap.TreeExplainer(model)
shap_values = explainer.shap_values(X)

# Summary plot (global importance)
shap.summary_plot(shap_values, X, feature_names=feature_names, show=False)
plt.tight_layout()
plt.show()

# Bar plot (mean absolute SHAP values)
shap.summary_plot(shap_values, X, feature_names=feature_names, plot_type='bar', show=False)
plt.tight_layout()
plt.show()
```

### Local Explanation (Single Prediction)

```python
# Explain a single prediction
sample_idx = 0
shap.force_plot(
    explainer.expected_value,
    shap_values[sample_idx],
    X[sample_idx],
    feature_names=feature_names,
    matplotlib=True,
    show=False
)
plt.tight_layout()
plt.show()

# Waterfall plot (alternative visualization)
shap.waterfall_plot(
    shap.Explanation(
        values=shap_values[sample_idx],
        base_values=explainer.expected_value,
        data=X[sample_idx],
        feature_names=feature_names
    )
)
```

## Comparing Importance Metrics

```python
import pandas as pd

# Extract all importance types
booster = model.get_booster()
importance_types = ['weight', 'gain', 'cover', 'total_gain', 'total_cover']

importance_df = pd.DataFrame()
for imp_type in importance_types:
    scores = booster.get_score(importance_type=imp_type)
    importance_df[imp_type] = pd.Series(scores)

importance_df = importance_df.fillna(0).sort_values('gain', ascending=False)

print(importance_df.head(10))
```

**Expected output**:
```
                    weight    gain     cover  total_gain  total_cover
worst concave points  45.0  1250.32  1823.45   56264.40    81955.25
worst perimeter       38.0  1102.88  1654.32   41909.44    62864.16
worst radius          42.0   985.67  1432.11   41398.14    60148.62
...
```

**Insight**: Features with high `weight` but low `gain` are used frequently but don't improve predictions much (candidates for removal).

## Feature Selection Based on Importance

```python
from sklearn.feature_selection import SelectFromModel

# Select features with importance > threshold
selector = SelectFromModel(
    model,
    threshold='median',     # Keep features above median importance
    prefit=True
)

X_selected = selector.transform(X)
selected_features = feature_names[selector.get_support()]

print(f"Original features: {X.shape[1]}")
print(f"Selected features: {X_selected.shape[1]}")
print(f"Selected feature names: {selected_features}")

# Retrain on selected features
model_selected = xgb.XGBClassifier(n_estimators=100, max_depth=5, random_state=42)
model_selected.fit(X_selected, y)
print(f"Original score: {model.score(X, y):.4f}")
print(f"Selected score: {model_selected.score(X_selected, y):.4f}")
```

## Common Mistakes

| Mistake | Why It's Wrong | Correct Approach |
|---------|----------------|------------------|
| **Using `weight` importance only** | Ignores actual gain; misleading for feature selection | Use `gain` or `total_gain` by default |
| **Not normalizing SHAP values** | Absolute SHAP values depend on scale | Use mean absolute SHAP for comparison |
| **Interpreting correlation as causation** | Importance shows predictive power, not causality | Be cautious with causal claims |
| **Ignoring feature interactions** | Single feature importance misses interactions | Use SHAP interaction plots |
| **Comparing importance across models** | Different models, data splits have different scales | Only compare within same model |

## Permutation Importance (Alternative)

Model-agnostic importance via random shuffling:

```python
from sklearn.inspection import permutation_importance

# Compute permutation importance
perm_importance = permutation_importance(
    model, X, y,
    n_repeats=10,
    random_state=42
)

# Sort by mean importance
sorted_idx = perm_importance.importances_mean.argsort()[::-1]

print("Top 10 Features (Permutation Importance):")
for idx in sorted_idx[:10]:
    print(f"{feature_names[idx]:30s}: "
          f"{perm_importance.importances_mean[idx]:.4f} "
          f"± {perm_importance.importances_std[idx]:.4f}")
```

**Advantage**: More reliable for feature selection (based on actual prediction degradation)
**Disadvantage**: Slower (requires rerunning predictions)

## Related Patterns

- [training-pipeline.md](../patterns/training-pipeline.md) — Integrating feature importance into pipelines
- [regularization.md](regularization.md) — Using L1 regularization for automatic feature selection
- [gradient-boosting.md](gradient-boosting.md) — How features contribute to gradient boosting

## References

- XGBoost Feature Importance: https://xgboost.readthedocs.io/en/stable/python/python_api.html#xgboost.Booster.get_score
- SHAP Library: https://shap.readthedocs.io/
- Lundberg & Lee (2017): "A Unified Approach to Interpreting Model Predictions"
