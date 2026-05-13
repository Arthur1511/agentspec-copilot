---
name: eda
description: Exploratory data analysis for data scientists — delegates to ds-eda-analyst agent. Use when profiling datasets, visualizing distributions, checking correlations, or detecting missing data and outliers.
---

# EDA Command

> Profile and explore a dataset to understand structure, distributions, and relationships

## Usage

```bash
/ds-eda <dataset-or-description>
```

## Examples

```bash
/ds-eda data/customers.csv
/ds-eda "Explore churn dataset — check missing values, distributions, and class balance"
/ds-eda "Correlation analysis between features and loan default"
/ds-eda notebooks/raw_data_exploration.ipynb
```

---

## What This Command Does

1. Invokes the **ds-eda-analyst** agent
2. Reads the dataset or description to understand schema and target
3. Loads KB patterns from `pandas` and `data-visualization` domains
4. Generates:
   - Shape, dtypes, null counts, cardinality report
   - Distribution plots (histograms, box plots, KDE)
   - Correlation heatmap and pairplot
   - Missing data summary with imputation recommendations
   - Quick baseline model for feature validation

## Agent Delegation

| Agent | Role |
|-------|------|
| `ds-eda-analyst` | Primary — profiling, distributions, correlations, outliers |
| `ds-statistician` | Escalation — when statistical significance tests are needed |
| `ds-feature-engineer` | Escalation — when missing data requires Pipeline imputation |

## KB Domains Used

- `pandas` — DataFrame profiling, groupby, reshaping
- `data-visualization` — EDA charts, heatmaps, distribution plots
- `statistical-analysis` — normality tests, outlier detection

## Output

The agent generates a profiling report with visualizations, null-handling recommendations, and a baseline model summary.
