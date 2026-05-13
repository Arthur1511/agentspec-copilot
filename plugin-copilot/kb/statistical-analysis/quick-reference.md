# Statistical Analysis — Quick Reference

## Descriptive Statistics

```python
import numpy as np
from scipy import stats

arr = df["col"].dropna().values
mean, median, std = arr.mean(), np.median(arr), arr.std(ddof=1)
skew, kurt = stats.skew(arr), stats.kurtosis(arr)   # excess kurtosis
ci_95 = stats.t.interval(0.95, df=len(arr)-1, loc=mean, scale=stats.sem(arr))
iqr = stats.iqr(arr)
```

## Normality Tests

| Test | When | Code |
|------|------|------|
| Shapiro-Wilk | n < 5000 | `stats.shapiro(arr)` |
| D'Agostino-K² | n ≥ 20 | `stats.normaltest(arr)` |
| Kolmogorov-Smirnov | Any | `stats.kstest(arr, 'norm', args=(mean, std))` |
| QQ-plot (visual) | Always | `sm.qqplot(arr, line='s')` |

> Rule: p < 0.05 → reject normality. Always combine with visual inspection.

## Parametric Tests

| Test | Use Case | Code |
|------|---------|------|
| One-sample t | Mean vs constant | `stats.ttest_1samp(arr, popmean)` |
| Independent t | Two groups | `stats.ttest_ind(a, b, equal_var=False)` |
| Paired t | Before/after | `stats.ttest_rel(before, after)` |
| One-way ANOVA | 3+ groups | `stats.f_oneway(g1, g2, g3)` |
| Two-way ANOVA | 2 factors | `sm.stats.anova_lm(model, typ=2)` |

## Non-Parametric Tests

| Test | Parametric Equivalent | Code |
|------|----------------------|------|
| Mann-Whitney U | Independent t | `stats.mannwhitneyu(a, b, alternative='two-sided')` |
| Wilcoxon signed-rank | Paired t | `stats.wilcoxon(before, after)` |
| Kruskal-Wallis | One-way ANOVA | `stats.kruskal(g1, g2, g3)` |
| Chi-square | Categorical | `stats.chi2_contingency(contingency_table)` |
| Fisher's exact | Small samples | `stats.fisher_exact(2x2_table)` |

## Effect Sizes

```python
# Cohen's d (two groups)
d = (b.mean() - a.mean()) / np.sqrt((a.std()**2 + b.std()**2) / 2)
# Interpretation: small=0.2, medium=0.5, large=0.8

# Eta-squared (ANOVA)
# eta2 = SS_between / SS_total   (from statsmodels anova_lm)

# Cramér's V (chi-square)
n = contingency.sum()
v = np.sqrt(chi2 / (n * (min(r, c) - 1)))
```

## Confidence Intervals

```python
# Parametric CI
ci = stats.t.interval(0.95, df=n-1, loc=mean, scale=stats.sem(arr))

# Bootstrap CI (non-parametric)
from scipy.stats import bootstrap
res = bootstrap((arr,), np.mean, confidence_level=0.95, n_resamples=10000)
ci = res.confidence_interval  # .low, .high

# Proportion CI (Wilson)
from statsmodels.stats.proportion import proportion_confint
ci = proportion_confint(successes, total, alpha=0.05, method='wilson')
```

## Multiple Comparisons

```python
from statsmodels.stats.multitest import multipletests

p_values = [0.01, 0.04, 0.03, 0.12, 0.08]
reject, p_adj, _, _ = multipletests(p_values, method='fdr_bh')  # Benjamini-Hochberg
# Also: 'bonferroni', 'holm', 'fdr_by'
```

## Correlation

```python
# Pearson (linear, normal)
r, p = stats.pearsonr(x, y)

# Spearman (monotonic, non-normal)
rho, p = stats.spearmanr(x, y)

# Kendall (small samples, ordinal)
tau, p = stats.kendalltau(x, y)

# Point-biserial (continuous vs binary)
r, p = stats.pointbiserialr(binary, continuous)
```

## Power Analysis

```python
from statsmodels.stats.power import TTestIndPower

analysis = TTestIndPower()
# Required sample size
n = analysis.solve_power(effect_size=0.5, alpha=0.05, power=0.80)

# Achieved power
power = analysis.solve_power(effect_size=0.5, nobs1=50, alpha=0.05)
```
