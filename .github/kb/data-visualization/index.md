# Data Visualization Knowledge Base

> **MCP Validated:** 2026-05-08

## Purpose

Complete reference for **data visualization** in Python — matplotlib foundations, seaborn statistical plots, plotly interactive charts, and publication-quality figure design for EDA, model evaluation, and reporting.

## Domain Overview

Visualization translates data and model outputs into insight. Covers the three-tier Python viz stack: matplotlib (foundation), seaborn (statistical plots), and plotly (interactive dashboards). Includes visual design principles that make charts honest and readable.

**Key Capabilities:**
- Exploratory distribution and relationship plots
- Model evaluation charts (ROC, calibration, residuals)
- Publication-quality figures with consistent style
- Interactive dashboards with Plotly/Dash
- Multi-panel layouts and subplots

## Key Concepts

| Concept | Description | File |
|---------|-------------|------|
| **Matplotlib Foundations** | Figure/Axes model, Artists, rcParams, OO vs pyplot API | [matplotlib-foundations.md](concepts/matplotlib-foundations.md) |
| **Seaborn Statistical Plots** | Distribution, categorical, regression, matrix plots | [seaborn-statistical-plots.md](concepts/seaborn-statistical-plots.md) |
| **Plotly Interactive** | Plotly Express, Graph Objects, layout, traces, Dash basics | [plotly-interactive.md](concepts/plotly-interactive.md) |
| **Visual Design Principles** | Color, whitespace, annotation, accessibility, lie factor | [visual-design-principles.md](concepts/visual-design-principles.md) |

## Patterns

| Pattern | Use Case | File |
|---------|----------|------|
| **EDA Charts** | Distribution panels, correlation heatmaps, pair plots, outlier viz | [eda-charts.md](patterns/eda-charts.md) |
| **Model Evaluation Plots** | ROC/PR curves, calibration, feature importance, residuals | [model-evaluation-plots.md](patterns/model-evaluation-plots.md) |
| **Publication Quality** | Style sheets, LaTeX labels, vector export, consistent palettes | [publication-quality.md](patterns/publication-quality.md) |
| **Dashboard Layout** | Multi-panel grids, subplot spacing, responsive Plotly dashboards | [dashboard-layout.md](patterns/dashboard-layout.md) |

## Learning Path

### Beginner
1. Read [matplotlib-foundations.md](concepts/matplotlib-foundations.md) — understand Figure/Axes
2. Study [eda-charts.md](patterns/eda-charts.md) — quick EDA visualization
3. Review [quick-reference.md](quick-reference.md) — one-liners for common plots

### Intermediate
4. Learn [seaborn-statistical-plots.md](concepts/seaborn-statistical-plots.md) — statistical viz
5. Apply [model-evaluation-plots.md](patterns/model-evaluation-plots.md) — visualize model performance
6. Study [visual-design-principles.md](concepts/visual-design-principles.md) — make charts honest

### Advanced
7. Master [plotly-interactive.md](concepts/plotly-interactive.md) — interactive exploration
8. Implement [dashboard-layout.md](patterns/dashboard-layout.md) — multi-panel dashboards
9. Apply [publication-quality.md](patterns/publication-quality.md) — presentation-ready figures

## Agent Usage

**Target Agents:**
- `ds-eda-analyst` — primary consumer; EDA distribution and correlation charts
- `ds-model-evaluator` — ROC/PR curves, calibration plots, residual analysis
- `ds-statistician` — visualizing distributions and hypothesis test results

**Common Tasks:**
- Visualize feature distributions: use `eda-charts.md`
- Plot ROC/PR curves: use `model-evaluation-plots.md`
- Create publication figure: use `publication-quality.md`
- Build interactive dashboard: use `dashboard-layout.md`

## Quick Start

```python
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

sns.set_theme(style="whitegrid", palette="husl", font_scale=1.2)

fig, axes = plt.subplots(1, 2, figsize=(12, 4))
data = np.random.normal(0, 1, 500)
sns.histplot(data, kde=True, ax=axes[0])
axes[0].set_title("Distribution with KDE")
sns.boxplot(x=data, ax=axes[1])
axes[1].set_title("Box Plot")
plt.tight_layout()
plt.show()
```

## Related Domains

- **pandas** — data preparation before visualization
- **statistical-analysis** — overlay statistical annotations on charts
- **scikit-learn** — model outputs (probabilities, importances) to visualize
- **xgboost** — SHAP values and tree-based feature importance plots

## References

- Matplotlib: https://matplotlib.org/stable/
- Seaborn: https://seaborn.pydata.org/
- Plotly: https://plotly.com/python/
- "Fundamentals of Data Visualization" — Claus O. Wilke
