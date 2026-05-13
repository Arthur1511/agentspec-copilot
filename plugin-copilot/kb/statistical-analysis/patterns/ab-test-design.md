# A/B Test Design Pattern

## Purpose

End-to-end template for designing, running, and analyzing a production A/B test — from power analysis through decision and guardrail checks.

---

## Phase 1 — Pre-Experiment Design

```python
import numpy as np
from statsmodels.stats.power import TTestIndPower, NormalIndPower
from statsmodels.stats.proportion import proportion_effectsize

# ── Experiment Spec ──────────────────────────────────────────────────
spec = {
    "metric_type": "binary",       # 'binary' | 'continuous'
    "baseline_value": 0.10,        # baseline conversion rate or mean
    "mde_relative": 0.15,          # 15% relative lift we want to detect
    "alpha": 0.05,
    "power": 0.80,
    "n_variants": 2,               # control + 1 treatment
    "traffic_per_day": 5_000,      # daily eligible users
    "allocation": 0.50,            # fraction assigned to treatment
}

# ── Sample Size Calculation ──────────────────────────────────────────
if spec["metric_type"] == "binary":
    target = spec["baseline_value"] * (1 + spec["mde_relative"])
    effect = proportion_effectsize(spec["baseline_value"], target)
    analysis = NormalIndPower()
else:
    # For continuous, user must supply Cohen's d estimate
    effect = spec.get("cohens_d", 0.3)
    analysis = TTestIndPower()

n_per_group = int(np.ceil(analysis.solve_power(
    effect_size=effect, alpha=spec["alpha"], power=spec["power"]
)))
n_total = n_per_group * spec["n_variants"]
runtime_days = int(np.ceil(n_total / spec["traffic_per_day"]))

print(f"Required n per group: {n_per_group:,}")
print(f"Total users needed:   {n_total:,}")
print(f"Estimated runtime:    {runtime_days} days")
print(f"Effect size:          {effect:.4f}")
```

---

## Phase 2 — Assignment Validation (SRM Check)

```python
from scipy.stats import chi2_contingency

def check_srm(n_control: int, n_treatment: int, expected_split: float = 0.5) -> dict:
    n_total = n_control + n_treatment
    expected_ctrl = n_total * expected_split
    expected_trt = n_total * (1 - expected_split)
    chi2, p, _, _ = chi2_contingency(
        [[n_control, n_treatment], [expected_ctrl, expected_trt]]
    )
    return {
        "n_control": n_control,
        "n_treatment": n_treatment,
        "actual_split": n_treatment / n_total,
        "chi2": chi2,
        "p_srm": p,
        "srm_detected": p < 0.01,
    }

srm = check_srm(n_control, n_treatment, expected_split=0.5)
if srm["srm_detected"]:
    raise RuntimeError(f"⚠️ SRM detected (p={srm['p_srm']:.4f}). "
                       "Investigate assignment mechanism before proceeding.")
```

---

## Phase 3 — Primary Metric Analysis

```python
from scipy import stats
import pandas as pd

def analyze_ab_test(
    df: pd.DataFrame,
    metric: str,
    group_col: str = "variant",
    control_label: str = "control",
    treatment_label: str = "treatment",
    metric_type: str = "continuous",   # 'continuous' | 'binary'
    alpha: float = 0.05,
) -> dict:

    ctrl = df[df[group_col] == control_label][metric]
    trt  = df[df[group_col] == treatment_label][metric]

    if metric_type == "binary":
        from statsmodels.stats.proportion import proportions_ztest
        count = [trt.sum(), ctrl.sum()]
        nobs  = [len(trt), len(ctrl)]
        stat, p_val = proportions_ztest(count, nobs, alternative="two-sided")
        effect_label, effect = "relative_lift", (trt.mean() - ctrl.mean()) / ctrl.mean()
    else:
        stat, p_val = stats.ttest_ind(ctrl, trt, equal_var=False)
        pooled = np.sqrt((ctrl.std(ddof=1)**2 + trt.std(ddof=1)**2) / 2)
        effect_label, effect = "cohens_d", (trt.mean() - ctrl.mean()) / pooled

    return {
        "metric": metric,
        "ctrl_mean": ctrl.mean(),
        "trt_mean": trt.mean(),
        "delta": trt.mean() - ctrl.mean(),
        "relative_delta": (trt.mean() - ctrl.mean()) / ctrl.mean(),
        "statistic": stat,
        "p_value": p_val,
        "significant": p_val < alpha,
        effect_label: effect,
        "n_ctrl": len(ctrl),
        "n_trt": len(trt),
    }

result = analyze_ab_test(df, metric="converted", metric_type="binary")
print(pd.Series(result).to_string())
```

---

## Phase 4 — Guardrail Check

```python
def check_guardrails(df, guardrail_metrics: list[str], alpha: float = 0.01) -> pd.DataFrame:
    rows = []
    for metric in guardrail_metrics:
        res = analyze_ab_test(df, metric=metric, metric_type="continuous", alpha=alpha)
        rows.append({
            "metric": metric,
            "delta_%": f"{res['relative_delta']:.1%}",
            "p_value": res["p_value"],
            "violated": res["significant"],
        })
    return pd.DataFrame(rows)

guardrails = check_guardrails(df, ["page_load_ms", "error_rate", "bounce_rate"])
print(guardrails.to_string())
if guardrails["violated"].any():
    print("⚠️  Guardrail metrics violated — do not ship without investigation.")
```

---

## Phase 5 — Decision

```python
def decision(primary: dict, guardrails: pd.DataFrame) -> str:
    if guardrails["violated"].any():
        return "❌ DO NOT SHIP — guardrail violated"
    if primary["significant"] and primary.get("relative_delta", 0) > 0:
        return "✅ SHIP — statistically significant positive effect, guardrails clean"
    if primary["significant"] and primary.get("relative_delta", 0) < 0:
        return "❌ DO NOT SHIP — significant negative effect on primary metric"
    return "⏳ INCONCLUSIVE — extend runtime or accept null hypothesis"

print(decision(result, guardrails))
```
