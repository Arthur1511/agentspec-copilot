# Hypothesis Testing

## Core Framework

Hypothesis testing evaluates evidence against a null hypothesis (H₀).

```
H₀: no effect / no difference (default assumption)
Hₐ: there is an effect / difference (what you want to show)
α:  significance level (Type I error rate) — typically 0.05
p:  probability of observing data as extreme as seen, assuming H₀ is true
```

**Decision rule:** Reject H₀ when p < α. Never "accept" H₀ — only "fail to reject."

## Test Selection Guide

```
Is the outcome variable continuous or categorical?
├── Continuous
│   ├── 1 group vs constant → One-sample t-test
│   ├── 2 independent groups
│   │   ├── Normal + equal variance → Student's t
│   │   ├── Normal + unequal variance → Welch's t (default)
│   │   └── Non-normal → Mann-Whitney U
│   ├── 2 paired groups
│   │   ├── Normal → Paired t-test
│   │   └── Non-normal → Wilcoxon signed-rank
│   └── 3+ groups
│       ├── Normal → One-way ANOVA → post-hoc Tukey
│       └── Non-normal → Kruskal-Wallis → Dunn test
└── Categorical → Chi-square (or Fisher's exact if n < 5 per cell)
```

## Parametric Tests

```python
from scipy import stats

# Independent t-test (Welch — does NOT assume equal variances)
t, p = stats.ttest_ind(group_a, group_b, equal_var=False)

# Paired t-test
t, p = stats.ttest_rel(before, after)

# One-way ANOVA
f, p = stats.f_oneway(g1, g2, g3)

# Post-hoc Tukey (after significant ANOVA)
from statsmodels.stats.multicomp import pairwise_tukeyhsd
result = pairwise_tukeyhsd(endog=values, groups=labels, alpha=0.05)
print(result.summary())
```

## Non-Parametric Tests

```python
# Mann-Whitney U (two independent samples)
u, p = stats.mannwhitneyu(group_a, group_b, alternative='two-sided')

# Wilcoxon signed-rank (paired, non-normal)
w, p = stats.wilcoxon(before, after, alternative='two-sided')

# Kruskal-Wallis (3+ groups, non-normal)
h, p = stats.kruskal(g1, g2, g3)

# Chi-square (categorical independence)
chi2, p, dof, expected = stats.chi2_contingency(contingency_table)
# Use Fisher's exact for 2×2 with small cells
odds_ratio, p = stats.fisher_exact(table_2x2)
```

## Assumptions Checklist

```python
# 1. Normality — Shapiro-Wilk (n < 5000)
_, p_norm = stats.shapiro(group_a)
print("Normal?" , p_norm > 0.05)

# 2. Equal variances — Levene's test
_, p_var = stats.levene(group_a, group_b)
print("Equal variances?", p_var > 0.05)

# 3. Independence — by design (no statistical test)

# 4. Outliers — IQR method
q1, q3 = np.percentile(arr, [25, 75])
iqr = q3 - q1
outliers = arr[(arr < q1 - 1.5*iqr) | (arr > q3 + 1.5*iqr)]
```

## Effect Sizes

Report effect size alongside p-value — p only tells you significance, not magnitude.

```python
import numpy as np

# Cohen's d (two groups, continuous)
def cohens_d(a, b):
    pooled_std = np.sqrt((np.var(a, ddof=1) + np.var(b, ddof=1)) / 2)
    return (b.mean() - a.mean()) / pooled_std
# Interpretation: 0.2=small, 0.5=medium, 0.8=large

# Rank-biserial r (Mann-Whitney)
n1, n2 = len(a), len(b)
r = 1 - (2 * u_stat) / (n1 * n2)

# Cramér's V (chi-square)
v = np.sqrt(chi2_stat / (n * (min(n_rows, n_cols) - 1)))
# Interpretation: 0.1=small, 0.3=medium, 0.5=large
```

## Pitfalls

| Pitfall | Consequence | Fix |
|---------|------------|-----|
| p-hacking / HARKing | Inflated false positives | Pre-register hypotheses |
| Not checking assumptions | Invalid test | Always run assumption checks |
| Reporting p without effect size | Misleading significance | Always report d, r, or V |
| Multiple comparisons without correction | Family-wise error inflation | Use Bonferroni or BH correction |
| One-tailed test without prior justification | Bias | Default to two-tailed |
