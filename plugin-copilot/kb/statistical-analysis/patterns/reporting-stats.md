# Reporting Statistics Pattern

## Purpose

Generate APA-style statistical reports with effect sizes, confidence intervals, and plain-language summaries suitable for stakeholder communication.

---

## APA Reporting Format

```python
def format_apa_ttest(t: float, df: float, p: float, d: float, ci: tuple) -> str:
    """Format t-test result in APA style."""
    p_str = "< .001" if p < 0.001 else f"= {p:.3f}"
    return (
        f"t({df:.0f}) = {t:.2f}, p {p_str}, "
        f"Cohen's d = {d:.2f}, 95% CI [{ci[0]:.2f}, {ci[1]:.2f}]"
    )

def format_apa_anova(f: float, df1: int, df2: int, p: float, eta2: float) -> str:
    p_str = "< .001" if p < 0.001 else f"= {p:.3f}"
    return f"F({df1}, {df2}) = {f:.2f}, p {p_str}, η² = {eta2:.3f}"

def format_apa_chisq(chi2: float, df: int, p: float, v: float, n: int) -> str:
    p_str = "< .001" if p < 0.001 else f"= {p:.3f}"
    return f"χ²({df}, N = {n}) = {chi2:.2f}, p {p_str}, Cramér's V = {v:.3f}"
```

---

## Comprehensive Results Table

```python
import pandas as pd
import numpy as np
from scipy import stats

def build_results_table(groups: dict[str, np.ndarray]) -> pd.DataFrame:
    """
    groups: {"Group A": arr_a, "Group B": arr_b, ...}
    Returns descriptive stats + pairwise comparisons.
    """
    rows = []
    for name, arr in groups.items():
        ci = stats.t.interval(0.95, df=len(arr)-1,
                              loc=arr.mean(), scale=stats.sem(arr))
        rows.append({
            "Group": name,
            "n": len(arr),
            "Mean": f"{arr.mean():.3f}",
            "SD": f"{arr.std(ddof=1):.3f}",
            "Median": f"{np.median(arr):.3f}",
            "95% CI": f"[{ci[0]:.3f}, {ci[1]:.3f}]",
        })
    return pd.DataFrame(rows).set_index("Group")

table = build_results_table({"Control": group_a, "Treatment": group_b})
print(table.to_markdown())
```

---

## Effect Size Summary

```python
EFFECT_BENCHMARKS = {
    "cohens_d":    [(0.2, "small"), (0.5, "medium"), (0.8, "large")],
    "eta_squared": [(0.01, "small"), (0.06, "medium"), (0.14, "large")],
    "cramers_v":   [(0.1, "small"), (0.3, "medium"), (0.5, "large")],
    "r":           [(0.1, "small"), (0.3, "medium"), (0.5, "large")],
}

def interpret_effect(value: float, metric: str = "cohens_d") -> str:
    benchmarks = EFFECT_BENCHMARKS[metric]
    label = "negligible"
    for threshold, magnitude in benchmarks:
        if abs(value) >= threshold:
            label = magnitude
    return f"{value:.3f} ({label})"

print("Effect size:", interpret_effect(0.45, "cohens_d"))
```

---

## Visual Summary Panel

```python
import matplotlib.pyplot as plt
import seaborn as sns

def plot_group_comparison(group_a: np.ndarray, group_b: np.ndarray,
                          labels: tuple = ("Control", "Treatment"),
                          metric_name: str = "Metric") -> plt.Figure:
    fig, axes = plt.subplots(1, 3, figsize=(15, 4))

    # Panel 1: Distribution
    for arr, label, color in zip([group_a, group_b], labels, ["#4C72B0", "#DD8452"]):
        sns.kdeplot(arr, ax=axes[0], label=label, fill=True, alpha=0.4, color=color)
    axes[0].set(title="Distribution", xlabel=metric_name)
    axes[0].legend()

    # Panel 2: Box plot
    import pandas as pd
    plot_df = pd.DataFrame({
        metric_name: np.concatenate([group_a, group_b]),
        "Group": [labels[0]] * len(group_a) + [labels[1]] * len(group_b),
    })
    sns.boxplot(data=plot_df, x="Group", y=metric_name, ax=axes[1],
                palette={"Control": "#4C72B0", "Treatment": "#DD8452"})
    axes[1].set_title("Box Plot")

    # Panel 3: Mean + CI
    means = [group_a.mean(), group_b.mean()]
    cis = [
        stats.t.interval(0.95, df=len(g)-1, loc=g.mean(), scale=stats.sem(g))
        for g in [group_a, group_b]
    ]
    errors = [[m - ci[0] for m, ci in zip(means, cis)],
              [ci[1] - m for m, ci in zip(means, cis)]]
    axes[2].bar(labels, means, yerr=errors, capsize=8,
                color=["#4C72B0", "#DD8452"], alpha=0.8, edgecolor="white")
    axes[2].set(title="Mean ± 95% CI", ylabel=metric_name)

    plt.tight_layout()
    return fig
```

---

## Plain-Language Summary Template

```python
def plain_language_summary(result: dict) -> str:
    direction = "higher" if result["delta"] > 0 else "lower"
    significance = (
        f"This difference is statistically significant (p = {result['p_value']:.4f})."
        if result["significant"]
        else f"This difference is NOT statistically significant (p = {result['p_value']:.4f})."
    )
    return (
        f"The treatment group showed a {abs(result['relative_delta']):.1%} {direction} "
        f"{result['metric']} compared to control "
        f"({result['trt_mean']:.3f} vs {result['ctrl_mean']:.3f}). "
        f"{significance} "
        f"Effect size: {result.get('cohens_d', result.get('relative_lift', 0)):.3f}."
    )
```

---

## Output Checklist

```
□ APA-formatted test result string
□ Descriptive stats table (n, mean, SD, median, 95% CI) per group
□ Effect size computed and magnitude labeled
□ Visual comparison panel (distribution + box + mean/CI)
□ Plain-language summary for non-technical stakeholders
□ Multiple comparisons correction noted if applicable
```
