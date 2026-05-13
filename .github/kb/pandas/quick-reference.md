# Pandas Quick Reference

> **MCP Validated:** 2026-05-08

Fast lookup for the most-used pandas operations.

---

## I/O

| Operation | Code |
|-----------|------|
| Read CSV | `pd.read_csv("f.csv", dtype={"id": str})` |
| Read Parquet | `pd.read_parquet("f.parquet")` |
| Read SQL | `pd.read_sql("SELECT ...", con=engine)` |
| Write Parquet | `df.to_parquet("f.parquet", index=False)` |
| Write CSV | `df.to_csv("f.csv", index=False)` |

---

## Inspection

| Operation | Code |
|-----------|------|
| Shape | `df.shape` |
| Types | `df.dtypes` |
| Summary | `df.info()` |
| Stats | `df.describe(include="all")` |
| Nulls | `df.isnull().sum()` |
| Unique | `df["col"].nunique()` |
| Frequency | `df["col"].value_counts(normalize=True)` |

---

## Selection

| Operation | Code |
|-----------|------|
| By label | `df.loc[rows, cols]` |
| By position | `df.iloc[0:5, 0:3]` |
| Boolean mask | `df[df["age"] > 30]` |
| Query string | `df.query("age > 30 and city == 'NY'")` |
| Multiple cols | `df[["a", "b", "c"]]` |

---

## Transformation

| Operation | Code |
|-----------|------|
| Rename cols | `df.rename(columns={"old": "new"})` |
| Add col | `df.assign(bmi=df.weight / df.height**2)` |
| Cast dtype | `df["col"].astype("category")` |
| Apply func | `df["col"].map(func)` |
| Chain ops | `df.pipe(clean).pipe(transform)` |
| Drop dupes | `df.drop_duplicates(subset=["id"])` |

---

## Aggregation

| Operation | Code |
|-----------|------|
| GroupBy | `df.groupby("col")["val"].mean()` |
| Multi-agg | `df.groupby("col").agg({"a": "sum", "b": "mean"})` |
| Named agg | `df.groupby("g").agg(avg=("v", "mean"), n=("v", "count"))` |
| Pivot table | `df.pivot_table(values="v", index="r", columns="c", aggfunc="sum")` |
| Transform | `df.groupby("g")["v"].transform("mean")` (keeps original shape) |

---

## Missing Data

| Operation | Code |
|-----------|------|
| Drop rows | `df.dropna(subset=["target"])` |
| Fill value | `df["col"].fillna(0)` |
| Fill median | `df["col"].fillna(df["col"].median())` |
| Fill forward | `df["col"].ffill()` |
| Indicator col | `df["col_missing"] = df["col"].isnull().astype(int)` |

---

## Merge / Join

| Operation | Code |
|-----------|------|
| Inner join | `df1.merge(df2, on="key")` |
| Left join | `df1.merge(df2, on="key", how="left")` |
| Stack rows | `pd.concat([df1, df2], ignore_index=True)` |
| Melt (wide→long) | `df.melt(id_vars=["id"], var_name="metric", value_name="val")` |
| Pivot (long→wide) | `df.pivot(index="id", columns="metric", values="val")` |

---

## Performance Tips

| Problem | Solution |
|---------|----------|
| High memory on strings | `.astype("category")` for low-cardinality |
| Slow `apply` row-wise | Vectorize with `.str`, `.dt`, or NumPy |
| Large CSV | `chunksize=10_000` in `read_csv` |
| Slow groupby | Use `observed=True` with categoricals |
| Copy vs view confusion | Always use `.copy()` when slicing to mutate |

---

## Common Pitfalls

| Mistake | Fix |
|---------|-----|
| `SettingWithCopyWarning` | Use `.loc` or `.copy()` |
| `df[col] = val` on slice | Use `df.loc[:, col] = val` |
| Chained indexing | Never `df["a"]["b"]` — use `df.loc[:, ["a", "b"]]` |
| `inplace=True` | Avoid — reassign instead: `df = df.rename(...)` |
| Iterating rows | Never `iterrows()` on large data — vectorize |
