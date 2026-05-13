# ARIMA Workflow

> **MCP Validated:** 2026-05-08

Complete SARIMA (Seasonal ARIMA) forecasting workflow — from stationarity testing to forecasting with confidence intervals.

---

## Workflow Overview

```
1. Load and visualize data
2. Test for stationarity (ADF test)
3. Apply differencing if needed
4. Identify p, q from ACF/PACF plots
5. Fit SARIMA model
6. Diagnose residuals (Ljung-Box test)
7. Forecast with confidence intervals
8. Plot actual vs forecast
```

---

## Step 1: Load and Visualize Data

```python
import pandas as pd
import matplotlib.pyplot as plt

# Load data with datetime index
df = pd.read_csv('data.csv', parse_dates=['date'], index_col='date')
series = df['value']

# Plot the series
plt.figure(figsize=(12, 4))
plt.plot(series)
plt.title('Original Time Series')
plt.xlabel('Date')
plt.ylabel('Value')
plt.grid(True)
plt.show()
```

---

## Step 2: Test for Stationarity

```python
from statsmodels.tsa.stattools import adfuller, kpss

def check_stationarity(series):
    """Perform ADF and KPSS tests."""
    # ADF test
    adf_result = adfuller(series, autolag='AIC')
    print("ADF Test:")
    print(f"  ADF Statistic: {adf_result[0]:.6f}")
    print(f"  p-value: {adf_result[1]:.6f}")
    if adf_result[1] < 0.05:
        print("  → Series is stationary (p < 0.05)")
    else:
        print("  → Series is non-stationary (p ≥ 0.05) - apply differencing")
    
    # KPSS test
    kpss_result = kpss(series, regression='c', nlags='auto')
    print("\nKPSS Test:")
    print(f"  KPSS Statistic: {kpss_result[0]:.6f}")
    print(f"  p-value: {kpss_result[1]:.6f}")
    if kpss_result[1] > 0.05:
        print("  → Series is stationary (p > 0.05)")
    else:
        print("  → Series is non-stationary (p ≤ 0.05)")
    
    return adf_result[1]

# Check original series
p_value = check_stationarity(series)
```

---

## Step 3: Apply Differencing if Needed

```python
# If non-stationary, apply first-order differencing
if p_value >= 0.05:
    series_diff = series.diff().dropna()
    print("\nAfter first-order differencing:")
    check_stationarity(series_diff)
    
    # For seasonal data, apply seasonal differencing
    seasonal_period = 12  # e.g., monthly data
    series_seasonal = series.diff(periods=seasonal_period).dropna()
    print(f"\nAfter seasonal differencing (period={seasonal_period}):")
    check_stationarity(series_seasonal)
else:
    series_diff = series
```

---

## Step 4: Identify p, q from ACF/PACF

```python
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf

# Plot ACF and PACF
fig, axes = plt.subplots(1, 2, figsize=(14, 4))

plot_acf(series_diff, lags=40, ax=axes[0])
axes[0].set_title('ACF (Autocorrelation Function)')

plot_pacf(series_diff, lags=40, ax=axes[1])
axes[1].set_title('PACF (Partial Autocorrelation Function)')

plt.tight_layout()
plt.show()

# Interpretation guide:
# - ACF cuts off at lag q → MA(q)
# - PACF cuts off at lag p → AR(p)
# - Both decay exponentially → ARMA(p, q)
```

**Example Interpretations:**
- PACF cuts off after lag 1, ACF decays → AR(1)
- ACF cuts off after lag 1, PACF decays → MA(1)
- Both decay slowly → Need more differencing (d)

---

## Step 5: Fit SARIMA Model

```python
from statsmodels.tsa.statespace.sarimax import SARIMAX

# Define SARIMA parameters
# SARIMA(p, d, q)(P, D, Q, s)
# p, d, q: Non-seasonal parameters
# P, D, Q: Seasonal parameters
# s: Seasonal period (12 for monthly, 7 for daily with weekly seasonality)

order = (1, 1, 1)              # (p, d, q)
seasonal_order = (1, 1, 1, 12) # (P, D, Q, s)

# Fit model
model = SARIMAX(series, 
                order=order, 
                seasonal_order=seasonal_order,
                enforce_stationarity=False,
                enforce_invertibility=False)

fitted_model = model.fit(disp=False)

# Print summary
print(fitted_model.summary())
```

**Parameter Tuning:**

```python
# Grid search for best parameters (AIC-based)
import itertools

def fit_sarima_grid(series, p_range, d_range, q_range, 
                    P_range, D_range, Q_range, s):
    """Grid search for best SARIMA parameters."""
    best_aic = float('inf')
    best_params = None
    
    # Generate all combinations
    pdq = list(itertools.product(p_range, d_range, q_range))
    PDQs = list(itertools.product(P_range, D_range, Q_range, [s]))
    
    for param in pdq:
        for param_seasonal in PDQs:
            try:
                model = SARIMAX(series, 
                                order=param, 
                                seasonal_order=param_seasonal,
                                enforce_stationarity=False,
                                enforce_invertibility=False)
                results = model.fit(disp=False)
                
                if results.aic < best_aic:
                    best_aic = results.aic
                    best_params = (param, param_seasonal)
                    
                print(f'SARIMA{param}x{param_seasonal} - AIC:{results.aic:.2f}')
            except:
                continue
    
    print(f'\nBest model: SARIMA{best_params[0]}x{best_params[1]} - AIC:{best_aic:.2f}')
    return best_params

# Example: Search over limited grid
best_params = fit_sarima_grid(
    series,
    p_range=[0, 1, 2],
    d_range=[0, 1],
    q_range=[0, 1, 2],
    P_range=[0, 1],
    D_range=[0, 1],
    Q_range=[0, 1],
    s=12
)
```

