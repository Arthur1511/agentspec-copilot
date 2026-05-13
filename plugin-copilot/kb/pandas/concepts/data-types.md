# Data Types and Casting

> dtype selection, categoricals, nullable integers, Arrow backend, and memory optimization.

---

## dtype Overview

| dtype | Storage | Nulls | Notes |
|-------|---------|-------|-------|
| `int64` | 8 bytes/val | No (use `Int64`) | Default integer |
| `Int64` | 8 bytes/val | Yes (pd.NA) | Nullable integer |
| `float64` | 8 bytes/val | Yes (NaN) | Default float |
| `float32` | 4 bytes/val | Yes | Use when precision allows |
| `object` | ~50+ bytes/val | Yes | Python strings — expensive |
| `string` | variable | Yes (pd.NA) | Arrow-backed strings |
| `category` | ~1 byte/val | Yes | Low-cardinality strings |
| `bool` | 1 byte/val | No | Flags |
| `datetime64[ns]` | 8 bytes/val | Yes (NaT) | Timestamps |

---

## Casting

```python
df["age"]    = df["age"].astype("int32")
df["city"]   = df["city"].astype("category")
df["active"] = df["active"].astype("bool")
df["date"]   = pd.to_datetime(df["date"], format="%Y-%m-%d")
df["price"]  = pd.to_numeric(df["price"], errors="coerce")  # non-parseable → NaN
```

---

## Categorical dtype

Best for columns with < ~50 unique values relative to total rows.

```python
df["status"] = df["status"].astype("category")

# Add new category before assigning
df["status"] = df["status"].cat.add_categories("archived")
df["status"] = df["status"].cat.set_categories(["pending", "active", "archived"], ordered=True)

# Sort by category order
df.sort_values("status")
```

**Memory saving:** `object` column with 1M rows → ~8 MB as `category` vs ~80 MB as `object`.

---

## Nullable Integer / Boolean

Use when a column has nulls and must stay integer (avoids silent float conversion).

```python
df["count"] = df["count"].astype("Int64")   # Nullable integer
df["flag"]  = df["flag"].astype("boolean")  # Nullable boolean

df["count"].isna()  # True for pd.NA entries
```

---

## String dtype (Arrow-backed)

Faster string operations and lower memory than `object`.

```python
df["name"] = df["name"].astype("string")    # pd.StringDtype()
df["name"].str.upper()                       # Same str accessor, faster
```

---

## Reducing Memory at Load Time

```python
dtype_map = {
    "user_id":  "int32",
    "age":      "int8",
    "city":     "category",
    "revenue":  "float32",
}
df = pd.read_csv("data.csv", dtype=dtype_map)
```

---

## Detecting and Optimizing

```python
# Before
print(df.memory_usage(deep=True).sum() / 1e6, "MB")

# Auto-downcast
for col in df.select_dtypes("integer").columns:
    df[col] = pd.to_numeric(df[col], downcast="integer")
for col in df.select_dtypes("float").columns:
    df[col] = pd.to_numeric(df[col], downcast="float")

# After
print(df.memory_usage(deep=True).sum() / 1e6, "MB")
```

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| Store IDs as `float64` | Precision loss, ugly | `int64` or `object` |
| Leave string cols as `object` when low-cardinality | Wastes memory | `category` |
| Mix types in one column | Degrades to `object` | Enforce at load time |
| Use `int64` for nullable integers | NaN forces float | Use `Int64` |
