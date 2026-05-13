# Time Series Evaluation

> **MCP Validated:** 2026-05-08

Comprehensive evaluation framework for time series forecasting models — metrics, baselines, walk-forward validation, and residual analysis.

---

## Evaluation Metrics

### 1. Mean Absolute Error (MAE)

**Most interpretable metric** — average absolute difference.

```python
from sklearn.metrics import mean_absolute_error

mae = mean_absolute_error(y_true, y_pred)
print(f"MAE: {mae:.2f}")
```

**Pros:** Easy to interpret, robust to outliers
**Cons:** Scale-dependent (can't compare across different datasets)

---

### 2. Mean Absolute Percentage Error (MAPE)

**Scale-independent** percentage error.

```python
def mape(y_true, y_pred):
    """Calculate MAPE, avoiding division by zero."""
    y_true, y_pred = np.array(y_true), np.array(y_pred)
    non_zero = y_true != 0
    return np.mean(np.abs((y_true[non_zero] - y_pred[non_zero]) / y_true[non_zero])) * 100

mape_score = mape(y_true, y_pred)
print(f"MAPE: {mape_score:.2f}%")
```

**Pros:** Scale-independent, easy to communicate
**Cons:** Undefined when y_true = 0, penalizes under-predictions more than over-predictions

---

### 3. Root Mean Squared Error (RMSE)

**Penalizes large errors** more than MAE.

```python
from sklearn.metrics import mean_squared_error

rmse = mean_squared_error(y_true, y_pred, squared=False)
print(f"RMSE: {rmse:.2f}")
```

**Pros:** Penalizes large errors, standard metric
**Cons:** Scale-dependent, sensitive to outliers

---

### 4. Mean Absolute Scaled Error (MASE)

**Best for model comparison** — compares to naive baseline.

```python
def mase(y_true, y_pred, y_train):
    """
    Calculate MASE (Mean Absolute Scaled Error).
    
    Parameters
    ----------
    y_true : array-like
        Actual test values
    y_pred : array-like
        Predicted values
    y_train : array-like
        Training data (for baseline calculation)
    
    Returns
    -------
    mase_score : float
        MASE score (< 1.0 is better than naive forecast)
    """
    mae_model = np.mean(np.abs(y_true - y_pred))
    
    # Naive forecast MAE (use training data)
    naive_forecast = y_train[:-1]
    naive_actual = y_train[1:]
    mae_naive = np.mean(np.abs(naive_actual - naive_forecast))
    
    return mae_model / mae_naive

mase_score = mase(y_test, y_pred, y_train)
print(f"MASE: {mase_score:.4f} ({'better' if mase_score < 1 else 'worse'} than naive)")
```

**Interpretation:**
- MASE < 1.0 → Model is better than naive forecast
- MASE = 1.0 → Model is same as naive forecast
- MASE > 1.0 → Model is worse than naive forecast

**Pros:** Scale-independent, compares to baseline
**Cons:** Requires training data

---

### 5. Prediction Interval Coverage (for probabilistic forecasts)

```python
def coverage(y_true, lower, upper):
    """Calculate percentage of actuals within prediction interval."""
    within_interval = (y_true >= lower) & (y_true <= upper)
    return np.mean(within_interval) * 100

# Example: 95% confidence interval
coverage_95 = coverage(y_true, y_pred_lower_95, y_pred_upper_95)
print(f"95% CI Coverage: {coverage_95:.1f}% (target: 95%)")
```

**Target:** For 95% CI, coverage should be ~95%

---

## Baseline Models

**Always compare to baselines** to validate model performance.

### 1. Naive Forecast (Last Value)

```python
def naive_forecast(y_train, n_steps):
    """Naive forecast: repeat last value."""
    return np.repeat(y_train.iloc[-1], n_steps)

y_naive = naive_forecast(y_train, len(y_test))
mae_naive = mean_absolute_error(y_test, y_naive)
print(f"Naive MAE: {mae_naive:.2f}")
```

---

### 2. Seasonal Naive Forecast

```python
def seasonal_naive_forecast(y_train, n_steps, season_length=7):
    """Seasonal naive: repeat values from last season."""
    return np.tile(y_train.iloc[-season_length:], (n_steps // season_length) + 1)[:n_steps]

y_seasonal_naive = seasonal_naive_forecast(y_train, len(y_test), season_length=7)
mae_seasonal = mean_absolute_error(y_test, y_seasonal_naive)
print(f"Seasonal Naive MAE: {mae_seasonal:.2f}")
```

---

### 3. Moving Average Baseline

```python
def moving_average_forecast(y_train, n_steps, window=7):
    """Moving average forecast."""
    ma = y_train.rolling(window=window).mean().iloc[-1]
    return np.repeat(ma, n_steps)

y_ma = moving_average_forecast(y_train, len(y_test), window=7)
mae_ma = mean_absolute_error(y_test, y_ma)
print(f"Moving Average MAE: {mae_ma:.2f}")
```

---

## Train/Val/Test Split

Use 3-way split for model selection and final evaluation.

```python
# 60% train, 20% validation, 20% test
n = len(df)
train_end = int(n * 0.6)
val_end = int(n * 0.8)

train = df[:train_end]
val = df[train_end:val_end]
test = df[val_end:]

print(f"Train: {train.index[0]} to {train.index[-1]} ({len(train)} rows)")
print(f"Val:   {val.index[0]} to {val.index[-1]} ({len(val)} rows)")
print(f"Test:  {test.index[0]} to {test.index[-1]} ({len(test)} rows)")
```

**Workflow:**
1. Train models on `train`
2. Select best model using `val` metrics
3. Report final performance on `test`

---

## Walk-Forward Validation (Expanding Window)

**Most robust evaluation** for time series.

```python
from sklearn.model_selection import TimeSeriesSplit

def walk_forward_validation(X, y, model, n_splits=5):
    """
    Perform walk-forward validation.
    
    Parameters
    ----------
    X : pd.DataFrame
        Features
    y : pd.Series
        Target
    model : estimator
        Model with fit() and predict() methods
    n_splits : int
        Number of splits
    
    Returns
    -------
    results : dict
        Dictionary with MAE and RMSE for each fold
    """
    tscv = TimeSeriesSplit(n_splits=n_splits)
    
    mae_scores = []
    rmse_scores = []
    
    for fold, (train_idx, val_idx) in enumerate(tscv.split(X)):
        X_train, X_val = X.iloc[train_idx], X.iloc[val_idx]
        y_train, y_val = y.iloc[train_idx], y.iloc[val_idx]
        
        # Train
        model.fit(X_train, y_train)
        
        # Predict
        y_pred = model.predict(X_val)
        
        # Evaluate
        mae = mean_absolute_error(y_val, y_pred)
        rmse = mean_squared_error(y_val, y_pred, squared=False)
        
        mae_scores.append(mae)
        rmse_scores.append(rmse)
        
        print(f"Fold {fold+1}: MAE={mae:.2f}, RMSE={rmse:.2f}")
    
    print(f"\nAverage: MAE={np.mean(mae_scores):.2f}, RMSE={np.mean(rmse_scores):.2f}")
    
    return {'mae_scores': mae_scores, 'rmse_scores': rmse_scores}

# Usage
from lightgbm import LGBMRegressor
model = LGBMRegressor(n_estimators=100, random_state=42, verbose=-1)
results = walk_forward_validation(X, y, model, n_splits=5)
```

---

## Residual Analysis

**Check if model captured all patterns.**

```python
import matplotlib.pyplot as plt
from statsmodels.stats.diagnostic import acorr_ljungbox
from statsmodels.graphics.tsaplots import plot_acf

def analyze_residuals(y_true, y_pred):
    """Analyze forecast residuals."""
    residuals = y_true - y_pred
    
    # 1. Plot residuals over time
    fig, axes = plt.subplots(2, 2, figsize=(14, 8))
    
    axes[0, 0].plot(residuals)
    axes[0, 0].axhline(0, linestyle='--', color='red')
    axes[0, 0].set_title('Residuals Over Time')
    axes[0, 0].set_ylabel('Residual')
    
    # 2. Residuals distribution
    axes[0, 1].hist(residuals, bins=30, edgecolor='black')
    axes[0, 1].set_title('Residuals Distribution')
    axes[0, 1].set_xlabel('Residual')
    
    # 3. ACF of residuals
    plot_acf(residuals, lags=40, ax=axes[1, 0])
    axes[1, 0].set_title('ACF of Residuals')
    
    # 4. Residuals vs predicted
    axes[1, 1].scatter(y_pred, residuals, alpha=0.5)
    axes[1, 1].axhline(0, linestyle='--', color='red')
    axes[1, 1].set_title('Residuals vs Predicted')
    axes[1, 1].set_xlabel('Predicted')
    axes[1, 1].set_ylabel('Residual')
    
    plt.tight_layout()
    plt.show()
    
    # 5. Ljung-Box test
    lb_test = acorr_ljungbox(residuals, lags=[10, 20, 30], return_df=True)
    print("\nLjung-Box Test (p > 0.05 indicates no autocorrelation):")
    print(lb_test)
    
    # 6. Summary statistics
    print(f"\nResiduals Summary:")
    print(f"  Mean: {residuals.mean():.4f} (should be ~0)")
    print(f"  Std: {residuals.std():.4f}")
    print(f"  Min: {residuals.min():.4f}")
    print(f"  Max: {residuals.max():.4f}")

# Usage
analyze_residuals(y_test, y_pred)
```

**Good Residuals Should:**
1. Have mean close to zero
2. Be normally distributed
3. Have no autocorrelation (ACF within bounds, Ljung-Box p > 0.05)
4. Have constant variance (no pattern in residuals vs predicted)

---

## Model Comparison Report

```python
def compare_models(models_dict, X_test, y_test):
    """
    Compare multiple models on test set.
    
    Parameters
    ----------
    models_dict : dict
        Dictionary of {model_name: trained_model}
    X_test : pd.DataFrame
        Test features
    y_test : pd.Series
        Test target
    
    Returns
    -------
    results_df : pd.DataFrame
        Comparison table
    """
    results = []
    
    for name, model in models_dict.items():
        y_pred = model.predict(X_test)
        
        mae = mean_absolute_error(y_test, y_pred)
        rmse = mean_squared_error(y_test, y_pred, squared=False)
        mape_score = mape(y_test, y_pred)
        
        results.append({
            'Model': name,
            'MAE': mae,
            'RMSE': rmse,
            'MAPE (%)': mape_score
        })
    
    results_df = pd.DataFrame(results).sort_values('MAE')
    return results_df

# Usage
models = {
    'ARIMA': arima_model,
    'Prophet': prophet_model,
    'LightGBM': lgbm_model,
    'Naive': naive_model
}

comparison = compare_models(models, X_test, y_test)
print(comparison)
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Correct Approach |
|--------------|----------------|------------------|
| **Using only RMSE** | Sensitive to outliers | Use multiple metrics (MAE, MAPE, MASE) |
| **Not comparing to baseline** | Can't judge if model is good | Always compare to naive/seasonal naive |
| **Shuffled cross-validation** | Data leakage | Use TimeSeriesSplit |
| **Not checking residuals** | Model may miss patterns | Always analyze residuals |
| **Single train/test split** | Overfits to that split | Use walk-forward validation |

---

## Related

- [arima-workflow.md](arima-workflow.md) — ARIMA forecasting
- [prophet-workflow.md](prophet-workflow.md) — Prophet forecasting
- [ml-forecasting.md](ml-forecasting.md) — ML-based forecasting
- [ts-fundamentals.md](../concepts/ts-fundamentals.md) — TimeSeriesSplit
