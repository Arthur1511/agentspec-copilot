# Feature Engineering for Time Series

> **MCP Validated:** 2026-05-08

Feature engineering for time series forecasting with ML models. CRITICAL: All features must use only past data to avoid data leakage.

---

## Lag Features (Past Values)

**Lag features** are the most important features for time series ML models.

**Rule:** Only use values from the past (shift by at least 1 timestep).

```python
import pandas as pd

# ✓ CORRECT: Create lag features (use past values only)
df['lag_1'] = df['value'].shift(1)   # Yesterday
df['lag_2'] = df['value'].shift(2)   # 2 days ago
df['lag_7'] = df['value'].shift(7)   # 1 week ago
df['lag_30'] = df['value'].shift(30) # 1 month ago

# Remove rows with NaN (can't train on these)
df = df.dropna()

# ✗ WRONG: Using current value (data leakage!)
# df['lag_0'] = df['value']  # LEAKAGE!
```

**Choosing Lags:**
- Use ACF/PACF plots to identify significant lags
- Include lags at seasonal periods (7 for weekly, 12 for monthly)
- Start with recent lags (1, 2, 3) and seasonal lags

---

## Rolling Window Statistics

**Rolling features** capture recent trends and volatility.

**CRITICAL:** Always `.shift(1)` before rolling to avoid leakage.

```python
# ✓ CORRECT: Rolling features (exclude current value)
df['rolling_mean_7'] = df['value'].shift(1).rolling(window=7).mean()
df['rolling_std_7'] = df['value'].shift(1).rolling(window=7).std()
df['rolling_min_7'] = df['value'].shift(1).rolling(window=7).min()
df['rolling_max_7'] = df['value'].shift(1).rolling(window=7).max()

# ✗ WRONG: Rolling without shift (includes current value)
# df['rolling_mean_7'] = df['value'].rolling(window=7).mean()  # LEAKAGE!
```

**Common Rolling Windows:**
- Short-term: 3, 7 days (capture recent trend)
- Medium-term: 14, 30 days (capture seasonal patterns)
- Long-term: 90, 365 days (capture annual trends)

### Exponentially Weighted Features

```python
# Exponential moving average (more weight on recent values)
df['ema_7'] = df['value'].shift(1).ewm(span=7, adjust=False).mean()
df['ema_30'] = df['value'].shift(1).ewm(span=30, adjust=False).mean()
```

---

## Date/Time Features

Extract cyclical patterns from timestamps.

```python
import pandas as pd

# Ensure datetime index
df.index = pd.to_datetime(df.index)

# Basic date features
df['hour'] = df.index.hour
df['dayofweek'] = df.index.dayofweek  # 0=Monday, 6=Sunday
df['day'] = df.index.day
df['month'] = df.index.month
df['quarter'] = df.index.quarter
df['year'] = df.index.year

# Binary features
df['is_weekend'] = (df.index.dayofweek >= 5).astype(int)
df['is_month_start'] = df.index.is_month_start.astype(int)
df['is_month_end'] = df.index.is_month_end.astype(int)

# Cyclical encoding (for hour, month, dayofweek)
import numpy as np

df['hour_sin'] = np.sin(2 * np.pi * df.index.hour / 24)
df['hour_cos'] = np.cos(2 * np.pi * df.index.hour / 24)

df['month_sin'] = np.sin(2 * np.pi * df.index.month / 12)
df['month_cos'] = np.cos(2 * np.pi * df.index.month / 12)
```

**Why Cyclical Encoding?**
- Captures the cyclical nature of time (December is close to January)
- Prevents model from treating month 12 as "greater" than month 1

---

## Holiday Features

```python
import pandas as pd
from pandas.tseries.holiday import USFederalHolidayCalendar

# US holidays
cal = USFederalHolidayCalendar()
holidays = cal.holidays(start='2020-01-01', end='2025-12-31')

df['is_holiday'] = df.index.isin(holidays).astype(int)

# Days until next holiday / days since last holiday
df['days_to_holiday'] = (holidays.searchsorted(df.index) - df.index).days
df['days_since_holiday'] = (df.index - holidays[holidays < df.index][-1]).days
```

