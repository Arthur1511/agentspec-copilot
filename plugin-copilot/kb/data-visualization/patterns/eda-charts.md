# EDA Charts Pattern

## Purpose

Standard visualization panel for exploratory data analysis: univariate distributions, bivariate relationships, correlation matrix, and target analysis.

---

## Setup

```python
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import pandas as pd

sns.set_theme(style="whitegrid", palette="husl", font_scale=1.1)
FIGSIZE_FULL = (16, 5)
FIGSIZE_HALF = (8, 5)
```

---

## Panel 1 — Univariate Distribution Dashboard

```python
def plot_distribution_dashboard(df: pd.DataFrame,
                                 columns: list[str] | None = None,
                                 ncols: int = 4) -> plt.Figure:
    """Histogram + KDE for every numeric column."""
    if columns is None:
        columns = df.select_dtypes("number").columns.tolist()
    nrows = int(np.ceil(len(columns) / ncols))
    fig, axes = plt.subplots(nrows, ncols,
                              figsize=(ncols * 4, nrows * 3),
                              constrained_layout=True)
    axes = axes.flat if nrows > 1 else [axes] if len(columns) == 1 else axes.flat

    for ax, col in zip(axes, columns):
        arr = df[col].dropna()
        sns.histplot(arr, kde=True, ax=ax, color="steelblue", alpha=0.6)
        ax.set(title=col, xlabel="", ylabel="")
        # Annotate mean and median
        ax.axvline(arr.mean(), color="red", ls="--", lw=1, label=f"mean={arr.mean():.2f}")
        ax.axvline(arr.median(), color="green", ls=":", lw=1, label=f"med={arr.median():.2f}")
        ax.legend(fontsize=7, frameon=False)

    for ax in list(axes)[len(columns):]:
        ax.set_visible(False)

    fig.suptitle("Univariate Distributions", fontsize=14, y=1.01)
    return fig
```

---

## Panel 2 — Outlier Box Plot Grid

```python
def plot_boxplot_grid(df: pd.DataFrame,
                      columns: list[str] | None = None,
                      hue: str | None = None) -> plt.Figure:
    if columns is None:
        columns = df.select_dtypes("number").columns.tolist()
    ncols = min(4, len(columns))
    nrows = int(np.ceil(len(columns) / ncols))
    fig, axes = plt.subplots(nrows, ncols,
                              figsize=(ncols * 4, nrows * 3),
                              constrained_layout=True)
    axes_flat = np.array(axes).flat

    for ax, col in zip(axes_flat, columns):
        if hue:
            sns.boxplot(data=df, x=hue, y=col, ax=ax, showfliers=True,
                        palette="husl")
        else:
            sns.boxplot(data=df, y=col, ax=ax, color="steelblue", showfliers=True)
        ax.set_title(col)

    for ax in list(axes_flat)[len(columns):]:
        ax.set_visible(False)

    fig.suptitle("Outlier Summary (Box Plots)", fontsize=14, y=1.01)
    return fig
```

---

## Panel 3 — Correlation Heatmap

```python
def plot_correlation_heatmap(df: pd.DataFrame,
                              method: str = "spearman",
                              figsize: tuple = (10, 8)) -> plt.Figure:
    corr = df.select_dtypes("number").corr(method=method)
    mask = np.triu(np.ones_like(corr, dtype=bool))   # hide upper triangle

    fig, ax = plt.subplots(figsize=figsize)
    sns.heatmap(
        corr, mask=mask, annot=True, fmt=".2f",
        cmap="coolwarm", center=0, vmin=-1, vmax=1,
        linewidths=0.4, square=True,
        cbar_kws={"shrink": 0.8, "label": f"{method.capitalize()} ρ"},
        ax=ax
    )
    ax.set_title(f"Feature Correlation Matrix ({method.capitalize()})", pad=12)
    fig.tight_layout()
    return fig
```

---

## Panel 4 — Target Relationship Analysis

```python
def plot_target_analysis(df: pd.DataFrame,
                          target: str,
                          features: list[str] | None = None,
                          task: str = "regression") -> plt.Figure:
    if features is None:
        features = [c for c in df.select_dtypes("number").columns if c != target]

    if task == "classification":
        # Show distribution of each feature per class
        ncols = min(3, len(features))
        nrows = int(np.ceil(len(features) / ncols))
        fig, axes = plt.subplots(nrows, ncols,
                                  figsize=(ncols * 4, nrows * 3),
                                  constrained_layout=True)
        for ax, feat in zip(np.array(axes).flat, features):
            sns.kdeplot(data=df, x=feat, hue=target, fill=True,
                        alpha=0.4, common_norm=False, ax=ax)
            ax.set_title(feat)
        fig.suptitle(f"Feature Distributions by {target}", fontsize=14)
    else:
        # Scatter + regression line for each feature
        corrs = df[features].corrwith(df[target]).sort_values(key=abs, ascending=False)
        top_features = corrs.index[:min(9, len(features))]
        ncols = 3
        nrows = int(np.ceil(len(top_features) / ncols))
        fig, axes = plt.subplots(nrows, ncols,
                                  figsize=(ncols * 4, nrows * 3),
                                  constrained_layout=True)
        for ax, feat in zip(np.array(axes).flat, top_features):
            sns.regplot(data=df, x=feat, y=target, ax=ax,
                        scatter_kws={"alpha": 0.3, "s": 15},
                        line_kws={"color": "red", "lw": 1.5})
            ax.set_title(f"{feat}\nρ={corrs[feat]:.3f}")

    return fig
```

---

## Full EDA Report

```python
def run_eda_report(df: pd.DataFrame, target: str | None = None,
                   task: str = "regression", save_dir: str | None = None):
    figs = {}
    figs["distributions"] = plot_distribution_dashboard(df)
    figs["boxplots"]       = plot_boxplot_grid(df, hue=target if task=="classification" else None)
    figs["correlation"]    = plot_correlation_heatmap(df)
    if target:
        figs["target"]     = plot_target_analysis(df, target, task=task)

    if save_dir:
        import pathlib
        pathlib.Path(save_dir).mkdir(parents=True, exist_ok=True)
        for name, fig in figs.items():
            fig.savefig(f"{save_dir}/{name}.png", dpi=150, bbox_inches="tight")
    return figs
```
