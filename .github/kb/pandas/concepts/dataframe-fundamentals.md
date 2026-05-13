# DataFrame Fundamentals

> Core data structures, memory layout, copy vs view, and dtype management.

---

## DataFrame and Series

pandas has two primary data structures:

- **Series** — 1D labeled array. Backed by a single NumPy array.
- **DataFrame** — 2D labeled table. Each column is a Series sharing a common index.

```python
import pandas as pd
import numpy as np

s = pd.Series([1, 2, 3], index=["a", "b", "c"])
df = pd.DataFrame({"name": ["Alice", "Bob"], "age": [30, 25]})
```

---

## Index

Every DataFrame and Series has an **Index** — the row labels.

```python
df.index           # RangeIndex(start=0, stop=2, step=1)
df.columns         # Index(['name', 'age'], dtype='object')
df.reset_index()   # Move index to column
df.set_index("id") # Promote column to index
```

---

## dtypes and Memory

Choosing the right dtype reduces memory by 2–10×.

| pandas dtype | NumPy / Python type | Use Case |
|---|---|---|
| `int64` | `np.int64` | Default integers |
| `float64` | `np.float64` | Default floats |
| `object` | Python `str` | Strings (expensive) |
| `category` | Categorical | Low-cardinality strings |
| `bool` | `bool` | Flags |
| `datetime64[ns]` | — | Timestamps |
| `Int64` (nullable) | pd.NA-aware | Integers with nulls |

```python
df["city"] = df["city"].astype("category")  # ~8x less memory
df.memory_usage(deep=True)                   # Check usage per column
```

---

## Copy vs View

pandas may return a **view** (shares memory) or a **copy** (independent).

```python
# View — modifying this changes df
view = df[df["age"] > 25]

# Copy — safe to mutate
safe = df[df["age"] > 25].copy()
safe["flag"] = True  # No SettingWithCopyWarning
```

**Rule:** Always call `.copy()` when slicing and intending to mutate.

---

## Creation Patterns

```python
# From dict
df = pd.DataFrame({"a": [1, 2], "b": [3, 4]})

# From list of dicts (common from API responses)
rows = [{"id": 1, "val": 10}, {"id": 2, "val": 20}]
df = pd.DataFrame(rows)

# From NumPy
arr = np.random.randn(100, 3)
df = pd.DataFrame(arr, columns=["x", "y", "z"])

# Empty with schema
df = pd.DataFrame(columns=["id", "name", "score"]).astype(
    {"id": "int64", "name": "object", "score": "float64"}
)
```

---

## Key Attributes

```python
df.shape       # (rows, cols)
df.ndim        # 2
df.size        # rows * cols
df.dtypes      # dtype per column
df.values      # underlying NumPy array
df.to_numpy()  # preferred over .values
```

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| `df["a"]["b"] = val` | Chain indexing — unpredictable | `df.loc[:, "b"] = val` |
| Loop over rows with `iterrows` | Very slow | Vectorized operations |
| Store mixed types in one column | Becomes `object` dtype | Enforce consistent types at load |