**Custom Holidays:**
```python
# Add custom events
custom_events = pd.to_datetime(['2023-12-25', '2024-01-01'])
df['is_custom_event'] = df.index.isin(custom_events).astype(int)
```

---

## Target Encoding for Categorical Variables

**Target encoding:** Replace category with mean of target variable for that category.

```python
# Example: Encoding store_id based on historical sales
train_mean_by_store = train.groupby('store_id')['sales'].mean()

# Apply encoding (use train statistics on both train and test)
df['store_id_encoded'] = df['store_id'].map(train_mean_by_store)

# Handle unseen categories
df['store_id_encoded'] = df['store_id_encoded'].fillna(train['sales'].mean())
```

**Warning:** Only compute statistics on training data to avoid leakage.

---

## Complete Feature Engineering Pipeline

```python
import pandas as pd
import numpy as np

def create_ts_features(df, target_col='value', lags=[1, 2, 7, 14, 30], 
                       rolling_windows=[7, 30]):
    """
    Create time series features for ML forecasting.
    
    Parameters
    ----------
    df : pd.DataFrame
        DataFrame with datetime index and target column
    target_col : str
        Name of target column
    lags : list
        List of lag values to create
    rolling_windows : list
        List of rolling window sizes
    
    Returns
    -------
    df_features : pd.DataFrame
        DataFrame with engineered features
    """
    df = df.copy()
    
    # 1. Lag features (CRITICAL: shift to avoid leakage)
    for lag in lags:
        df[f'lag_{lag}'] = df[target_col].shift(lag)
    
    # 2. Rolling statistics (CRITICAL: shift before rolling)
    for window in rolling_windows:
        df[f'rolling_mean_{window}'] = df[target_col].shift(1).rolling(window).mean()
        df[f'rolling_std_{window}'] = df[target_col].shift(1).rolling(window).std()
        df[f'rolling_min_{window}'] = df[target_col].shift(1).rolling(window).min()
        df[f'rolling_max_{window}'] = df[target_col].shift(1).rolling(window).max()
    
    # 3. Date/time features
    df['hour'] = df.index.hour
    df['dayofweek'] = df.index.dayofweek
    df['day'] = df.index.day
    df['month'] = df.index.month
    df['quarter'] = df.index.quarter
    df['is_weekend'] = (df.index.dayofweek >= 5).astype(int)
    
    # Cyclical encoding
    df['month_sin'] = np.sin(2 * np.pi * df.index.month / 12)
    df['month_cos'] = np.cos(2 * np.pi * df.index.month / 12)
    
    # 4. Remove rows with NaN (from lag/rolling features)
    df = df.dropna()
    
    return df

# Usage
df_features = create_ts_features(df, target_col='sales', 
                                  lags=[1, 7, 14, 28], 
                                  rolling_windows=[7, 14, 28])
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Correct Approach |
|--------------|----------------|------------------|
| **Rolling without shift** | Uses current value (leakage) | Always `.shift(1)` before `.rolling()` |
| **Using lag_0** | Uses current target value (leakage) | Start with `lag_1` (yesterday) |
| **Target encoding on full dataset** | Uses test data statistics (leakage) | Compute on train set only |
| **Not removing NaN rows** | Model can't train on missing values | `.dropna()` after feature creation |
| **Using linear time feature** | Doesn't capture cyclical nature | Use sin/cos encoding for time |

---

## Related

- [ml-forecasting.md](../patterns/ml-forecasting.md) — Complete ML forecasting pipeline
- [ts-fundamentals.md](ts-fundamentals.md) — ACF/PACF for lag selection
- [evaluation-ts.md](../patterns/evaluation-ts.md) — Validating features don't cause leakage
