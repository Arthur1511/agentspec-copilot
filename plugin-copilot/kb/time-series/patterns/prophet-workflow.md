# Prophet Workflow

> **MCP Validated:** 2026-05-08

Complete forecasting workflow using Facebook Prophet for business time series with seasonality, holidays, and special events.

---

## When to Use Prophet

**Best For:**
- Business time series (sales, website traffic, etc.)
- Multiple seasonalities (daily + weekly + yearly)
- Missing data or irregular timestamps
- Need to incorporate holidays and special events
- Non-technical stakeholders need interpretable components

**Avoid When:**
- Data is stationary without clear trend/seasonality
- High-frequency data (second-level) — too slow
- Need fastest possible inference (use ARIMA or ML instead)

---

## Step 1: Install and Import Prophet

```python
# Install Prophet
# pip install prophet

from prophet import Prophet
import pandas as pd
import matplotlib.pyplot as plt
```

---

## Step 2: Prepare Data

Prophet requires a DataFrame with two columns:
- `ds`: datetime column (date stamp)
- `y`: numeric target column

```python
# Load data
df = pd.read_csv('data.csv', parse_dates=['date'])

# Rename columns to 'ds' and 'y' (REQUIRED by Prophet)
df = df.rename(columns={'date': 'ds', 'sales': 'y'})

# Ensure ds is datetime
df['ds'] = pd.to_datetime(df['ds'])

# Sort by date
df = df.sort_values('ds').reset_index(drop=True)

print(df.head())
```

**Example DataFrame:**
```
         ds      y
0 2020-01-01  120.5
1 2020-01-02  135.2
2 2020-01-03  128.7
```

---

## Step 3: Create and Configure Model

```python
# Basic model
model = Prophet()

# Advanced configuration
model = Prophet(
    growth='linear',              # 'linear' or 'logistic' (for capped growth)
    seasonality_mode='multiplicative',  # 'additive' or 'multiplicative'
    yearly_seasonality=True,      # Auto-detect yearly pattern
    weekly_seasonality=True,      # Auto-detect weekly pattern
    daily_seasonality=False,      # Disable if not daily data
    changepoint_prior_scale=0.05, # Flexibility of trend (default: 0.05, higher = more flexible)
    seasonality_prior_scale=10.0  # Strength of seasonality (default: 10.0)
)
```

**Parameter Guide:**

| Parameter | Default | Use Case |
|-----------|---------|----------|
| `growth='linear'` | Default | Most business metrics |
| `growth='logistic'` | For capped data | User growth, market saturation |
| `seasonality_mode='additive'` | Default | Seasonal variation is constant |
| `seasonality_mode='multiplicative'` | High variance | Seasonal variation grows with trend |
| `changepoint_prior_scale=0.05` | Default | Lower = smoother trend, higher = more flexible |

---

## Step 4: Add Custom Seasonalities

```python
# Add monthly seasonality (30.5-day period)
model.add_seasonality(
    name='monthly',
    period=30.5,
    fourier_order=5  # Higher = more complex pattern (1-10)
)

# Add quarterly seasonality
model.add_seasonality(
    name='quarterly',
    period=365.25/4,
    fourier_order=3
)

# Conditional seasonality (e.g., only on weekdays)
df['is_weekday'] = (df['ds'].dt.dayofweek < 5).astype(int)

model.add_seasonality(
    name='weekday_seasonality',
    period=7,
    fourier_order=3,
    condition_name='is_weekday'
)
```

---

## Step 5: Add Holidays and Special Events

```python
# Option 1: Built-in country holidays
model.add_country_holidays(country_name='US')

# Option 2: Custom holidays
holidays = pd.DataFrame({
    'holiday': ['Black Friday', 'Black Friday', 'Cyber Monday', 'Cyber Monday'],
    'ds': pd.to_datetime(['2020-11-27', '2021-11-26', '2020-11-30', '2021-11-29']),
    'lower_window': 0,   # Days before holiday
    'upper_window': 1    # Days after holiday
})

model = Prophet(holidays=holidays)

# Add holiday effects with window
# lower_window=-2, upper_window=2 means 2 days before to 2 days after
```

---

## Step 6: Add Regressors (Exogenous Variables)

```python
# Add external features (e.g., promotions, weather)
df['promotion'] = 0  # Example: binary promotion indicator
df.loc[df['ds'].dt.month == 12, 'promotion'] = 1

model.add_regressor('promotion')

# Multiple regressors
df['temperature'] = 25  # Example: temperature data
model.add_regressor('temperature')

# Note: Regressors must be present in both training and forecast data
```

---

## Step 7: Fit Model

```python
# Fit the model
model.fit(df)

# Suppress verbose output
model.fit(df, verbose=False)
```

---

## Step 8: Create Future DataFrame and Forecast

