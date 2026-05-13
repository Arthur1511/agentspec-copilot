# GroupBy and Aggregation

> Split-apply-combine with `groupby`, `agg`, `transform`, `apply`, and `pivot_table`.

---

## The Split-Apply-Combine Pattern

1. **Split** — partition data by one or more keys
2. **Apply** — compute a function on each partition
3. **Combine** — collect results into a new structure

```python
grouped = df.groupby("category")       # GroupBy object
result  = grouped["value"].mean()      # Series with one value per group
```

---

## `.agg()` — Multiple Aggregations

```python
# Single function
df.groupby("dept")["salary"].mean()

# Multiple functions
df.groupby("dept")["salary"].agg(["mean", "std", "count"])

# Different functions per column
df.groupby("dept").agg({"salary": "mean", "tenure": "max"})

# Named aggregations (preferred — clear output column names)
df.groupby("dept").agg(
    avg_salary=("salary", "mean"),
    max_tenure=("tenure", "max"),
    headcount=("id", "count"),
)
```

---

## `.transform()` — Preserve Shape

Returns a Series/DataFrame of the **same shape** as the input — useful for creating new columns based on group statistics.

```python
# Add group mean as a new column
df["dept_avg"] = df.groupby("dept")["salary"].transform("mean")

# Normalize within group
df["salary_norm"] = df.groupby("dept")["salary"].transform(
    lambda x: (x - x.mean()) / x.std()
)

# Fill nulls with group median
df["salary"] = df["salary"].fillna(
    df.groupby("dept")["salary"].transform("median")
)
```

---

## `.apply()` — Custom Functions

Use only when `agg` / `transform` cannot express the logic (slower).

```python
def top_n(group, n=3):
    return group.nlargest(n, "salary")

df.groupby("dept").apply(top_n, n=2, include_groups=False)
```

---

## `pivot_table`

```python
pd.pivot_table(
    df,
    values="sales",
    index="region",
    columns="quarter",
    aggfunc="sum",
    fill_value=0,
)
```

Equivalent to Excel PivotTable. Returns a DataFrame.

---

## `resample()` — Time-Based GroupBy

Requires a DatetimeIndex.

```python
df = df.set_index("date")
monthly = df["revenue"].resample("ME").sum()   # Month-end
weekly  = df["visits"].resample("W").mean()
```

---

## Rolling and Expanding Windows

```python
df["rolling_avg"] = df["value"].rolling(window=7, min_periods=1).mean()
df["cum_sum"]     = df["value"].expanding().sum()
df["ewm_avg"]     = df["value"].ewm(span=7).mean()
```

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| `apply` with row-wise lambda | Very slow | Vectorize or use `agg` |
| Ignore `observed=True` on categoricals | Creates all combos | `groupby(..., observed=True)` |
| Large `apply` on each group | Memory spikes | Use `agg` or `transform` |
| Forget `reset_index()` | GroupBy index surprises | Chain `.reset_index()` |
