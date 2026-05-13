# Time Series Fundamentals

> **MCP Validated:** 2026-05-08

Core concepts in time series analysis — components (trend, seasonality, residuals), autocorrelation, and proper train/test splitting.

---

## Time Series Components

Every time series can be decomposed into three components:

1. **Trend (T_t):** Long-term increase or decrease in the data
2. **Seasonality (S_t):** Regular patterns that repeat at fixed intervals (daily, weekly, yearly)
3. **Residuals (R_t):** Random noise or irregular component

### Additive vs Multiplicative Decomposition

| Model | Formula | When to Use |
|-------|---------|-------------|
| **Additive** | `Y_t = T_t + S_t + R_t` | Seasonal variation is constant over time |
| **Multiplicative** | `Y_t = T_t × S_t × R_t` | Seasonal variation increases with trend |

---

## STL Decomposition

**STL (Seasonal and Trend decomposition using Loess)** is the most robust decomposition method.

```python
import pandas as pd
from statsmodels.tsa.seasonal import STL

# Load data with datetime index
df = pd.read_csv('data.csv', parse_dates=['date'], index_col='date')
series = df['value']

# Perform STL decomposition
stl = STL(series, seasonal=13)  # seasonal period (13 for monthly with odd number)
result = stl.fit()

# Extract components
trend = result.trend
seasonal = result.seasonal
residual = result.resid

# Plot
import matplotlib.pyplot as plt
fig = result.plot()
plt.tight_layout()
plt.show()
```

**Parameters:**
- `seasonal`: Must be odd; use season length + 1 if even (e.g., 13 for monthly data)
- `trend`: Length of trend smoother (default: `None` → automatic)
- `robust`: If `True`, use robust fitting to handle outliers

---

## Autocorrelation (ACF) and Partial Autocorrelation (PACF)

**Autocorrelation:** Correlation of a time series with its own lagged values.

**ACF (Autocorrelation Function):** Measures correlation at all lags.

**PACF (Partial Autocorrelation Function):** Measures correlation at a specific lag, removing the effect of intermediate lags.

### Why ACF/PACF Matter

Used to identify ARIMA model parameters:
- ACF cuts off at lag q → MA(q) component
- PACF cuts off at lag p → AR(p) component

```python
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
import matplotlib.pyplot as plt

# Plot ACF and PACF
fig, axes = plt.subplots(1, 2, figsize=(12, 4))

plot_acf(series, lags=40, ax=axes[0])
axes[0].set_title('Autocorrelation Function (ACF)')

plot_pacf(series, lags=40, ax=axes[1])
axes[1].set_title('Partial Autocorrelation Function (PACF)')

plt.tight_layout()
plt.show()
```

**Interpretation:**
- Significant lags (outside blue cone) indicate temporal correlation
- Slow decay in ACF → trend present (needs differencing)
- Sharp cutoff in ACF at lag q → MA(q)
- Sharp cutoff in PACF at lag p → AR(p)

---

## Time-Based Train/Test Split (NO SHUFFLING!)

**CRITICAL RULE:** Never shuffle time series data. Always split chronologically.

### Why No Shuffling?

Shuffling creates **data leakage** by allowing the model to train on future data to predict the past.

```python
import pandas as pd

# ✓ CORRECT: Chronological split
train = df[:'2023-01-01']
test = df['2023-01-02':]

# ✓ CORRECT: Percentage-based split
split_idx = int(len(df) * 0.8)
train = df[:split_idx]
test = df[split_idx:]

# ✗ WRONG: Using train_test_split with shuffle
# from sklearn.model_selection import train_test_split
# train, test = train_test_split(df, test_size=0.2, shuffle=True)  # LEAKAGE!
```

### Walk-Forward Validation

For robust evaluation, use walk-forward (expanding window) cross-validation:

```python
from sklearn.model_selection import TimeSeriesSplit

tscv = TimeSeriesSplit(n_splits=5)
for train_idx, val_idx in tscv.split(X):
    X_train, X_val = X[train_idx], X[val_idx]
    y_train, y_val = y[train_idx], y[val_idx]
    
    # Train model
    model.fit(X_train, y_train)
    
    # Validate
    score = model.score(X_val, y_val)
    print(f"Validation score: {score:.4f}")
```

**Gap Parameter:** Add `gap=n` to simulate a forecast horizon (e.g., `gap=7` for 7-day ahead forecasting).

---

## pandas Datetime Index Setup

Proper datetime indexing is essential for time series operations.

```python
import pandas as pd

# Load data with datetime parsing
df = pd.read_csv('data.csv', parse_dates=['date'], index_col='date')

# Or convert after loading
df['date'] = pd.to_datetime(df['date'])
df = df.set_index('date')

# Verify datetime index
print(type(df.index))  # <class 'pandas.core.indexes.datetimes.DatetimeIndex'>

# Sort by time (always!)
df = df.sort_index()

# Handle timezones
df = df.tz_localize('UTC')  # Add timezone
df = df.tz_convert('America/New_York')  # Convert timezone

# Set frequency (fill missing dates)
df = df.asfreq('D')  # Daily frequency, fills missing dates with NaN
```

### Common Frequency Aliases

| Alias | Description | Example |
|-------|-------------|---------|
| `D` | Daily | Business days |
| `B` | Business day | Exclude weekends |
| `W` | Weekly | Every 7 days |
| `M` | Month end | Last day of month |
| `MS` | Month start | First day of month |
| `Q` | Quarter end | Mar 31, Jun 30, etc. |
| `H` | Hourly | Every hour |
| `T` or `min` | Minute | Every minute |

---

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Correct Approach |
|--------------|----------------|------------------|
| Using `train_test_split` with shuffle | Data leakage | Use chronological split |
| Not setting datetime index | Can't use time-based operations | Use `pd.to_datetime()` + `set_index()` |
| Ignoring missing timestamps | Gaps in data break models | Use `.asfreq()` to fill gaps |
| Not checking for stationarity | ARIMA won't converge | Apply ADF test and differencing |

---

## Related

- [stationarity.md](stationarity.md) — ADF/KPSS tests and differencing
- [forecasting-models.md](forecasting-models.md) — Model selection guide
- [feature-engineering-ts.md](feature-engineering-ts.md) — Lag and rolling features
