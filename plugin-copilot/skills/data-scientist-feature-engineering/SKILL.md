---
name: ds-feature-engineering
description: Feature engineering for data scientists — delegates to ds-feature-engineer agent. Use when building scikit-learn Pipelines, encoding categoricals, imputing missing values, scaling features, or creating lag/rolling features for time series.
---

# Feature Engineering Command

> Build preprocessing pipelines, encode features, and engineer inputs for ML models

## Usage

```bash
/ds-feature-engineering <dataset-or-description>
```

## Examples

```bash
/ds-feature-engineering data/train.csv
/ds-feature-engineering "Encode categoricals and impute nulls for churn model"
/ds-feature-engineering "Build ColumnTransformer for mixed numeric/categorical dataset"
/ds-feature-engineering "Create lag and rolling features for daily sales forecasting"
```

---

## What This Command Does

1. Invokes the **ds-feature-engineer** agent
2. Audits column types, cardinality, and null rates
3. Loads KB patterns from `scikit-learn` and `pandas` domains
4. Generates:
   - `ColumnTransformer` + `Pipeline` definition preventing data leakage
   - Encoder selection (OrdinalEncoder vs OneHotEncoder vs TargetEncoder)
   - Imputer selection (SimpleImputer vs KNNImputer)
   - Scaler selection (StandardScaler vs RobustScaler)
   - Feature selection step (SelectKBest or RFE)

## Agent Delegation

| Agent | Role |
|-------|------|
| `ds-feature-engineer` | Primary — Pipeline, encoding, imputation, scaling, selection |
| `ds-time-series-analyst` | Escalation — when lag/rolling features are needed |
| `ds-eda-analyst` | Escalation — when column audit is needed first |

## KB Domains Used

- `scikit-learn` — Pipeline, ColumnTransformer, encoders, imputers, scalers
- `pandas` — Feature creation with DataFrame operations
- `time-series` — Lag features, rolling statistics, date/time features

## Output

The agent generates a complete scikit-learn `Pipeline` with `ColumnTransformer`, ready to fit on training data without leakage.
