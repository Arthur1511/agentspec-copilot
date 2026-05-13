# Pandas Knowledge Base

> **MCP Validated:** 2026-05-08

## Purpose

Complete reference for **pandas** — the foundational Python library for data manipulation, wrangling, and analysis. Essential for every data scientist working with tabular, time-series, or structured data.

## Domain Overview

pandas provides DataFrame and Series data structures backed by NumPy, with expressive APIs for loading, transforming, aggregating, and exporting data. It is the lingua franca of Python data science.

**Key Capabilities:**
- DataFrame and Series creation from CSV, Excel, SQL, JSON, Parquet
- Flexible indexing with `.loc`, `.iloc`, boolean masks
- Split-apply-combine with `groupby`
- Relational joins and reshaping (`merge`, `pivot`, `melt`)
- Missing data detection and imputation
- Time-series resampling and rolling windows
- Integration with NumPy, scikit-learn, matplotlib, and Arrow

## Key Concepts

| Concept | Description | File |
|---------|-------------|------|
| **DataFrame Fundamentals** | Core data structures, dtypes, memory layout, copy vs view | [dataframe-fundamentals.md](concepts/dataframe-fundamentals.md) |
| **Indexing & Selection** | `.loc`, `.iloc`, boolean indexing, `.query()`, MultiIndex | [indexing-selection.md](concepts/indexing-selection.md) |
| **GroupBy & Aggregation** | `groupby`, `agg`, `transform`, `apply`, `pivot_table` | [groupby-aggregation.md](concepts/groupby-aggregation.md) |
| **Data Types & Casting** | dtype selection, categoricals, nullable integers, Arrow backend | [data-types.md](concepts/data-types.md) |

## Patterns

| Pattern | Use Case | File |
|---------|----------|------|
| **Data Wrangling** | Clean, reshape, and normalize raw tabular data | [data-wrangling.md](patterns/data-wrangling.md) |
| **Merge & Join** | Combine DataFrames with merge, join, concat strategies | [merge-join.md](patterns/merge-join.md) |
| **Missing Data** | Detect, impute, and flag null values | [missing-data.md](patterns/missing-data.md) |
| **Performance Optimization** | Vectorization, chunking, categoricals, Arrow backend | [performance-optimization.md](patterns/performance-optimization.md) |

## Learning Path

### Beginner
1. Read [dataframe-fundamentals.md](concepts/dataframe-fundamentals.md) — core structures
2. Study [data-wrangling.md](patterns/data-wrangling.md) — practical transformations
3. Review [quick-reference.md](quick-reference.md) — most-used operations

### Intermediate
4. Learn [indexing-selection.md](concepts/indexing-selection.md) — precise data access
5. Master [groupby-aggregation.md](concepts/groupby-aggregation.md) — analytics patterns
6. Apply [missing-data.md](patterns/missing-data.md) — production-quality cleaning

### Advanced
7. Study [data-types.md](concepts/data-types.md) — memory efficiency
8. Implement [merge-join.md](patterns/merge-join.md) — complex multi-table work
9. Optimize with [performance-optimization.md](patterns/performance-optimization.md)

## Agent Usage

**Target Agents:**
- `ds-eda-analyst` — exploratory data analysis and profiling
- `ds-feature-engineer` — feature pipeline construction
- `python-developer` — data manipulation in production code

**Common Tasks:**
- Load data: `pd.read_csv()`, `pd.read_parquet()`, `pd.read_sql()`
- Profile: `.info()`, `.describe()`, `.value_counts()`, `.isnull().sum()`
- Transform: `.rename()`, `.assign()`, `.pipe()`, `.apply()`
- Export: `.to_parquet()`, `.to_csv()`, `.to_sql()`

## Quick Start

```python
import pandas as pd

df = pd.read_csv("data.csv")
print(df.info())
print(df.describe())

# Clean
df = df.dropna(subset=["target"])
df["age"] = df["age"].fillna(df["age"].median())

# Aggregate
summary = df.groupby("category")["value"].agg(["mean", "std", "count"])

# Export
df.to_parquet("clean_data.parquet", index=False)
```

## Related Domains

- **Python** — Core language patterns
- **scikit-learn** — Model-ready arrays from DataFrames
- **data-quality** — Validation patterns
- **xgboost** — Direct DataFrame input support

## References

- Official Docs: https://pandas.pydata.org/docs/
- User Guide: https://pandas.pydata.org/docs/user_guide/
- API Reference: https://pandas.pydata.org/docs/reference/
