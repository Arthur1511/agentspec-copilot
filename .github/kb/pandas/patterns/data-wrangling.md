# Data Wrangling

> Clean, reshape, and normalize raw tabular data with pandas.

---

## Typical Wrangling Pipeline

```
Load → Inspect → Rename → Cast → Clean → Reshape → Validate → Export
```

---

## 1. Load and Inspect

```python
import pandas as pd

df = pd.read_csv("raw.csv", dtype_backend="numpy_nullable")
print(df.shape)
print(df.dtypes)
print(df.isnull().sum())
print(df.describe(include="all"))
```

---

## 2. Rename and Normalize Column Names

```python
# Lowercase and replace spaces
df.columns = df.columns.str.lower().str.replace(" ", "_").str.strip()

# Explicit renaming
df = df.rename(columns={
    "First Name": "first_name",
    "DOB":        "date_of_birth",
    "Rev$":       "revenue",
})
```

---

## 3. Cast dtypes

```python
df["user_id"]   = df["user_id"].astype("int32")
df["city"]      = df["city"].astype("category")
df["joined_at"] = pd.to_datetime(df["joined_at"], format="%Y-%m-%d")
df["revenue"]   = pd.to_numeric(df["revenue"], errors="coerce")
```

---

## 4. Clean Text Columns

```python
df["email"] = df["email"].str.strip().str.lower()
df["name"]  = df["name"].str.title()
df["phone"] = df["phone"].str.replace(r"\D", "", regex=True)

# Flag bad formats
df["valid_email"] = df["email"].str.match(r"^[\w.+-]+@[\w-]+\.[a-z]{2,}$")
```

---

## 5. Derive New Columns

```python
# Arithmetic
df["bmi"] = df["weight_kg"] / df["height_m"] ** 2

# String combination
df["full_name"] = df["first_name"] + " " + df["last_name"]

# Date parts
df["year"]  = df["joined_at"].dt.year
df["month"] = df["joined_at"].dt.month
df["dow"]   = df["joined_at"].dt.day_name()

# Bucketing
df["age_group"] = pd.cut(
    df["age"],
    bins=[0, 18, 35, 60, 100],
    labels=["child", "young_adult", "adult", "senior"],
)
```

---

## 6. Filter and Deduplicate

```python
# Remove duplicates
df = df.drop_duplicates(subset=["user_id"], keep="last")

# Filter valid records
df = df[df["revenue"] > 0]
df = df.dropna(subset=["target"])

# Reset index after filtering
df = df.reset_index(drop=True)
```

---

## 7. Reshape

```python
# Wide → Long
df_long = df.melt(
    id_vars=["user_id", "date"],
    value_vars=["q1_sales", "q2_sales", "q3_sales", "q4_sales"],
    var_name="quarter",
    value_name="sales",
)

# Long → Wide
df_wide = df_long.pivot_table(
    index="user_id", columns="quarter", values="sales", aggfunc="sum"
).reset_index()
```

---

## 8. Validate and Export

```python
# Sanity checks
assert df["user_id"].is_unique, "Duplicate IDs found"
assert df["revenue"].ge(0).all(), "Negative revenue"
assert df.isnull().sum().sum() == 0, "Remaining nulls"

# Export
df.to_parquet("clean_data.parquet", index=False, compression="snappy")
```

---

## Full Wrangling Template

```python
def wrangle(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)
    df.columns = df.columns.str.lower().str.replace(" ", "_")
    df = df.rename(columns={"dob": "date_of_birth"})
    df["date_of_birth"] = pd.to_datetime(df["date_of_birth"])
    df["city"] = df["city"].astype("category")
    df = df.drop_duplicates(subset=["id"]).reset_index(drop=True)
    df = df.dropna(subset=["target"])
    return df
```

---

## Anti-Patterns

| Never Do | Why | Instead |
|----------|-----|---------|
| Mutate raw file | Lose provenance | Save cleaned copy separately |
| Hardcode column positions | Breaks on schema change | Use column names |
| Skip type casting | Numeric ops fail silently | Cast at load time |
| Forget `reset_index` after filter | Surprises in downstream `.iloc` | Always reset |
