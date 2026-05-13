# Indexing and Selection

> `.loc`, `.iloc`, boolean masks, `.query()`, and MultiIndex patterns.

---

## Three Selection Methods

| Method | Selector Type | Example |
|--------|--------------|---------|
| `[]` | Column name / boolean mask | `df["age"]`, `df[mask]` |
| `.loc[r, c]` | **Label**-based | `df.loc[0:5, "age"]` |
| `.iloc[r, c]` | **Position**-based (integer) | `df.iloc[0:5, 2]` |

---

## `.loc` — Label-Based

```python
# Single row by index label
df.loc[42]

# Row range (inclusive on both ends)
df.loc[10:20]

# Row + column
df.loc[df["age"] > 30, ["name", "salary"]]

# Assign safely
df.loc[df["score"].isna(), "score"] = 0
```

---

## `.iloc` — Position-Based

```python
# First 5 rows, first 3 columns
df.iloc[0:5, 0:3]

# Last row
df.iloc[-1]

# Every other row
df.iloc[::2]
```

---

## Boolean Indexing

```python
mask = (df["age"] > 25) & (df["city"] == "NY")
subset = df[mask]

# Multiple values
df[df["status"].isin(["active", "pending"])]

# Negation
df[~df["name"].str.startswith("A")]
```

**Always use `&`, `|`, `~` (not `and`, `or`, `not`) with pandas masks.**

---

## `.query()` — String Expressions

```python
# Clean, readable filtering
df.query("age > 25 and city == 'NY'")

# With Python variables (@ prefix)
threshold = 25
df.query("age > @threshold")

# Columns with spaces
df.query("`first name` == 'Alice'")
```

`.query()` is compiled — often faster than equivalent boolean indexing on large DataFrames.

---

## Column Selection

```python
# Single column → Series
df["age"]

# Multiple columns → DataFrame
df[["name", "age", "salary"]]

# By dtype
df.select_dtypes(include=["number"])
df.select_dtypes(exclude=["object"])

# By pattern
df.filter(like="score")   # columns containing "score"
df.filter(regex=r"^Q\d")  # columns matching regex
```

---

## MultiIndex

```python
# Create
df = df.set_index(["year", "category"])

# Access
df.loc[(2024, "A")]           # Both levels
df.loc[2024]                  # Outer level only
df.xs("A", level="category")  # Cross-section

# Reset
df = df.reset_index()
```

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| `df[df["a"] > 1][["b"]]` | Chain — may return copy | `df.loc[df["a"] > 1, "b"]` |
| Mix `.loc` and positional | Confusing, error-prone | Pick one, be consistent |
| `df.loc[0]` on non-int index | Returns wrong row | Use label that exists in index |
