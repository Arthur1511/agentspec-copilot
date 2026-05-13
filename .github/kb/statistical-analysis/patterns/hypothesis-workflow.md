# Hypothesis Testing Workflow

## Purpose

End-to-end pattern for rigorous hypothesis testing: pre-test assumption checks, test selection, execution, effect size, and reporting.

---

## Step 1 — State Hypotheses (Before Looking at Data)

```python
# Document your hypotheses BEFORE examining results
hypothesis = {
    "H0": "Mean session duration is equal across user segments A and B",
    "Ha": "Mean session duration differs between segments A and B",
    "alpha": 0.05,
    "alternative": "two-sided",
    "metric": "session_duration_seconds",
    "min_effect_size": 0.2,  # Cohen's d — smallest effect worth detecting
}
print(hypothesis)
```

---

## Step 2 — Check Assumptions

```python
import numpy as np
from scipy import stats
import matplotlib.pyplot as plt
import statsmodels.api as sm

def check_assumptions(group_a: np.ndarray, group_b: np.ndarray) -> dict:
    results = {}

    # Normality — Shapiro-Wilk (n < 5000)
    for name, arr in [("group_a", group_a), ("group_b", group_b)]:
        n = len(arr)
        sample = arr[:5000] if n > 5000 else arr
        _, p_norm = stats.shapiro(sample)
        results[f"normality_{name}"] = {"p": p_norm, "normal": p_norm > 0.05}

    # Equal variances — Levene's test
    _, p_var = stats.levene(group_a, group_b)
    results["equal_variances"] = {"p": p_var, "equal": p_var > 0.05}

    # Sample sizes
    results["n_a"], results["n_b"] = len(group_a), len(group_b)

    return results

assumptions = check_assumptions(group_a, group_b)
for k, v in assumptions.items():
    print(f"{k}: {v}")
```

---

## Step 3 — Select and Run Test

```python
def run_two_group_test(group_a: np.ndarray, group_b: np.ndarray,
                       alpha: float = 0.05, alternative: str = "two-sided") -> dict:
    both_normal = (
        stats.shapiro(group_a[:5000])[1] > 0.05 and
        stats.shapiro(group_b[:5000])[1] > 0.05
    )
    n_min = min(len(group_a), len(group_b))

    if both_normal and n_min >= 30:
        # Welch's t-test (does NOT assume equal variances)
        t_stat, p_val = stats.ttest_ind(group_a, group_b,
                                        equal_var=False, alternative=alternative)
        test_name = "Welch's t-test"
        # Cohen's d
        pooled_std = np.sqrt((group_a.std(ddof=1)**2 + group_b.std(ddof=1)**2) / 2)
        effect_size = (group_b.mean() - group_a.mean()) / pooled_std
        effect_label = "Cohen's d"
    else:
        # Mann-Whitney U (non-parametric)
        u_stat, p_val = stats.mannwhitneyu(group_a, group_b, alternative=alternative)
        t_stat = u_stat
        test_name = "Mann-Whitney U"
        # Rank-biserial correlation
        effect_size = 1 - (2 * u_stat) / (len(group_a) * len(group_b))
        effect_label = "rank-biserial r"

    reject = p_val < alpha
    return {
        "test": test_name,
        "statistic": t_stat,
        "p_value": p_val,
        "reject_h0": reject,
        "effect_size": effect_size,
        "effect_label": effect_label,
        "mean_a": group_a.mean(),
        "mean_b": group_b.mean(),
        "delta": group_b.mean() - group_a.mean(),
        "relative_delta": (group_b.mean() - group_a.mean()) / abs(group_a.mean()),
    }

result = run_two_group_test(group_a, group_b, alpha=0.05)
```

---

## Step 4 — Confidence Interval

```python
# Bootstrap CI for the mean difference (non-parametric, works for any statistic)
from scipy.stats import bootstrap

def mean_diff(a, b):
    return a.mean() - b.mean()

res = bootstrap(
    (group_a, group_b),
    statistic=lambda a, b: b.mean() - a.mean(),
    n_resamples=10_000,
    confidence_level=0.95,
    paired=False,
    random_state=42
)
ci = res.confidence_interval
print(f"Bootstrap 95% CI for (B-A): [{ci.low:.3f}, {ci.high:.3f}]")
```

---

## Step 5 — Report Results

```python
def report_result(result: dict, hypothesis: dict) -> str:
    sig = "significant" if result["reject_h0"] else "not significant"
    effect = result["effect_size"]
    magnitude = (
        "large" if abs(effect) >= 0.8 else
        "medium" if abs(effect) >= 0.5 else
        "small" if abs(effect) >= 0.2 else "negligible"
    )
    return (
        f"A {result['test']} showed the difference was {sig} "
        f"(statistic={result['statistic']:.3f}, p={result['p_value']:.4f}, α={hypothesis['alpha']}).\n"
        f"Group B mean ({result['mean_b']:.3f}) vs Group A mean ({result['mean_a']:.3f}), "
        f"Δ={result['delta']:.3f} ({result['relative_delta']:.1%} relative).\n"
        f"Effect size: {result['effect_label']} = {effect:.3f} ({magnitude})."
    )

print(report_result(result, hypothesis))
```

---

## Output Checklist

```
□ Hypotheses stated before analysis
□ Assumptions verified (normality, equal variance)
□ Correct test selected and run
□ Effect size computed and interpreted
□ 95% confidence interval reported
□ Multiple comparisons correction applied (if >1 test)
□ Conclusion stated in plain language
```
