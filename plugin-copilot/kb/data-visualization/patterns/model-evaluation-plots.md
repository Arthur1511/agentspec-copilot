# Model Evaluation Plots

## Purpose

Standard visualization patterns for evaluating classification and regression models: ROC/PR curves, calibration, confusion matrix, feature importance, and residual analysis.

---

## Setup

```python
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import pandas as pd
from sklearn import metrics

sns.set_theme(style="whitegrid", font_scale=1.1)
```

---

## Classification — ROC & PR Curves

```python
def plot_roc_pr(y_true: np.ndarray, y_prob: np.ndarray,
                model_name: str = "Model") -> plt.Figure:
    fig, axes = plt.subplots(1, 2, figsize=(12, 5))

    # ROC
    fpr, tpr, _ = metrics.roc_curve(y_true, y_prob)
    auc = metrics.roc_auc_score(y_true, y_prob)
    axes[0].plot(fpr, tpr, lw=2, color="steelblue", label=f"{model_name} (AUC={auc:.3f})")
    axes[0].plot([0, 1], [0, 1], "k--", lw=1, label="Random")
    axes[0].set(xlabel="FPR", ylabel="TPR", title="ROC Curve")
    axes[0].legend(loc="lower right")

    # PR
    prec, rec, _ = metrics.precision_recall_curve(y_true, y_prob)
    ap = metrics.average_precision_score(y_true, y_prob)
    axes[1].plot(rec, prec, lw=2, color="tomato", label=f"{model_name} (AP={ap:.3f})")
    baseline = y_true.mean()
    axes[1].axhline(baseline, ls="--", color="gray", lw=1, label=f"Baseline ({baseline:.2f})")
    axes[1].set(xlabel="Recall", ylabel="Precision", title="PR Curve")
    axes[1].legend(loc="upper right")

    plt.tight_layout()
    return fig
```

---

## Classification — Confusion Matrix

```python
def plot_confusion_matrix(y_true, y_pred,
                           labels: list | None = None,
                           normalize: str | None = "true") -> plt.Figure:
    cm = metrics.confusion_matrix(y_true, y_pred, normalize=normalize)
    fmt = ".1%" if normalize else "d"
    fig, ax = plt.subplots(figsize=(6, 5))
    sns.heatmap(cm, annot=True, fmt=fmt, cmap="Blues",
                xticklabels=labels, yticklabels=labels,
                linewidths=0.5, ax=ax)
    ax.set(xlabel="Predicted", ylabel="Actual", title="Confusion Matrix")
    plt.tight_layout()
    return fig
```

---

## Classification — Calibration Curve

```python
from sklearn.calibration import calibration_curve

def plot_calibration(y_true, y_prob, n_bins: int = 10,
                     model_name: str = "Model") -> plt.Figure:
    fig, axes = plt.subplots(1, 2, figsize=(12, 4))

    # Reliability diagram
    fraction_pos, mean_pred = calibration_curve(y_true, y_prob, n_bins=n_bins)
    axes[0].plot([0, 1], [0, 1], "k--", lw=1, label="Perfect calibration")
    axes[0].plot(mean_pred, fraction_pos, "o-", color="steelblue",
                 markersize=6, label=model_name)
    axes[0].set(xlabel="Mean predicted probability", ylabel="Fraction positive",
                title="Calibration Curve", xlim=(0, 1), ylim=(0, 1))
    axes[0].legend()

    # Probability histogram
    axes[1].hist(y_prob[y_true == 0], bins=30, alpha=0.5,
                 label="Negative", color="#4C72B0", density=True)
    axes[1].hist(y_prob[y_true == 1], bins=30, alpha=0.5,
                 label="Positive", color="#DD8452", density=True)
    axes[1].set(xlabel="Predicted probability", ylabel="Density",
                title="Score Distribution")
    axes[1].legend()

    plt.tight_layout()
    return fig
```

---

## Regression — Residual Plots

```python
def plot_residuals(y_true, y_pred, model_name: str = "Model") -> plt.Figure:
    residuals = y_true - y_pred
    fig, axes = plt.subplots(1, 3, figsize=(16, 4))

    # Actual vs Predicted
    axes[0].scatter(y_pred, y_true, alpha=0.4, s=15, color="steelblue")
    mn, mx = min(y_pred.min(), y_true.min()), max(y_pred.max(), y_true.max())
    axes[0].plot([mn, mx], [mn, mx], "r--", lw=1.5)
    axes[0].set(xlabel="Predicted", ylabel="Actual", title="Actual vs Predicted")
    r2 = metrics.r2_score(y_true, y_pred)
    axes[0].text(0.05, 0.95, f"R²={r2:.3f}", transform=axes[0].transAxes, va="top")

    # Residuals vs Fitted
    axes[1].scatter(y_pred, residuals, alpha=0.4, s=15, color="steelblue")
    axes[1].axhline(0, color="red", ls="--", lw=1.5)
    axes[1].set(xlabel="Fitted values", ylabel="Residuals", title="Residuals vs Fitted")

    # Residual distribution
    from scipy import stats
    sns.histplot(residuals, kde=True, ax=axes[2], color="steelblue")
    axes[2].set(xlabel="Residual", title="Residual Distribution")
    _, p_norm = stats.shapiro(residuals[:5000])
    axes[2].text(0.05, 0.95, f"Shapiro p={p_norm:.4f}",
                 transform=axes[2].transAxes, va="top", fontsize=9)

    fig.suptitle(f"{model_name} — Residual Analysis", fontsize=13)
    plt.tight_layout()
    return fig
```

---

## Feature Importance

```python
def plot_feature_importance(model, feature_names: list[str],
                             top_n: int = 20) -> plt.Figure:
    # Works for sklearn tree-based models and XGBoost
    if hasattr(model, "feature_importances_"):
        importances = model.feature_importances_
    elif hasattr(model, "coef_"):
        importances = np.abs(model.coef_).ravel()
    else:
        raise ValueError("Model has no feature_importances_ or coef_ attribute")

    imp_df = (
        pd.DataFrame({"feature": feature_names, "importance": importances})
        .sort_values("importance", ascending=False)
        .head(top_n)
    )

    fig, ax = plt.subplots(figsize=(8, max(4, top_n * 0.35)))
    ax.barh(imp_df.feature[::-1], imp_df.importance[::-1],
            color="steelblue", edgecolor="white")
    ax.set(xlabel="Importance", title=f"Top {top_n} Feature Importances")
    plt.tight_layout()
    return fig
```
