# Time Series Knowledge Base

> **MCP Validated:** 2026-05-08

## Purpose

Complete reference for **time series analysis and forecasting in Python** — stationarity testing, decomposition, ARIMA/SARIMA, Prophet, ML-based forecasting, and evaluation metrics for production forecasting systems.

## Domain Overview

Time series analysis involves working with data ordered by time, where observations are correlated across timestamps. Unlike cross-sectional data, time series require specialized techniques to handle temporal dependencies, seasonality, and trends without data leakage.

**Key Capabilities:**
- Stationarity testing and differencing (ADF, KPSS)
- Time series decomposition (STL, seasonal extraction)
- Classical forecasting (ARIMA, SARIMA)
- Modern forecasting (Prophet, ML-based models)
- Feature engineering with lag features and rolling windows
- Walk-forward validation and proper train/test splits
- Evaluation metrics (MAE, MAPE, RMSE, MASE)

## Key Concepts

| Concept | Description | File |
|---------|-------------|------|
| **TS Fundamentals** | Components (trend/seasonality/residuals), ACF/PACF, temporal train/test split | [ts-fundamentals.md](concepts/ts-fundamentals.md) |
| **Stationarity** | ADF/KPSS tests, differencing to achieve stationarity | [stationarity.md](concepts/stationarity.md) |
| **Forecasting Models** | ARIMA family, Prophet, ML-based approaches — when to use each | [forecasting-models.md](concepts/forecasting-models.md) |
| **Feature Engineering TS** | Lag features, rolling windows, date/time features (no future data leakage!) | [feature-engineering-ts.md](concepts/feature-engineering-ts.md) |

## Patterns

| Pattern | Use Case | File |
|---------|----------|------|
| **ARIMA Workflow** | Complete SARIMA pipeline: stationarity, ACF/PACF, fit, diagnose, forecast | [arima-workflow.md](patterns/arima-workflow.md) |
| **Prophet Workflow** | Business time series with seasonality + holidays using Facebook Prophet | [prophet-workflow.md](patterns/prophet-workflow.md) |
| **ML Forecasting** | LightGBM/XGBoost with lag features, TimeSeriesSplit, recursive forecasting | [ml-forecasting.md](patterns/ml-forecasting.md) |
| **Evaluation TS** | MAE/MAPE/RMSE/MASE, walk-forward validation, baseline comparison | [evaluation-ts.md](patterns/evaluation-ts.md) |

## Learning Path

### Beginner
1. Read [ts-fundamentals.md](concepts/ts-fundamentals.md) — understand time series components
2. Study [stationarity.md](concepts/stationarity.md) — learn ADF/KPSS tests
3. Review [quick-reference.md](quick-reference.md) — model selection and evaluation metrics

### Intermediate
4. Learn [forecasting-models.md](concepts/forecasting-models.md) — compare ARIMA vs Prophet vs ML
5. Apply [arima-workflow.md](patterns/arima-workflow.md) — classical statistical forecasting
6. Implement [prophet-workflow.md](patterns/prophet-workflow.md) — business time series

### Advanced
7. Master [feature-engineering-ts.md](concepts/feature-engineering-ts.md) — lag and rolling features
8. Implement [ml-forecasting.md](patterns/ml-forecasting.md) — ML-based forecasting at scale
9. Apply [evaluation-ts.md](patterns/evaluation-ts.md) — production-grade model evaluation

## Agent Usage

**Target Agents:**
- `ds-time-series-analyst` — primary consumer; forecasting and decomposition
- `data-scientist` — ML model integration with time series features
- `python-developer` — production pipeline implementation

**Common Tasks:**
- Test stationarity: Use `stationarity.md` with ADF/KPSS tests
- Forecast with seasonality: Use `prophet-workflow.md` for business data
- ML-based forecasting: Use `ml-forecasting.md` with LightGBM
- Evaluate models: Use `evaluation-ts.md` with walk-forward validation

## Quick Start

```python
import pandas as pd
from statsmodels.tsa.statespace.sarimax import SARIMAX
from statsmodels.tsa.stattools import adfuller

# Load data with datetime index
df = pd.read_csv('data.csv', parse_dates=['date'], index_col='date')
series = df['value']

# Check stationarity
adf_result = adfuller(series)
print(f"ADF Statistic: {adf_result[0]:.4f}, p-value: {adf_result[1]:.4f}")

# Fit SARIMA
model = SARIMAX(series, order=(1, 1, 1), seasonal_order=(1, 1, 1, 12))
fitted = model.fit(disp=False)

# Forecast 12 steps ahead
forecast = fitted.forecast(steps=12)
print(forecast)
```

## Related Domains

- **pandas** — datetime indexing and data manipulation
- **scikit-learn** — TimeSeriesSplit, ML models for forecasting
- **xgboost** — gradient boosting with lag features
- **statistical-analysis** — hypothesis testing and correlation analysis
- **data-visualization** — plotting time series and forecast intervals

## References

- statsmodels: https://www.statsmodels.org/stable/tsa.html
- Prophet: https://facebook.github.io/prophet/
- Forecasting: Principles and Practice (Hyndman & Athanasopoulos): https://otexts.com/fpp3/
- scikit-learn TimeSeriesSplit: https://scikit-learn.org/stable/modules/cross_validation.html#time-series-split
