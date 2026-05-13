# Stationarity

> **MCP Validated:** 2026-05-08

Stationarity is a fundamental assumption for many time series models (especially ARIMA). A stationary series has constant statistical properties over time.

---

## What is Stationarity?

A time series is **stationary** if:

1. **Constant mean:** The average value doesn't change over time
2. **Constant variance:** The spread around the mean doesn't change over time
3. **Constant autocorrelation:** The correlation structure doesn't depend on time, only on lag

**Why It Matters:**
- ARIMA models assume stationarity
- Non-stationary series lead to spurious regressions
- Forecasts from non-stationary models are unreliable

---

## Visual Inspection

```python
import matplotlib.pyplot as plt

# Plot the series
plt.figure(figsize=(12, 4))
plt.plot(series)
plt.title('Time Series Plot')
plt.xlabel('Time')
plt.ylabel('Value')
plt.show()

# Check for:
# - Trend (upward/downward slope) → non-stationary
# - Changing variance (widening/narrowing spread) → non-stationary
# - Seasonal patterns → may be trend-stationary
```

---

## Augmented Dickey-Fuller (ADF) Test

The ADF test is the most common stationarity test.

**Null Hypothesis (H₀):** The series has a unit root (non-stationary).

**Interpretation:**
- **p-value < 0.05** → Reject H₀ → Series is stationary
- **p-value ≥ 0.05** → Fail to reject H₀ → Series is non-stationary

```python
from statsmodels.tsa.stattools import adfuller

def adf_test(series, name=''):
    """Perform Augmented Dickey-Fuller test."""
    result = adfuller(series, autolag='AIC')
    
    print(f'ADF Test Results for {name}:')
    print(f'  ADF Statistic: {result[0]:.6f}')
    print(f'  p-value: {result[1]:.6f}')
    print(f'  Critical Values:')
    for key, value in result[4].items():
        print(f'    {key}: {value:.3f}')
    
    if result[1] <= 0.05:
        print("  → Reject H₀: Series is stationary (p < 0.05)")
    else:
        print("  → Fail to reject H₀: Series is non-stationary (p ≥ 0.05)")
    
    return result[1]  # Return p-value

# Example usage
p_value = adf_test(series, name='Original Series')
```

**Parameters:**
- `autolag='AIC'`: Automatically select number of lags using Akaike Information Criterion (recommended)
- `regression='c'`: Include constant (default); use `'ct'` for constant + trend

---

## KPSS Test (Complement to ADF)

The KPSS test checks for trend stationarity and complements ADF.

**Null Hypothesis (H₀):** The series is trend-stationary.

**Interpretation:**
- **p-value > 0.05** → Series is stationary
- **p-value ≤ 0.05** → Series is non-stationary

```python
from statsmodels.tsa.stattools import kpss

def kpss_test(series, name=''):
    """Perform KPSS test."""
    result = kpss(series, regression='c', nlags='auto')
    
    print(f'KPSS Test Results for {name}:')
    print(f'  KPSS Statistic: {result[0]:.6f}')
    print(f'  p-value: {result[1]:.6f}')
    print(f'  Critical Values:')
    for key, value in result[3].items():
        print(f'    {key}: {value:.3f}')
    
    if result[1] >= 0.05:
        print("  → Series is stationary (p > 0.05)")
    else:
        print("  → Series is non-stationary (p ≤ 0.05)")
    
    return result[1]

# Example usage
kpss_test(series, name='Original Series')
```

**Parameters:**
- `regression='c'`: Test for level stationarity (default)
- `regression='ct'`: Test for trend stationarity

---

## Combined ADF + KPSS Strategy

| ADF Result | KPSS Result | Interpretation | Action |
|------------|-------------|----------------|--------|
| Stationary | Stationary | **Stationary** | No differencing needed |
| Non-stationary | Stationary | **Trend-stationary** | Detrend or difference |
| Stationary | Non-stationary | **Difference-stationary** | Difference once |
| Non-stationary | Non-stationary | **Non-stationary** | Difference and retest |

---

## Differencing to Achieve Stationarity

**First-order differencing:** Remove trend by subtracting previous value.

```python
import pandas as pd

# First-order differencing
series_diff = series.diff().dropna()

# Check stationarity
adf_test(series_diff, name='First-Differenced Series')

# If still non-stationary, apply second-order differencing
series_diff2 = series_diff.diff().dropna()
adf_test(series_diff2, name='Second-Differenced Series')
```

**Seasonal differencing:** Remove seasonal patterns.

```python
# Seasonal differencing (e.g., lag=12 for monthly data)
series_seasonal_diff = series.diff(periods=12).dropna()
adf_test(series_seasonal_diff, name='Seasonal-Differenced Series')

# Combined: First + seasonal differencing
series_combined = series.diff().diff(periods=12).dropna()
adf_test(series_combined, name='Combined-Differenced Series')
```

**Warning:** Avoid over-differencing (differencing more than needed) as it introduces unnecessary complexity.

---

## Auto-Differencing Function

```python
def make_stationary(series, max_diff=2, seasonal_period=None):
    """
    Automatically difference series until stationary (ADF p-value < 0.05).
    
    Parameters
    ----------
    series : pd.Series
        Time series to make stationary
    max_diff : int
        Maximum number of differencing orders
    seasonal_period : int, optional
        Apply seasonal differencing with this period
    
    Returns
    -------
    stationary_series : pd.Series
        Differenced series
    d : int
        Number of regular differences applied
    D : int
        Number of seasonal differences applied
    """
    d = 0
    D = 0
    current_series = series.copy()
    
    # Apply seasonal differencing first if specified
    if seasonal_period is not None:
        adf_p = adfuller(current_series, autolag='AIC')[1]
        if adf_p >= 0.05:
            current_series = current_series.diff(periods=seasonal_period).dropna()
            D = 1
    
    # Apply regular differencing
    for i in range(max_diff):
        adf_p = adfuller(current_series, autolag='AIC')[1]
        if adf_p < 0.05:
            print(f"Stationary after {d} regular and {D} seasonal differences (p={adf_p:.4f})")
            return current_series, d, D
        
        current_series = current_series.diff().dropna()
        d += 1
    
    print(f"Warning: Series may not be stationary after {d} differences")
    return current_series, d, D

# Example usage
stationary_series, d, D = make_stationary(series, seasonal_period=12)
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Correct Approach |
|--------------|----------------|------------------|
| Not testing for stationarity | ARIMA may not converge or produce bad forecasts | Always run ADF test before ARIMA |
| Using only ADF test | ADF has low power in some cases | Use both ADF and KPSS |
| Over-differencing | Introduces MA components unnecessarily | Difference until stationary, then stop |
| Ignoring seasonal non-stationarity | Model misses seasonal patterns | Apply seasonal differencing |

---

## Related

- [ts-fundamentals.md](ts-fundamentals.md) — Time series components and ACF/PACF
- [arima-workflow.md](../patterns/arima-workflow.md) — Using stationarity tests in ARIMA pipeline
- [forecasting-models.md](forecasting-models.md) — Model selection based on stationarity
