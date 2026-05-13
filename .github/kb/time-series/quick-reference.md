# Time Series Quick Reference

> **MCP Validated:** 2026-05-08

Fast lookup tables for time series testing, model selection, evaluation metrics, and common pitfalls.

---

## Stationarity Test Selection

| Test | Purpose | Null Hypothesis | Interpretation |
|------|---------|-----------------|----------------|
| **ADF (Augmented Dickey-Fuller)** | Detect unit root | Series has unit root (non-stationary) | p < 0.05 → stationary |
| **KPSS** | Detect trend stationarity | Series is trend-stationary | p > 0.05 → stationary |
| **Ljung-Box** | Test autocorrelation | No autocorrelation in residuals | p > 0.05 → no autocorrelation |

**Rule of Thumb:** Use both ADF and KPSS together for robust stationarity assessment.

---

## Model Selection Decision Matrix

| Scenario | Best Model | Reason |
|----------|------------|--------|
| **Short series (<100 obs) + seasonality** | SARIMA | Statistical model works well with limited data |
| **Long series + multiple seasonalities** | Prophet | Handles daily/weekly/yearly seasonality natively |
| **Large dataset + exogenous features** | LightGBM/XGBoost | ML models leverage features effectively |
| **Need prediction intervals** | Prophet or Conformal Prediction | Native uncertainty quantification |
| **Need interpretability** | ARIMA | Clear AR/MA components |
| **High-frequency data (minute/second)** | ML-based (with lag features) | Scalable and flexible |

---

## Evaluation Metrics

| Metric | Formula | Use Case | Best Value |
|--------|---------|----------|------------|
| **MAE** | `mean(abs(actual - predicted))` | Interpretable, robust to outliers | Lower |
| **MAPE** | `mean(abs((actual - predicted) / actual)) * 100` | Percentage error (avoid if actual has zeros) | Lower |
| **RMSE** | `sqrt(mean((actual - predicted)^2))` | Penalizes large errors | Lower |
| **MASE** | MAE / naive forecast MAE | Scale-independent, compares to baseline | <1.0 is better than naive |
| **Coverage** | Fraction of actuals in prediction interval | For probabilistic forecasts | 95% for 95% CI |

**Note:** MASE is preferred for comparing models across different scales.

---

## Time Series Split — NO SHUFFLING RULE

```python
from sklearn.model_selection import TimeSeriesSplit

# ✓ CORRECT: Time-based split (no shuffling)
tscv = TimeSeriesSplit(n_splits=5)
for train_idx, val_idx in tscv.split(X):
    X_train, X_val = X[train_idx], X[val_idx]
    y_train, y_val = y[train_idx], y[val_idx]
    # Train model...

# ✗ WRONG: Never use train_test_split with shuffle=True
# from sklearn.model_selection import train_test_split
# X_train, X_test, y_train, y_test = train_test_split(X, y, shuffle=True)  # LEAKAGE!
```

**Gap Parameter:** Add `gap=` parameter to simulate forecast horizon and prevent leakage.

---

## Common Pitfalls

| Mistake | Symptom | Solution |
|---------|---------|----------|
| **Data leakage (using future data)** | Unrealistically high accuracy | Use TimeSeriesSplit, never shuffle |
| **Not removing trend before modeling** | ARIMA doesn't converge | Apply differencing after ADF test |
| **Forgetting timezone alignment** | Seasonal patterns off by hours | Use `.tz_localize()` or `.tz_convert()` |
| **Using MAPE with zero values** | Division by zero errors | Use MAE or RMSE instead |
| **No baseline comparison** | Can't tell if model is good | Always compare to naive and seasonal naive |
| **Overfitting on train set** | Great train metrics, poor test | Use walk-forward validation |
| **Not checking residuals** | Model misses patterns | Plot ACF of residuals, use Ljung-Box test |

---

## Lag Feature Creation (No Leakage!)

```python
import pandas as pd

# ✓ CORRECT: Only use past values
df['lag_1'] = df['value'].shift(1)      # Yesterday's value
df['lag_7'] = df['value'].shift(7)      # Last week's value
df['rolling_mean_7'] = df['value'].shift(1).rolling(window=7).mean()  # Past 7-day avg

# ✗ WRONG: Rolling without shift() uses current value (leakage!)
# df['rolling_mean_7'] = df['value'].rolling(window=7).mean()  # INCLUDES CURRENT ROW!
```

**Critical:** Always `.shift()` before creating rolling features to avoid leakage.

---

## ARIMA Order Selection

| Component | Parameter | ACF Behavior | PACF Behavior |
|-----------|-----------|--------------|---------------|
| **AR (p)** | Autoregressive order | Decays exponentially | Cuts off after lag p |
| **I (d)** | Differencing order | Check ADF test | Difference until stationary |
| **MA (q)** | Moving average order | Cuts off after lag q | Decays exponentially |

**Seasonal ARIMA:** Add `(P, D, Q, s)` for seasonal component where `s` is season length (12 for monthly, 7 for daily).

---

## Prophet Components

```python
from prophet import Prophet

model = Prophet(
    seasonality_mode='multiplicative',  # or 'additive'
    daily_seasonality=False,            # Disable if not daily data
    weekly_seasonality=True,            # Enable for weekly patterns
    yearly_seasonality=True,            # Enable for yearly patterns
)

# Add custom seasonality
model.add_seasonality(name='monthly', period=30.5, fourier_order=5)

# Add holidays
model.add_country_holidays(country_name='US')
```

---

## Training Checklist

```python
# ✓ 1. Check datetime index
assert isinstance(df.index, pd.DatetimeIndex), "Must have DatetimeIndex"

# ✓ 2. Check for missing timestamps
assert df.index.is_monotonic_increasing, "Index must be sorted"
df = df.asfreq('D')  # Fill missing dates

# ✓ 3. Test stationarity
from statsmodels.tsa.stattools import adfuller
adf_stat, p_value = adfuller(df['value'])[:2]
if p_value > 0.05:
    df['value_diff'] = df['value'].diff()  # Apply differencing

# ✓ 4. Split without shuffling
train = df[:'2023-01-01']
test = df['2023-01-02':]

# ✓ 5. Train and forecast
# (Use appropriate model)

# ✓ 6. Evaluate with multiple metrics
from sklearn.metrics import mean_absolute_error, mean_squared_error
mae = mean_absolute_error(y_test, y_pred)
rmse = mean_squared_error(y_test, y_pred, squared=False)
```

---

## Related

- [ts-fundamentals.md](concepts/ts-fundamentals.md) — Core time series concepts
- [arima-workflow.md](patterns/arima-workflow.md) — Statistical forecasting pipeline
- [ml-forecasting.md](patterns/ml-forecasting.md) — ML-based approach
- [evaluation-ts.md](patterns/evaluation-ts.md) — Comprehensive evaluation framework
