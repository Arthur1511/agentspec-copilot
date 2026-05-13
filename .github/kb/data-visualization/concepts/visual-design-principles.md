# Visual Design Principles

## Core Principles

### 1. Data-Ink Ratio (Tufte)
Maximize the proportion of ink devoted to displaying data. Remove:
- Unnecessary grid lines (especially heavy ones)
- Decorative backgrounds and 3D effects
- Redundant labels and tick marks
- Chartjunk (decorative illustrations)

### 2. Lie Factor
```
Lie Factor = (size of effect in graphic) / (size of effect in data)
```
- **LF = 1**: Honest representation
- **LF > 1**: Chart exaggerates effect
- **LF < 1**: Chart understates effect

Common causes: non-zero y-axis baseline, inconsistent scaling, 3D charts

### 3. Gestalt Principles
| Principle | Application |
|-----------|-------------|
| **Proximity** | Group related elements close together |
| **Similarity** | Use consistent colors/shapes for same category |
| **Continuity** | Use lines to show trends |
| **Enclosure** | Use borders/shading to define groups |
| **Figure-Ground** | Make data stand out from background |

## Color Guidelines

```python
import seaborn as sns

# Categorical (≤ 8 groups) — distinguishable, colorblind-safe
CATEGORICAL = sns.color_palette("colorblind", 8)

# Sequential (single metric, light → dark)
SEQUENTIAL = "YlOrRd"   # or "Blues", "Greens", "viridis"

# Diverging (positive / zero / negative)
DIVERGING = "RdBu_r"    # or "coolwarm", "seismic"

# Always define a palette dict for categorical consistency
PALETTE = {
    "control": "#4C72B0",
    "treatment": "#DD8452",
    "baseline": "#8C8C8C",
}
```

**Rules:**
- Never encode 2+ variables in color alone; add shape/size
- Max 7 categories for color encoding (cognitive limit)
- Use colorblind-safe palettes by default
- Diverging scale: always center at a meaningful zero

## Typography

```python
mpl.rcParams.update({
    "font.family": "sans-serif",
    "font.size": 11,           # base size
    "axes.titlesize": 13,      # chart title
    "axes.labelsize": 11,      # axis labels
    "xtick.labelsize": 9,
    "ytick.labelsize": 9,
    "legend.fontsize": 9,
})

# Hierarchy: Title > Axis Labels > Tick Labels > Legend > Annotations
# Ratio guideline: 14 : 11 : 9 : 9 : 9
```

## Choosing the Right Chart

| Goal | Chart |
|------|-------|
| Distribution of one variable | Histogram, KDE, box, violin |
| Compare distributions | Side-by-side box/violin, ECDF |
| Relationship between two vars | Scatter, regression plot |
| Composition (parts of a whole) | Bar (stacked), pie (≤5 slices only) |
| Change over time | Line chart |
| Ranking | Horizontal bar chart |
| Correlation matrix | Heatmap |
| All pairwise relationships | Pair plot |

## Accessibility

```python
# Colorblind-safe default
sns.set_palette("colorblind")

# Add pattern/marker differentiation
markers = ["o", "s", "^", "D", "v"]
for i, (key, grp) in enumerate(df.groupby("group")):
    ax.scatter(grp.x, grp.y, marker=markers[i], label=key)

# Minimum contrast ratio (text on background): 4.5:1 (WCAG AA)
# Use https://webaim.org/resources/contrastchecker/
```

## Annotation Best Practices

```python
# Annotate directly on chart (avoid separate legend when possible)
for group, row in summary.iterrows():
    ax.text(row.x + 0.1, row.y, group, va='center', fontsize=9)

# Use consistent precision
ax.yaxis.set_major_formatter(mpl.ticker.FormatStrFormatter('%.1f'))

# Reference line with label
ax.axhline(0.5, ls="--", color="gray", lw=1)
ax.text(ax.get_xlim()[1], 0.5, " Baseline", va="center", color="gray", fontsize=9)
```

## Quality Checklist

```
□ Non-zero y-axis: is the truncation justified?
□ Lie factor: does scale distort perceived difference?
□ Color: colorblind-safe? meaningful encoding?
□ Labels: all axes labeled with units?
□ Title: describes what the chart shows, not just the data
□ Source annotation: data source cited if for publication
□ Legend: positioned to not obscure data
□ Grid: subtle (alpha ≤ 0.3), only horizontal when helpful
□ Export: saved at ≥ 150 dpi (PNG) or as PDF/SVG
```
