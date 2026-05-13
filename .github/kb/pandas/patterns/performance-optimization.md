# Performance Optimization

> Vectorization, chunking, categoricals, Arrow backend, and memory-efficient patterns.

---

## The Performance Hierarchy

```
Built-in pandas methods
    > NumPy vectorized operations
        > .str / .dt accessors
            > list comprehensions
                > df.apply(axis=1)      ← 10–100x slower
                    > iterrows()        ← 100–1000x slower
```

**Rule:** If you're looping over rows, you're doing it wrong.

---

## Vectorization — Replace Loops

```python
# BAD — row loop
results = []
for _, row in df.iterrows():
    results.append(row["a"] + row["b"])
df["c"] = results

# GOOD — vectorized
df["c"] = df["a"] + df["b"]
```

```python
# BAD — apply
df["tax"] = df["income"].apply(lambda x: x * 0.3 if x > 50000 else x * 0.2)

# GOOD — np.where / pd.cut
df["tax"] = np.where(df["income"] > 50000, df["income"] * 0.3, df["income"] * 0.2)
```

---

## Categorical Columns

```python
# Before
df["city"] = df["city"].astype("object")      # ~80 MB for 1M rows
df.groupby("city")["revenue"].mean()          # Slow

# After
df["city"] = df["city"].astype("category")    # ~8 MB
df.groupby("city", observed=True)["revenue"].mean()  # Fast
```

Always add `observed=True` when grouping on categoricals.

---

## Chunking Large Files

```python
# Process a 10GB CSV without loading into memory
chunks = []
for chunk in pd.read_csv("big.csv", chunksize=100_000):
    result = chunk.groupby("category")["value"].sum()
    chunks.append(result)

summary = pd.concat(chunks).groupby(level=0).sum()
```

---

## Efficient I/O

| Format | Read Speed | Write Speed | File Size | Random Access |
|--------|-----------|------------|-----------|---------------|
| CSV | Slow | Slow | Large | No |
| Parquet | Fast | Fast | Small | Column |
| Feather | Fastest | Fastest | Medium | Column |
| HDF5 | Fast | Fast | Medium | Yes |

```python
# Write once, read many times
df.to_parquet("data.parquet", index=False, compression="snappy")
df = pd.read_parquet("data.parquet", columns=["id", "target"])  # Column pruning
```

---

## String Operations

Use `.str` accessor — vectorized C-level operations:

```python
# BAD
df["name"] = df["name"].apply(lambda x: x.upper())

# GOOD
df["name"] = df["name"].str.upper()
```

---

## eval() and query() for Large DataFrames

For DataFrames > 1M rows, `eval` / `query` use Numexpr under the hood:

```python
df.eval("c = a + b", inplace=True)
df.query("age > 30 and salary > 50000")
```

---

## Arrow Backend (pandas ≥ 2.0)

```python
df = pd.read_parquet("data.parquet", dtype_backend="pyarrow")
# Faster string ops, lower memory, nullable by default
```

---

## Memory Audit

```python
def memory_report(df: pd.DataFrame) -> None:
    total_mb = df.memory_usage(deep=True).sum() / 1e6
    print(f"Total: {total_mb:.1f} MB")
    print(df.memory_usage(deep=True).sort_values(ascending=False) / 1e6)

memory_report(df)
```

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| `iterrows()` for transformations | 100–1000x slower | Vectorized ops |
| `apply(func, axis=1)` for math | 10–100x slower | NumPy / pandas ops |
| Load full CSV to use 3 columns | Wastes memory | `usecols=["a","b","c"]` |
| String ops on `object` dtype | Slow | `.str` accessor |
| `df.append` in a loop | O(n²) copies | `pd.concat([...])` once at end |