```python
# Create future dataframe for forecasting
future = model.make_future_dataframe(periods=30, freq='D')  # 30 days ahead

# If you added regressors, you must provide their future values
# future['promotion'] = 0  # Example: no promotions in future
# future['temperature'] = 25  # Example: constant temperature

# Generate forecast
forecast = model.predict(future)

# View forecast columns
print(forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']].tail(10))
```

**Forecast Columns:**
- `yhat`: Point forecast
- `yhat_lower`: Lower bound of 80% confidence interval
- `yhat_upper`: Upper bound of 80% confidence interval
- `trend`: Trend component
- `weekly`: Weekly seasonality component
- `yearly`: Yearly seasonality component

---

## Step 9: Visualize Forecast

```python
# Plot forecast
fig1 = model.plot(forecast)
plt.title('Prophet Forecast')
plt.show()

# Plot components (trend, seasonality)
fig2 = model.plot_components(forecast)
plt.show()
```

---

## Step 10: Cross-Validation

```python
from prophet.diagnostics import cross_validation, performance_metrics

# Perform cross-validation
# initial: training size
# period: spacing between cutoff dates
# horizon: forecast horizon
df_cv = cross_validation(
    model, 
    initial='365 days',  # Train on first 365 days
    period='90 days',    # Every 90 days, add more data
    horizon='90 days'    # Forecast 90 days ahead
)

# Calculate performance metrics
df_metrics = performance_metrics(df_cv)
print(df_metrics.head())

# Average metrics
print(f"\nAverage MAE: {df_metrics['mae'].mean():.2f}")
print(f"Average MAPE: {df_metrics['mape'].mean():.2f}")
print(f"Average RMSE: {df_metrics['rmse'].mean():.2f}")
```

---

## Step 11: Hyperparameter Tuning

```python
import itertools
import numpy as np

# Define parameter grid
param_grid = {
    'changepoint_prior_scale': [0.001, 0.01, 0.1, 0.5],
    'seasonality_prior_scale': [0.01, 0.1, 1.0, 10.0],
    'seasonality_mode': ['additive', 'multiplicative']
}

# Generate all combinations
all_params = [dict(zip(param_grid.keys(), v)) 
              for v in itertools.product(*param_grid.values())]

# Evaluate each combination
results = []

for params in all_params:
    model = Prophet(**params)
    model.fit(df, verbose=False)
    
    # Cross-validation
    df_cv = cross_validation(model, initial='365 days', period='90 days', 
                              horizon='90 days', disable_tqdm=True)
    df_metrics = performance_metrics(df_cv)
    
    results.append({
        'params': params,
        'mae': df_metrics['mae'].mean(),
        'rmse': df_metrics['rmse'].mean()
    })

# Find best parameters
best_result = min(results, key=lambda x: x['rmse'])
print(f"Best params: {best_result['params']}")
print(f"Best RMSE: {best_result['rmse']:.2f}")
```

---

## Complete Production Pipeline

```python
def prophet_forecast_pipeline(df, periods=30, holidays=None, regressors=None):
    """
    Complete Prophet forecasting pipeline.
    
    Parameters
    ----------
    df : pd.DataFrame
        DataFrame with 'ds' (datetime) and 'y' (target) columns
    periods : int
        Number of days to forecast
    holidays : pd.DataFrame, optional
        Custom holidays DataFrame
    regressors : list, optional
        List of regressor column names in df
    
    Returns
    -------
    forecast : pd.DataFrame
        Forecast with components
    model : Prophet
        Fitted model object
    """
    # Create model
    model = Prophet(
        seasonality_mode='multiplicative',
        holidays=holidays
    )
    
    # Add regressors if specified
    if regressors:
        for regressor in regressors:
            model.add_regressor(regressor)
    
    # Fit model
    model.fit(df, verbose=False)
    
    # Create future dataframe
    future = model.make_future_dataframe(periods=periods)
    
    # Add regressor values for future (example: set to 0)
    if regressors:
        for regressor in regressors:
            if regressor in df.columns:
                future[regressor] = 0  # Set future values as needed
    
    # Forecast
    forecast = model.predict(future)
    
    return forecast, model

# Usage
forecast, model = prophet_forecast_pipeline(df, periods=30)

# Plot
model.plot(forecast)
plt.show()
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Correct Approach |
|--------------|----------------|------------------|
| Not renaming to `ds`/`y` | Prophet requires these names | Always rename before fitting |
| Adding regressors without future values | Prophet can't forecast | Provide future regressor values |
| Using daily seasonality on monthly data | Overfits noise | Disable `daily_seasonality` |
| Not tuning `changepoint_prior_scale` | Model is too rigid or too flexible | Cross-validate to find optimal value |

---

## Related

- [forecasting-models.md](../concepts/forecasting-models.md) — Model comparison
- [evaluation-ts.md](evaluation-ts.md) — Forecast evaluation metrics
- [arima-workflow.md](arima-workflow.md) — Alternative statistical approach
