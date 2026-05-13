# Experiment Comparison Pattern

## Purpose

Query and compare multiple MLflow runs to identify the best model, understand performance variance, and build model leaderboards for stakeholder reporting.

---

## Load All Runs into DataFrame

```python
import mlflow
import pandas as pd
import numpy as np

def load_experiment_runs(
    experiment_name: str,
    status: str = "FINISHED",
    min_metrics: dict | None = None,
) -> pd.DataFrame:
    """Load all runs for an experiment into a clean DataFrame."""
    filters = [f"attributes.status = '{status}'"]
    if min_metrics:
        for k, v in min_metrics.items():
            filters.append(f"metrics.{k} > {v}")

    runs = mlflow.search_runs(
        experiment_names=[experiment_name],
        filter_string=" AND ".join(filters),
        order_by=["start_time DESC"],
        max_results=200,
    )
    if runs.empty:
        print(f"No finished runs in '{experiment_name}'")
        return runs

    # Clean up column names
    runs.columns = [c.replace("metrics.", "").replace("params.", "p_")
                    .replace("tags.", "t_") for c in runs.columns]
    return runs

runs = load_experiment_runs("churn-prediction", min_metrics={"roc_auc": 0.80})
print(f"Loaded {len(runs)} runs")
```

---

## Leaderboard

```python
METRICS = ["roc_auc", "f1", "avg_prec", "cv_auc_mean"]
PARAMS  = ["p_n_estimators", "p_max_depth", "p_model_type"]

def build_leaderboard(runs: pd.DataFrame,
                      sort_by: str = "roc_auc",
                      top_n: int = 10) -> pd.DataFrame:
    cols = ["run_id", "start_time"] + \
           [c for c in METRICS if c in runs.columns] + \
           [c for c in PARAMS if c in runs.columns]
    board = (
        runs[cols]
        .sort_values(sort_by, ascending=False)
        .head(top_n)
        .reset_index(drop=True)
    )
    board.index += 1   # rank starts at 1
    board["run_id"] = board["run_id"].str[:8]
    return board

board = build_leaderboard(runs)
print(board.to_markdown(index=True))
```

---

## Metric Comparison Plot

```python
import matplotlib.pyplot as plt
import seaborn as sns

def plot_metric_comparison(runs: pd.DataFrame,
                            metrics: list[str] = None,
                            hue: str = "p_model_type") -> plt.Figure:
    if metrics is None:
        metrics = [c for c in ["roc_auc", "f1", "avg_prec", "cv_auc_mean"]
                   if c in runs.columns]

    n = len(metrics)
    fig, axes = plt.subplots(1, n, figsize=(5 * n, 4), constrained_layout=True)
    if n == 1:
        axes = [axes]

    for ax, metric in zip(axes, metrics):
        if hue and hue in runs.columns:
            sns.stripplot(data=runs, y=metric, x=hue, ax=ax,
                          jitter=True, size=7, alpha=0.7)
        else:
            ax.scatter(range(len(runs)), runs[metric], s=40, alpha=0.7)
        ax.set(title=metric, xlabel="")
        ax.tick_params(axis='x', rotation=30)

    fig.suptitle("Metric Comparison Across Runs", fontsize=13)
    return fig
```

---

## Hyperparameter Sensitivity

```python
def hyperparameter_sensitivity(runs: pd.DataFrame,
                                param: str,
                                metric: str = "roc_auc") -> plt.Figure:
    """Box plot of metric distribution per param value."""
    if param not in runs.columns or metric not in runs.columns:
        raise ValueError(f"Columns {param} or {metric} not found")

    fig, ax = plt.subplots(figsize=(8, 4))
    order = runs.groupby(param)[metric].median().sort_values(ascending=False).index
    sns.boxplot(data=runs, x=param, y=metric, order=order, ax=ax,
                palette="husl", showfliers=False)
    sns.stripplot(data=runs, x=param, y=metric, order=order, ax=ax,
                  color="black", size=4, alpha=0.5, jitter=True)
    ax.set(title=f"{metric} by {param}", xlabel=param)
    plt.tight_layout()
    return fig
```

---

## Load Best Model Directly

```python
def load_best_model_from_experiment(
    experiment_name: str,
    metric: str = "roc_auc",
    min_score: float = 0.80,
) -> tuple:
    """Return (model, run_row) for the best run in an experiment."""
    runs = mlflow.search_runs(
        experiment_names=[experiment_name],
        filter_string=(f"metrics.{metric} > {min_score} "
                       "AND attributes.status = 'FINISHED'"),
        order_by=[f"metrics.{metric} DESC"],
        max_results=1,
    )
    if runs.empty:
        raise ValueError("No qualifying runs found")

    best = runs.iloc[0]
    model = mlflow.sklearn.load_model(f"runs:/{best['run_id']}/model")
    print(f"Loaded run {best['run_id'][:8]}: {metric}={best[f'metrics.{metric}']:.4f}")
    return model, best


model, best_run = load_best_model_from_experiment("churn-prediction")
```

---

## Output Checklist

```
□ All runs loaded with status=FINISHED filter
□ Leaderboard table generated (ranked by primary metric)
□ Metric comparison strip plot created
□ Hyperparameter sensitivity analysis run for key params
□ Best model identified and loaded
□ Best run metadata (run_id, params, metrics) captured for documentation
```