---

## Step 6: Diagnose Residuals

```python
from statsmodels.stats.diagnostic import acorr_ljungbox

# Extract residuals
residuals = fitted_model.resid

# Plot residuals
fig, axes = plt.subplots(2, 2, figsize=(14, 8))

# 1. Residuals over time
axes[0, 0].plot(residuals)
axes[0, 0].set_title('Residuals Over Time')
axes[0, 0].axhline(0, linestyle='--', color='red')

# 2. Residuals distribution
axes[0, 1].hist(residuals, bins=30, edgecolor='black')
axes[0, 1].set_title('Residuals Distribution')

# 3. ACF of residuals
plot_acf(residuals, lags=40, ax=axes[1, 0])
axes[1, 0].set_title('ACF of Residuals')

# 4. Q-Q plot
from scipy import stats
stats.probplot(residuals, dist="norm", plot=axes[1, 1])
axes[1, 1].set_title('Q-Q Plot')

plt.tight_layout()
plt.show()

# Ljung-Box test (test for autocorrelation in residuals)
lb_test = acorr_ljungbox(residuals, lags=[10, 20, 30], return_df=True)
print("\nLjung-Box Test (p-values should be > 0.05 for white noise):")
print(lb_test)
```

**Good Residuals Should:**
1. Have mean close to zero
2. Be normally distributed (Q-Q plot is linear)
3. Have no autocorrelation (ACF within blue cone, Ljung-Box p > 0.05)
4. Have constant variance (no fanning pattern)

---

## Step 7: Forecast with Confidence Intervals

```python
# Forecast 12 steps ahead
n_steps = 12
forecast_result = fitted_model.get_forecast(steps=n_steps)

# Extract forecast and confidence intervals
forecast = forecast_result.predicted_mean
conf_int = forecast_result.conf_int()

# Create forecast index
last_date = series.index[-1]
forecast_index = pd.date_range(start=last_date + pd.Timedelta(days=1), 
                                periods=n_steps, freq='D')

forecast_df = pd.DataFrame({
    'forecast': forecast.values,
    'lower': conf_int.iloc[:, 0].values,
    'upper': conf_int.iloc[:, 1].values
}, index=forecast_index)

print("\nForecast:")
print(forecast_df)
```

---

## Step 8: Plot Actual vs Forecast

```python
# Plot historical + forecast
plt.figure(figsize=(14, 6))

# Historical data
plt.plot(series.index, series.values, label='Historical', color='black')

# Forecast
plt.plot(forecast_df.index, forecast_df['forecast'], 
         label='Forecast', color='blue', linestyle='--')

# Confidence interval
plt.fill_between(forecast_df.index, 
                 forecast_df['lower'], 
                 forecast_df['upper'], 
                 alpha=0.2, color='blue', label='95% CI')

plt.title('SARIMA Forecast with 95% Confidence Interval')
plt.xlabel('Date')
plt.ylabel('Value')
plt.legend()
plt.grid(True)
plt.show()
```

---

## Complete Production Pipeline

```python
def sarima_forecast_pipeline(series, order, seasonal_order, n_steps=12):
    """
    Complete SARIMA forecasting pipeline.
    
    Parameters
    ----------
    series : pd.Series
        Time series with datetime index
    order : tuple
        (p, d, q)
    seasonal_order : tuple
        (P, D, Q, s)
    n_steps : int
        Number of steps to forecast
    
    Returns
    -------
    forecast_df : pd.DataFrame
        Forecast with confidence intervals
    fitted_model : SARIMAXResults
        Fitted model object
    """
    # 1. Fit model
    model = SARIMAX(series, order=order, seasonal_order=seasonal_order,
                    enforce_stationarity=False, enforce_invertibility=False)
    fitted_model = model.fit(disp=False)
    
    # 2. Forecast
    forecast_result = fitted_model.get_forecast(steps=n_steps)
    forecast = forecast_result.predicted_mean
    conf_int = forecast_result.conf_int()
    
    # 3. Create forecast DataFrame
    last_date = series.index[-1]
    forecast_index = pd.date_range(start=last_date + pd.Timedelta(days=1), 
                                    periods=n_steps, freq=series.index.freq)
    
    forecast_df = pd.DataFrame({
        'forecast': forecast.values,
        'lower_ci': conf_int.iloc[:, 0].values,
        'upper_ci': conf_int.iloc[:, 1].values
    }, index=forecast_index)
    
    return forecast_df, fitted_model

# Usage
forecast_df, model = sarima_forecast_pipeline(
    series, 
    order=(1, 1, 1), 
    seasonal_order=(1, 1, 1, 12),
    n_steps=12
)
```

---

## Related

- [stationarity.md](../concepts/stationarity.md) — ADF/KPSS tests
- [ts-fundamentals.md](../concepts/ts-fundamentals.md) — ACF/PACF interpretation
- [evaluation-ts.md](evaluation-ts.md) — Forecast evaluation metrics
