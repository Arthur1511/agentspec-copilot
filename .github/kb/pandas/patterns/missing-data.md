# Missing Data

> Detect, understand, impute, and flag null values in pandas DataFrames.

---

## Null Types in pandas

| Symbol | Type | Source |
|--------|------|--------|
| `np.nan` | `float` | Default null for numeric columns |
| `pd.NaT` | `datetime` | Null timestamp |
| `pd.NA` | Polymorphic | Nullable dtypes (`Int64`, `boolean`, `string`) |
| `None` | `object` | Python object — stored as-is |

All are detected by `isnull()` / `isna()`.

---

## Step 1: Detect

```python
# Null count per column
df.isnull().sum()

# Null percentage
(df.isnull().sum() / len(df) * 100).round(2)

# Rows with ANY null
df[df.isnull().any(axis=1)]

# Heatmap of nulls (visual)
import seaborn as sns
sns.heatmap(df.isnull(), cbar=False, yticklabels=False)
```

---

## Step 2: Understand the Mechanism

| Mechanism | Meaning | Action |
|-----------|---------|--------|
| **MCAR** (Missing Completely At Random) | No pattern — random data entry | Safe to impute |
| **MAR** (Missing At Random) | Missing depends on observed data | Impute with model |
| **MNAR** (Missing Not At Random) | Missing relates to unobserved value | Flag + investigate |

```python
# Are nulls in 'income' associated with 'age'?
df.groupby(df["income"].isnull())["age"].mean()
```

---

## Step 3: Impute

### Simple Strategies

```python
# Drop rows where target is null
df = df.dropna(subset=["target"])

# Fill with statistic
df["age"]    = df["age"].fillna(df["age"].median())
df["salary"] = df["salary"].fillna(df["salary"].mean())
df["city"]   = df["city"].fillna(df["city"].mode()[0])

# Fill with constant
df["score"].fillna(0)
df["category"].fillna("unknown")

# Forward / backward fill (time-series)
df["price"] = df["price"].ffill().bfill()
```

### Group-Aware Imputation

```python
# Fill with group median
df["salary"] = df["salary"].fillna(
    df.groupby("dept")["salary"].transform("median")
)
```

### scikit-learn Imputers

```python
from sklearn.impute import SimpleImputer, KNNImputer

imp = KNNImputer(n_neighbors=5)
X_imputed = imp.fit_transform(df[numeric_cols])
```

---

## Step 4: Add Missing Indicator

Preserve the information that a value was missing — often predictive.

```python
for col in ["income", "credit_score"]:
    df[f"{col}_missing"] = df[col].isnull().astype("int8")
```

---

## Step 5: Validate

```python
# After imputation — no nulls should remain in expected columns
critical = ["user_id", "target", "age"]
assert df[critical].isnull().sum().sum() == 0
```

---

## Decision Guide

```
Null % < 5%  → Safe to drop rows (if MCAR)
Null % 5-30% → Impute with median/mode + add indicator flag
Null % > 30% → Consider dropping column OR advanced imputation
Target col   → Always drop null target rows (never impute target)
```

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| Impute target variable | Fabricates labels | Drop rows with null target |
| `fillna` with global mean before CV | Leakage | Impute inside Pipeline |
| Drop columns with > 30% nulls reflexively | Useful missingness signal lost | Add indicator, then impute |
| Ignore null mechanism | Wrong imputation strategy | Test MCAR vs MAR first |
| `dropna()` without `subset=` | Drops rows with ANY null | Specify columns explicitly |
