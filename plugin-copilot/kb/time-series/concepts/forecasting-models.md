# Forecasting Models

> **MCP Validated:** 2026-05-08

Overview of time series forecasting models — ARIMA family, Prophet, and ML-based approaches. Comparison of when to use each model type.

---

## Model Categories

### 1. Statistical Models (ARIMA Family)

**Models:** AR, MA, ARMA, ARIMA, SARIMA, SARIMAX

**Strengths:**
- Interpretable (clear AR/MA components)
- Works well with small datasets (<1000 observations)
- Produces prediction intervals natively
- Fast to train and forecast

**Weaknesses:**
- Requires stationarity (differencing needed)
- Limited ability to incorporate exogenous variables
- Manual parameter tuning (p, d, q)
- Assumes linear relationships

**When to Use:**
- Short to medium time series (100-10,000 observations)
- Single seasonality (daily, weekly, monthly, yearly)
- Need interpretability and uncertainty quantification

---

## ARIMA Family Components

| Model | Components | Formula | Use Case |
|-------|------------|---------|----------|
| **AR(p)** | Autoregressive | `Y_t = c + Σ φ_i Y_{t-i} + ε_t` | Series depends on past values |
| **MA(q)** | Moving average | `Y_t = c + Σ θ_i ε_{t-i} + ε_t` | Series depends on past errors |
| **ARMA(p,q)** | AR + MA | Combination of AR and MA | Stationary series |
| **ARIMA(p,d,q)** | ARMA + differencing | ARMA on d-differenced series | Non-stationary series |
| **SARIMA(p,d,q)(P,D,Q,s)** | ARIMA + seasonal | ARIMA with seasonal component | Seasonal data |

**Parameters:**
- **p:** Autoregressive order (number of past values)
- **d:** Differencing order (number of times to difference)
- **q:** Moving average order (number of past errors)
- **P, D, Q:** Seasonal equivalents of p, d, q
- **s:** Season length (12 for monthly, 7 for daily with weekly seasonality)

---

### 2. Prophet (Facebook Prophet)

**Strengths:**
- Handles multiple seasonalities (daily + weekly + yearly) automatically
- Robust to missing data and outliers
- Easy to add holidays and special events
- Interpretable components (trend + seasonality + holidays)
- Good for business time series with irregular patterns

**Weaknesses:**
- Less accurate than ML models for large datasets with features
- Black-box optimization (less transparent than ARIMA)
- Slower than ARIMA for simple forecasts

**When to Use:**
- Business time series with holidays and events
- Multiple seasonalities (e.g., hourly data with daily and weekly patterns)
- Missing data or irregular sampling
- Need to explain forecasts to non-technical stakeholders

```python
from prophet import Prophet

# Prepare data (requires 'ds' and 'y' columns)
df = pd.DataFrame({'ds': dates, 'y': values})

# Create and fit model
model = Prophet(
    seasonality_mode='multiplicative',  # or 'additive'
    yearly_seasonality=True,
    weekly_seasonality=True,
    daily_seasonality=False
)
model.fit(df)

# Forecast
future = model.make_future_dataframe(periods=30)  # 30 days ahead
forecast = model.predict(future)
```

---

### 3. ML-Based Models (LightGBM, XGBoost, Random Forest)

**Approach:** Treat time series as supervised learning with engineered features.

**Strengths:**
- Scalable to large datasets (millions of rows)
- Handles exogenous features (weather, promotions, etc.)
- Non-linear relationships
- Feature importance for interpretability

**Weaknesses:**
- Requires careful feature engineering (lag, rolling, date features)
- No native prediction intervals (need conformal prediction or quantile regression)
- Risk of data leakage if features not carefully designed
- More complex to implement than statistical models

**When to Use:**
- Large datasets (>10,000 observations)
- Exogenous features available (e.g., weather, promotions)
- Non-linear relationships expected
- High-frequency data (minute, second level)

---

## Model Comparison Table

| Criterion | ARIMA/SARIMA | Prophet | ML (LightGBM) |
|-----------|--------------|---------|---------------|
| **Data Size** | 100-10,000 | 500-100,000 | >10,000 |
| **Seasonality** | Single (with SARIMA) | Multiple | Multiple (via features) |
| **Exogenous Features** | Limited (SARIMAX) | Yes (regressors) | Yes (native) |
| **Interpretability** | High | Medium | Medium (feature importance) |
| **Training Speed** | Fast | Medium | Medium |
| **Prediction Intervals** | Native | Native | Requires extra step |
| **Missing Data Handling** | Poor | Good | Poor (needs imputation) |
| **Parameter Tuning** | Manual (p, d, q) | Auto | Hyperparameter tuning |

---

## Decision Tree

```
Start
  |
  ├─ Data size < 1000 observations? → YES → SARIMA
  |
  ├─ Multiple seasonalities (daily + weekly + yearly)? → YES → Prophet
  |
  ├─ Many exogenous features (>10)? → YES → LightGBM
  |
  ├─ Need interpretable AR/MA components? → YES → ARIMA
  |
  ├─ Business context (holidays, events)? → YES → Prophet
  |
  └─ High accuracy priority + large data? → YES → LightGBM with lag features
```

---

## Ensemble Approaches

Combine multiple models for better performance:

```python
# Simple average ensemble
forecast_arima = arima_model.predict(...)
forecast_prophet = prophet_model.predict(...)['yhat']
forecast_ml = ml_model.predict(...)

forecast_ensemble = (forecast_arima + forecast_prophet + forecast_ml) / 3
```

**Advanced:** Use weighted average based on validation performance or train a meta-model.

---

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Correct Approach |
|--------------|----------------|------------------|
| Using ML without lag features | Model has no temporal information | Create lag and rolling features |
| Using ARIMA on non-stationary data | Model won't converge | Apply differencing first |
| Prophet on high-frequency data without aggregation | Too slow, overfits noise | Aggregate to hourly/daily |
| Ignoring exogenous features | Misses valuable information | Include features in SARIMAX or ML |

---

## Related

- [arima-workflow.md](../patterns/arima-workflow.md) — SARIMA implementation
- [prophet-workflow.md](../patterns/prophet-workflow.md) — Prophet implementation
- [ml-forecasting.md](../patterns/ml-forecasting.md) — LightGBM forecasting
- [evaluation-ts.md](../patterns/evaluation-ts.md) — Model comparison framework
