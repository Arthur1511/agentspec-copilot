# Merge and Join

> Combine DataFrames with merge, join, concat — selecting the right strategy.

---

## merge() — Relational Joins

`pd.merge()` or `df.merge()` — mirrors SQL JOIN semantics.

```python
result = df1.merge(df2, on="key", how="inner")
```

| `how` | Equivalent | Keeps |
|-------|-----------|-------|
| `"inner"` | INNER JOIN | Only matching rows |
| `"left"` | LEFT JOIN | All of left + matches from right |
| `"right"` | RIGHT JOIN | All of right + matches from left |
| `"outer"` | FULL OUTER JOIN | All rows, NaN where no match |
| `"cross"` | CROSS JOIN | Cartesian product |

---

## Key Variations

```python
# Different column names
df1.merge(df2, left_on="user_id", right_on="id")

# Multiple keys
df1.merge(df2, on=["user_id", "date"])

# Merge on index
df1.merge(df2, left_index=True, right_on="id")
df1.merge(df2, left_index=True, right_index=True)

# Suffix for overlapping columns (not key)
df1.merge(df2, on="id", suffixes=("_left", "_right"))
```

---

## Diagnosing Merge Issues

```python
# Check for unexpected row explosion (many-to-many)
before = len(df1)
result = df1.merge(df2, on="key", how="left")
after  = len(result)
if after != before:
    print(f"Rows grew: {before} → {after}. Check for duplicate keys in df2.")

# validate parameter (pandas ≥ 0.21)
df1.merge(df2, on="id", validate="one_to_one")   # Raises if not unique
df1.merge(df2, on="id", validate="many_to_one")
```

---

## concat() — Stack DataFrames

```python
# Stack rows (same schema)
combined = pd.concat([df_jan, df_feb, df_mar], ignore_index=True)

# Stack columns (same index)
combined = pd.concat([df_features, df_targets], axis=1)

# With source label
combined = pd.concat([df1, df2], keys=["train", "test"])
```

**Use `concat` for same-schema stacking; `merge` for relational lookups.**

---

## join() — Index-Based Shortcut

```python
# Left join on index
result = df1.join(df2, how="left")

# Join on a column of the left
result = df1.set_index("id").join(df2.set_index("user_id"), how="left")
```

---

## Lookup Pattern (Map Instead of Merge)

For simple column enrichment, `map` is faster than `merge`:

```python
# Avoid
df = df.merge(mapping_df[["id", "label"]], on="id", how="left")

# Prefer (for simple 1:1 lookups)
label_map = mapping_df.set_index("id")["label"]
df["label"] = df["id"].map(label_map)
```

---

## Deduplication After Join

After a left join, always check for unexpected duplicates:

```python
df = df.drop_duplicates(subset=["primary_key"]).reset_index(drop=True)
```

---

## Performance

| Strategy | When to Use |
|---------|-------------|
| `merge` | General purpose, small-medium DataFrames |
| `map` / `replace` | Simple 1:1 key→value lookup |
| `join` on index | When both sides are indexed by the same key |
| Sort before merge | Large DataFrames with sorted keys |

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| Merge without checking key uniqueness | Silent row duplication | Use `validate=` |
| `pd.concat` with mismatched columns | NaN explosion | Align schemas first |
| Merge on `object` dtype keys | Slow string comparison | Cast to `category` or integer |
| Ignore NaN rows after left join | Unintended nulls downstream | Check with `.isnull().sum()` |
