# Correlation and Causation

## Correlation Coefficients

| Coefficient | Measures | Assumption | Use When |
|---|---|---|---|
| Pearson r | Linear relationship | Both vars normal | Continuous, linear |
| Spearman ρ | Monotonic rank | None | Ordinal, non-linear, outliers |
| Kendall τ | Concordant pairs | None | Small n, ties |
| Point-biserial r | Linear (continuous vs binary) | Continuous normal | One binary variable |
| Phi (φ) | Binary–binary | None | Both variables binary |

```python
from scipy import stats

# Pearson (linear, parametric)
r, p = stats.pearsonr(x, y)

# Spearman (monotonic, robust to outliers)
rho, p = stats.spearmanr(x, y)

# Kendall (small n or many ties)
tau, p = stats.kendalltau(x, y)

# Point-biserial
r, p = stats.pointbiserialr(binary_var, continuous_var)
```

## Correlation Matrix

```python
import pandas as pd
import seaborn as sns, matplotlib.pyplot as plt

corr = df.corr(method='pearson')          # or 'spearman'

# Plot heatmap
fig, ax = plt.subplots(figsize=(10, 8))
mask = np.triu(np.ones_like(corr, dtype=bool))  # hide upper triangle
sns.heatmap(corr, mask=mask, annot=True, fmt=".2f",
            cmap="coolwarm", center=0, vmin=-1, vmax=1, ax=ax)
ax.set_title("Feature Correlation Matrix")
```

## Partial Correlation

Correlation between two variables **after removing the effect of confounders**.

```python
import pingouin as pg

# Partial correlation: x–y controlling for z
result = pg.partial_corr(data=df, x='x', y='y', covar='z')
print(result[['r', 'p-val', 'CI95%']])

# Multiple covariates
result = pg.partial_corr(data=df, x='x', y='y', covar=['z1', 'z2'])
```

## Spurious Correlation

Correlation ≠ causation. Common confounding patterns:

```
Type            Example
─────────────── ─────────────────────────────────────────────
Common cause    Ice cream sales & drowning (both caused by heat)
Reverse cause   Hospital visits ↑ with illness (not the other way)
Coincidence     Nicolas Cage films & pool drownings
Mediator        Income → Education → Health (education mediates)
```

## Causal Inference Basics

```python
# 1. Control for confounders via regression
import statsmodels.formula.api as smf

model = smf.ols('y ~ x + confounder1 + confounder2', data=df).fit()
print(model.summary())

# 2. Propensity score matching (observational data)
# pip install causalml
from causalml.match import NearestNeighborMatch
# ... (see causalml docs for full workflow)

# 3. Difference-in-differences (panel data)
# y = α + β1*time + β2*treated + β3*(time*treated) + ε
model = smf.ols('y ~ time * treated', data=df).fit()
att = model.params['time:treated']  # Average Treatment Effect on Treated
```

## Correlation Strength Interpretation

```
|r| range   Interpretation
────────── ─────────────────
0.00–0.09   Negligible
0.10–0.29   Weak
0.30–0.49   Moderate
0.50–0.69   Strong
0.70–1.00   Very strong
```

## VIF — Multicollinearity Detection

```python
from statsmodels.stats.outliers_influence import variance_inflation_factor

vif_data = pd.DataFrame({
    "feature": X.columns,
    "VIF": [variance_inflation_factor(X.values, i) for i in range(X.shape[1])]
})
# VIF > 10 indicates problematic multicollinearity
print(vif_data.sort_values("VIF", ascending=False))
```

## Decision Guide

| Situation | Recommendation |
|---|---|
| Both vars continuous, roughly normal | Pearson r |
| Non-normal, ordinal, or outliers present | Spearman ρ |
| Controlling for a third variable | Partial correlation |
| Checking feature redundancy | VIF or correlation matrix |
| Claiming causation | Requires experimental design (RCT) or causal model |
