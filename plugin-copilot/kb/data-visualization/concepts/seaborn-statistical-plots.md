# Seaborn Statistical Plots

## Setup

```python
import seaborn as sns
import matplotlib.pyplot as plt

# Apply once per session
sns.set_theme(
    style="whitegrid",   # whitegrid | darkgrid | white | dark | ticks
    palette="husl",      # husl | tab10 | Set2 | colorblind | muted
    font_scale=1.2,
    rc={"axes.spines.top": False, "axes.spines.right": False}
)
```

## Distribution Plots (`displot` family)

```python
# Histogram + KDE
sns.histplot(df, x="value", kde=True, hue="group",
             bins=30, stat="density", common_norm=False)

# KDE only
sns.kdeplot(df, x="value", hue="group",
            fill=True, alpha=0.3, common_norm=False)

# ECDF (empirical CDF — often better than histogram)
sns.ecdfplot(df, x="value", hue="group")

# Rug (marginal ticks)
sns.rugplot(df, x="value", hue="group", height=0.05)
```

## Categorical Plots (`catplot` family)

```python
# Box plot
sns.boxplot(df, x="group", y="value", hue="subgroup",
            order=ordered_cats, showfliers=False)

# Violin plot (combines box + KDE)
sns.violinplot(df, x="group", y="value", inner="box", density_norm="width")

# Strip + swarm (individual points)
sns.stripplot(df, x="group", y="value", jitter=True, alpha=0.5)
sns.swarmplot(df, x="group", y="value", size=3)

# Bar plot (mean + CI)
sns.barplot(df, x="group", y="value", estimator="mean", errorbar="ci")

# Count plot
sns.countplot(df, x="category",
              order=df["category"].value_counts().index)
```

## Relationship Plots (`relplot` family)

```python
# Scatter + regression
sns.scatterplot(df, x="feat_a", y="feat_b",
                hue="class", size="weight", alpha=0.7)

# Linear regression with CI
sns.regplot(df, x="a", y="b", ci=95, scatter_kws={"alpha": 0.4})

# Faceted scatter grid
g = sns.relplot(df, x="a", y="b", col="group",
                kind="scatter", hue="class", col_wrap=3, height=3)
```

## Matrix Plots

```python
# Correlation heatmap
corr = df.corr(method='spearman')
mask = np.triu(np.ones_like(corr, dtype=bool))
fig, ax = plt.subplots(figsize=(10, 8))
sns.heatmap(corr, mask=mask, annot=True, fmt=".2f",
            cmap="coolwarm", center=0, vmin=-1, vmax=1,
            linewidths=0.5, ax=ax)

# Cluster map (hierarchical clustering)
sns.clustermap(corr, cmap="coolwarm", center=0,
               figsize=(10, 10), method="ward")

# Pair plot (all pairwise relationships)
sns.pairplot(df, hue="target", diag_kind="kde",
             plot_kws={"alpha": 0.5}, diag_kws={"fill": True})
```

## FacetGrid — Multi-Panel

```python
# facetgrid manual
g = sns.FacetGrid(df, col="group", row="gender", height=3, aspect=1.2)
g.map_dataframe(sns.histplot, x="value", kde=True)
g.set_axis_labels("Value", "Count")
g.add_legend()
g.set_titles(col_template="{col_name}", row_template="{row_name}")
```

## Adding Significance Markers

```python
# Manual annotations after seaborn plot
from scipy.stats import ttest_ind

def annotate_significance(ax, x1, x2, y, h, p):
    """Draw bracket and p-value annotation."""
    stars = "***" if p < 0.001 else "**" if p < 0.01 else "*" if p < 0.05 else "ns"
    ax.plot([x1, x1, x2, x2], [y, y+h, y+h, y], lw=1, color="black")
    ax.text((x1+x2)/2, y+h, stars, ha="center", va="bottom", color="black")
```

## Common Style Choices

| Setting | Code |
|---------|------|
| Remove legend | `ax.get_legend().remove()` |
| Move legend outside | `ax.legend(bbox_to_anchor=(1.05, 1), loc='upper left')` |
| Rotate x-tick labels | `ax.tick_params(axis='x', rotation=45)` |
| Set palette | `sns.set_palette("Set2")` |
| Per-plot override | `palette={"A": "steelblue", "B": "tomato"}` |
