# A/B Testing

## Concepts

| Term | Definition |
|---|---|
| **Control** | Existing version (A) |
| **Treatment** | New version (B) |
| **MDE** | Minimum Detectable Effect — smallest effect worth detecting |
| **α** | Type I error rate — false positive (typically 0.05) |
| **β** | Type II error rate — false negative (typically 0.20) |
| **Power (1−β)** | Probability of detecting a true effect (typically 0.80) |
| **SRM** | Sample Ratio Mismatch — unequal assignment |

## Pre-Experiment: Power Analysis

Calculate required sample size **before** running the experiment.

```python
from statsmodels.stats.power import TTestIndPower, NormalIndPower
from statsmodels.stats.proportion import proportion_effectsize

# Continuous metric (e.g., revenue per user)
analysis = TTestIndPower()
n_per_group = analysis.solve_power(
    effect_size=0.3,    # Cohen's d  (small=0.2, medium=0.5, large=0.8)
    alpha=0.05,
    power=0.80,
    alternative='two-sided'
)
print(f"Required n per group: {np.ceil(n_per_group):.0f}")

# Binary metric (e.g., conversion rate)
baseline_rate = 0.10
target_rate = 0.12          # 20% relative lift
effect = proportion_effectsize(baseline_rate, target_rate)

analysis = NormalIndPower()
n_per_group = analysis.solve_power(effect_size=effect, alpha=0.05, power=0.80)
print(f"Required n per group: {np.ceil(n_per_group):.0f}")
```

## Running the Experiment

```python
import pandas as pd
from scipy import stats

# Continuous metric
control = df[df.group == 'control']['revenue']
treatment = df[df.group == 'treatment']['revenue']

t, p = stats.ttest_ind(control, treatment, equal_var=False)
d = (treatment.mean() - control.mean()) / np.sqrt(
    (control.std()**2 + treatment.std()**2) / 2)
lift = (treatment.mean() - control.mean()) / control.mean()

print(f"Control: {control.mean():.4f}, Treatment: {treatment.mean():.4f}")
print(f"Lift: {lift:.1%}, Cohen's d: {d:.3f}, p-value: {p:.4f}")

# Binary metric (conversion)
n_control = len(df[df.group == 'control'])
n_treatment = len(df[df.group == 'treatment'])
conv_control = df[df.group == 'control']['converted'].sum()
conv_treatment = df[df.group == 'treatment']['converted'].sum()

from statsmodels.stats.proportion import proportions_ztest
z, p = proportions_ztest(
    [conv_treatment, conv_control],
    [n_treatment, n_control],
    alternative='two-sided'
)
```

## Sample Ratio Mismatch Check

```python
from scipy.stats import chi2_contingency

expected_ratio = 0.5
n_total = n_control + n_treatment
expected_control = n_total * expected_ratio
expected_treatment = n_total * (1 - expected_ratio)

chi2, p_srm, _, _ = chi2_contingency(
    [[n_control, n_treatment], [expected_control, expected_treatment]]
)
if p_srm < 0.01:
    print("⚠️  WARNING: Sample Ratio Mismatch detected! Investigate assignment.")
```

## Guardrail Metrics

Always test that the experiment didn't harm key metrics alongside the primary metric.

```python
guardrails = {
    "page_load_time": "lower is better",
    "error_rate": "lower is better",
    "session_length": "no degradation",
}
# Run t-tests for each guardrail at α=0.01 (more conservative)
for metric in guardrails:
    _, p = stats.ttest_ind(
        df[df.group=='control'][metric],
        df[df.group=='treatment'][metric],
        equal_var=False
    )
    status = "❌ GUARDRAIL VIOLATED" if p < 0.01 else "✅ OK"
    print(f"{metric}: p={p:.4f} {status}")
```

## Sequential Testing (Early Stopping)

```python
# Use always-valid p-values (mSPRT) to allow peeking
# pip install streamz  or use scipy's sequential_ratio_test
from scipy.stats import spearmanr

# Simpler: Bonferroni correction for planned interim analyses
n_looks = 3
alpha_adjusted = 0.05 / n_looks   # conservative; O'Brien-Fleming is better
```

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Peeking (stopping early) | Sequential testing or pre-commit to fixed horizon |
| Multiple primary metrics | Pre-register one primary metric |
| SRM ignored | Always check SRM before analysis |
| Novelty effect | Run test long enough to capture steady state |
| Network effects (SUTVA violation) | Cluster randomization |
| Carry-over effect | Use washout period or holdout design |
