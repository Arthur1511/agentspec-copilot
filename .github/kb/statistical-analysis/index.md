# Statistical Analysis Knowledge Base

> **MCP Validated:** 2026-05-08

## Purpose

Complete reference for **statistical analysis** in data science — probability distributions, hypothesis testing, A/B testing, confidence intervals, and correlation analysis using Python (`scipy`, `statsmodels`, `pingouin`).

## Domain Overview

Statistical analysis provides the mathematical foundation for making evidence-based decisions from data. Covers classical frequentist inference, effect size reporting, and experiment design for production A/B tests.

**Key Capabilities:**
- Probability distribution fitting and simulation
- Parametric and non-parametric hypothesis testing
- A/B test design (power, sample size, significance)
- Confidence intervals and bootstrap estimation
- Correlation and partial correlation analysis
- Multiple comparisons correction

## Key Concepts

| Concept | Description | File |
|---------|-------------|------|
| **Distributions** | Common distributions, fitting, simulation, QQ-plots | [distributions.md](concepts/distributions.md) |
| **Hypothesis Testing** | t-tests, ANOVA, chi-square, non-parametric alternatives | [hypothesis-testing.md](concepts/hypothesis-testing.md) |
| **Correlation & Causation** | Pearson, Spearman, partial correlation, confounders | [correlation-causation.md](concepts/correlation-causation.md) |
| **A/B Testing** | Power analysis, sequential testing, MDE, error rates | [ab-testing.md](concepts/ab-testing.md) |

## Patterns

| Pattern | Use Case | File |
|---------|----------|------|
| **Exploratory Stats** | Descriptive statistics, distribution diagnostics, outlier detection | [exploratory-stats.md](patterns/exploratory-stats.md) |
| **Hypothesis Workflow** | End-to-end testing from assumption check to conclusion | [hypothesis-workflow.md](patterns/hypothesis-workflow.md) |
| **A/B Test Design** | Pre-experiment power analysis and post-experiment analysis | [ab-test-design.md](patterns/ab-test-design.md) |
| **Reporting Stats** | APA-style reporting, effect sizes, CI tables | [reporting-stats.md](patterns/reporting-stats.md) |

## Learning Path

### Beginner
1. Read [distributions.md](concepts/distributions.md) — understand common distributions
2. Study [exploratory-stats.md](patterns/exploratory-stats.md) — describe your data
3. Review [quick-reference.md](quick-reference.md) — key functions at a glance

### Intermediate
4. Learn [hypothesis-testing.md](concepts/hypothesis-testing.md) — choose the right test
5. Apply [hypothesis-workflow.md](patterns/hypothesis-workflow.md) — end-to-end testing
6. Study [correlation-causation.md](concepts/correlation-causation.md) — avoid confounding

### Advanced
7. Master [ab-testing.md](concepts/ab-testing.md) — experiment design theory
8. Implement [ab-test-design.md](patterns/ab-test-design.md) — production A/B tests
9. Apply [reporting-stats.md](patterns/reporting-stats.md) — communicate results

## Agent Usage

**Target Agents:**
- `ds-statistician` — primary consumer; hypothesis testing and A/B test design
- `ds-eda-analyst` — exploratory statistics, distribution diagnostics
- `ds-model-evaluator` — statistical significance of model comparisons

**Common Tasks:**
- Test whether group means differ: use `hypothesis-workflow.md`
- Design an A/B test: use `ab-test-design.md`
- Report results with effect sizes: use `reporting-stats.md`
- Check normality assumption: use `distributions.md`

## Quick Start

```python
import numpy as np
from scipy import stats

# Descriptive statistics + 95% CI
data = np.array([12.5, 13.1, 11.8, 14.2, 12.9, 13.7])
ci = stats.t.interval(0.95, df=len(data)-1, loc=data.mean(), scale=stats.sem(data))
print(f"Mean: {data.mean():.2f} ± {data.std(ddof=1):.2f}, 95% CI: {ci}")

# Two-sample t-test with Cohen's d
group_a = np.random.normal(10, 2, 100)
group_b = np.random.normal(10.5, 2, 100)
t_stat, p_val = stats.ttest_ind(group_a, group_b)
pooled_std = np.sqrt((group_a.std()**2 + group_b.std()**2) / 2)
cohens_d = (group_b.mean() - group_a.mean()) / pooled_std
print(f"t={t_stat:.3f}, p={p_val:.4f}, d={cohens_d:.3f}")
```

## Related Domains

- **pandas** — data manipulation before statistical analysis
- **scikit-learn** — ML models that consume statistical features
- **data-visualization** — visualizing distributions and test results
- **xgboost** — advanced modeling after statistical feature analysis

## References

- SciPy Stats: https://docs.scipy.org/doc/scipy/reference/stats.html
- Statsmodels: https://www.statsmodels.org/
- Pingouin: https://pingouin-stats.org/
- "Statistics Done Wrong" — Alex Reinhart
