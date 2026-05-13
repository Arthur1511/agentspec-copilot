# Data Visualization — Quick Reference

## Matplotlib Essentials

```python
import matplotlib.pyplot as plt

fig, ax = plt.subplots(figsize=(8, 5))      # OO API — always preferred
ax.plot(x, y, color="steelblue", lw=2)
ax.set(xlabel="X", ylabel="Y", title="Title")
ax.legend(loc="upper right")
fig.tight_layout()
fig.savefig("fig.pdf", dpi=300, bbox_inches="tight")
```

## Seaborn One-Liners

| Chart | Code |
|-------|------|
| Histogram + KDE | `sns.histplot(df, x="col", kde=True, hue="group")` |
| Box plot | `sns.boxplot(df, x="group", y="value")` |
| Violin plot | `sns.violinplot(df, x="group", y="value", inner="box")` |
| Scatter | `sns.scatterplot(df, x="a", y="b", hue="class", size="weight")` |
| Regression line | `sns.regplot(df, x="a", y="b", ci=95)` |
| Heatmap | `sns.heatmap(corr, annot=True, fmt=".2f", cmap="coolwarm", center=0)` |
| Pair plot | `sns.pairplot(df, hue="target", diag_kind="kde")` |
| Count plot | `sns.countplot(df, x="cat", order=df["cat"].value_counts().index)` |

## Plotly Express One-Liners

```python
import plotly.express as px

px.histogram(df, x="col", color="group", marginal="box", nbins=50)
px.scatter(df, x="a", y="b", color="class", hover_data=["id"])
px.box(df, x="group", y="value", points="outliers")
px.heatmap(corr)                              # px.imshow for 2D arrays
px.line(df, x="date", y="value", color="series")
```

## Style Setup

```python
import seaborn as sns, matplotlib as mpl

# Seaborn theme (apply once per notebook)
sns.set_theme(style="whitegrid", palette="husl", font_scale=1.2)

# Matplotlib rcParams
mpl.rcParams.update({
    "figure.dpi": 150,
    "axes.spines.top": False,
    "axes.spines.right": False,
    "font.family": "sans-serif",
})
```

## Color Palettes

| Use Case | Palette |
|----------|---------|
| Categorical | `"husl"`, `"tab10"`, `"Set2"` |
| Sequential (light→dark) | `"Blues"`, `"YlOrRd"`, `"viridis"` |
| Diverging (neg/zero/pos) | `"coolwarm"`, `"RdBu_r"`, `"seismic"` |
| Colorblind-safe | `"colorblind"` (seaborn), `"tab10"` |

## Figure Layouts

```python
# Subplots
fig, axes = plt.subplots(2, 3, figsize=(15, 8), sharex=True)
axes[0, 1].set_title("Top-center")
plt.tight_layout(pad=2.0)

# GridSpec (unequal sizes)
from matplotlib.gridspec import GridSpec
gs = GridSpec(2, 2, figure=fig, height_ratios=[3, 1])
ax_main = fig.add_subplot(gs[0, :])   # full-width top
ax_bot_l = fig.add_subplot(gs[1, 0])
```

## Annotations

```python
ax.axvline(x=threshold, color="red", ls="--", label="Threshold")
ax.axhspan(ymin, ymax, alpha=0.1, color="green")
ax.annotate("Peak", xy=(x0, y0), xytext=(x0+1, y0+5),
            arrowprops=dict(arrowstyle="->"))
ax.text(0.05, 0.95, "Note", transform=ax.transAxes,
        va="top", fontsize=10)
```

## Save & Export

```python
fig.savefig("fig.png", dpi=150, bbox_inches="tight")     # raster
fig.savefig("fig.pdf", bbox_inches="tight")               # vector (publications)
fig.savefig("fig.svg", bbox_inches="tight")               # editable vector
plotly_fig.write_html("interactive.html")                  # Plotly → HTML
```
