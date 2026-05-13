# Exploratory Statistics Pattern

## Purpose

Systematically characterize a dataset before modeling: descriptive stats, distribution shape, outlier detection, and correlation screening.

---

## Step 1 — Univariate Summary

```python
import pandas as pd
import numpy as np
from scipy import stats

def univariate_summary(df: pd.DataFrame) -> pd.DataFrame:
    """Descriptive stats + distribution shape for every numeric column."""
    rows = []
    for col in df.select_dtypes("number").columns:
        arr = df[col].dropna().values
        n, n_missing = len(arr), df[col].isna().sum()
        _, p_shapiro = stats.shapiro(arr[:5000]) if n >= 8 else (None, None)
        rows.append({
            "column": col,
            "n": n,
            "missing_%": f"{100 * n_missing / len(df):.1f}%",
            "mean": arr.mean(),
            "std": arr.std(ddof=1),
            "min": arr.min(),
            "p25": np.percentile(arr, 25),
            "median": np.median(arr),
            "p75": np.percentile(arr, 75),
            "max": arr.max(),
            "skew": stats.skew(arr),
            "kurtosis": stats.kurtosis(arr),
            "normal?": "yes" if (p_shapiro and p_shapiro > 0.05) else "no",
        })
    return pd.DataFrame(rows).set_index("column")

summary = univariate_summary(df)
print(summary.to_string())
```

---

## Step 2 — Categorical Summary

```python
def categorical_summary(df: pd.DataFrame) -> pd.DataFrame:
    rows = []
    for col in df.select_dtypes(["object", "category", "bool"]).columns:
        vc = df[col].value_counts(normalize=True)
        rows.append({
            "column": col,
            "n_unique": df[col].nunique(),
            "missing_%": f"{100 * df[col].isna().mean():.1f}%",
            "top_value": vc.index[0],
            "top_freq": f"{vc.iloc[0]:.1%}",
            "entropy": stats.entropy(vc.values),
        })
    return pd.DataFrame(rows).set_index("column")
```

---

## Step 3 — Outlier Detection

```python
from scipy import stats as sp

def flag_outliers(df: pd.DataFrame, method: str = "iqr") -> pd.DataFrame:
    """Returns outlier flags; method='iqr' or 'zscore'."""
    outlier_df = pd.DataFrame(False, index=df.index, columns=df.select_dtypes("number").columns)
    for col in outlier_df.columns:
        arr = df[col].fillna(df[col].median())
        if method == "iqr":
            q1, q3 = arr.quantile([0.25, 0.75])
            iqr = q3 - q1
            outlier_df[col] = (arr < q1 - 1.5 * iqr) | (arr > q3 + 1.5 * iqr)
        elif method == "zscore":
            outlier_df[col] = np.abs(sp.zscore(arr)) > 3
    outlier_df["n_outlier_features"] = outlier_df.sum(axis=1)
    return outlier_df

flags = flag_outliers(df, method="iqr")
print(f"Rows with ≥1 outlier feature: {(flags.n_outlier_features > 0).sum()}")
```

---

## Step 4 — Correlation Screening

```python
def correlation_screen(df: pd.DataFrame, method: str = "spearman",
                       threshold: float = 0.7) -> pd.DataFrame:
    """Returns high-correlation pairs."""
    corr = df.select_dtypes("number").corr(method=method).abs()
    upper = corr.where(np.triu(np.ones(corr.shape), k=1).astype(bool))
    pairs = (
        upper.stack()
        .reset_index()
        .rename(columns={"level_0": "feature_1", "level_1": "feature_2", 0: "corr"})
        .query("corr >= @threshold")
        .sort_values("corr", ascending=False)
    )
    return pairs

high_corr = correlation_screen(df, threshold=0.80)
print(f"High-correlation pairs (|r| ≥ 0.80):\n{high_corr}")
```

---

## Step 5 — Target Relationship (Supervised EDA)

```python
import matplotlib.pyplot as plt
import seaborn as sns

target = "y"
features = df.select_dtypes("number").columns.drop(target)

def target_correlation_bar(df, target, features):
    corrs = df[features].corrwith(df[target], method="spearman").sort_values(key=abs, ascending=False)
    fig, ax = plt.subplots(figsize=(8, max(4, len(corrs) * 0.3)))
    colors = ["steelblue" if v > 0 else "tomato" for v in corrs.values]
    ax.barh(corrs.index, corrs.values, color=colors)
    ax.axvline(0, color="black", lw=0.8)
    ax.set(xlabel="Spearman ρ", title=f"Feature–Target Correlation ({target})")
    plt.tight_layout()
    return fig

target_correlation_bar(df, target, features)
```

---

## Output Checklist

```
□ Univariate summary table saved / printed
□ Categorical summary table saved / printed
□ Outlier flag counts reviewed
□ High-correlation pairs identified → candidates for removal
□ Feature–target correlation bar chart created
□ Key findings written in analysis notes
```
