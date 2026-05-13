# ML-Based Forecasting

> **MCP Validated:** 2026-05-08

Machine learning-based time series forecasting using LightGBM, XGBoost, or Random Forest with engineered lag and rolling features. Critical: proper train/test split to avoid data leakage.

---

## Why ML for Time Series?

**Advantages:**
- Handles non-linear relationships
- Scalable to millions of rows
- Incorporates exogenous features naturally (weather, promotions, etc.)
- Feature importance for interpretability
- State-of-the-art accuracy on large datasets

**Disadvantages:**
- Requires careful feature engineering
- No native prediction intervals (need conformal prediction)
- Risk of data leakage if not careful
- More complex than ARIMA/Prophet

---

## Step 1: Feature Engineering (No Leakage!)

**CRITICAL:** Always use `.shift()` to avoid data leakage.

```python
import pandas as pd
import numpy as np

def create_ts_features(df, target_col='value', lags=[1, 2, 7, 14, 30], 
                       rolling_windows=[7, 14, 30]):
    """Create time series features for ML models."""
    df = df.copy()
    
    # 1. Lag features (MUST shift!)
    for lag in lags:
        df[f'lag_{lag}'] = df[target_col].shift(lag)
    
    # 2. Rolling statistics (MUST shift before rolling!)
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
    df['is_month_start'] = df.index.is_month_start.astype(int)
    df['is_month_end'] = df.index.is_month_end.astype(int)
    
    # 4. Cyclical encoding
    df['month_sin'] = np.sin(2 * np.pi * df.index.month / 12)
    df['month_cos'] = np.cos(2 * np.pi * df.index.month / 12)
    df['dayofweek_sin'] = np.sin(2 * np.pi * df.index.dayofweek / 7)
    df['dayofweek_cos'] = np.cos(2 * np.pi * df.index.dayofweek / 7)
    
    return df

# Usage
df = pd.read_csv('data.csv', parse_dates=['date'], index_col='date')
df_features = create_ts_features(df, target_col='sales')

# Drop rows with NaN (from lag/rolling features)
df_features = df_features.dropna()
```

---

## Step 2: Train/Test Split (TimeSeriesSplit)

**CRITICAL:** Never shuffle! Always use time-based split.

```python
from sklearn.model_selection import TimeSeriesSplit

# Prepare features and target
feature_cols = [col for col in df_features.columns if col != 'sales']
X = df_features[feature_cols]
y = df_features['sales']

# Time series cross-validation split
tscv = TimeSeriesSplit(n_splits=5, test_size=30)  # 30-day test set

for fold, (train_idx, val_idx) in enumerate(tscv.split(X)):
    print(f"Fold {fold+1}:")
    print(f"  Train: {df_features.index[train_idx[0]]} to {df_features.index[train_idx[-1]]}")
    print(f"  Val:   {df_features.index[val_idx[0]]} to {df_features.index[val_idx[-1]]}")
```

**Alternative: Simple chronological split**

```python
# Split by date
train_size = int(len(df_features) * 0.8)
X_train, X_test = X[:train_size], X[train_size:]
y_train, y_test = y[:train_size], y[train_size:]

print(f"Train: {df_features.index[0]} to {df_features.index[train_size-1]}")
print(f"Test:  {df_features.index[train_size]} to {df_features.index[-1]}")
```

---

## Step 3: Train LightGBM Model

```python
import lightgbm as lgb
from sklearn.metrics import mean_absolute_error, mean_squared_error

# Define model
model = lgb.LGBMRegressor(
    objective='regression',
    metric='mae',
    n_estimators=1000,
    learning_rate=0.01,
    max_depth=8,
    num_leaves=31,
    subsample=0.8,
    colsample_bytree=0.8,
    random_state=42,
    verbose=-1
)

# Train with early stopping
model.fit(
    X_train, y_train,
    eval_set=[(X_test, y_test)],
    eval_metric='mae',
    callbacks=[lgb.early_stopping(stopping_rounds=50), lgb.log_evaluation(100)]
)

# Predict
y_pred = model.predict(X_test)

# Evaluate
mae = mean_absolute_error(y_test, y_pred)
rmse = mean_squared_error(y_test, y_pred, squared=False)
print(f"MAE: {mae:.2f}")
print(f"RMSE: {rmse:.2f}")
```

---

## Step 4: Feature Importance

```python
import matplotlib.pyplot as plt

# Get feature importance
importance = pd.DataFrame({
    'feature': feature_cols,
    'importance': model.feature_importances_
}).sort_values('importance', ascending=False)

# Plot top 20 features
plt.figure(figsize=(10, 8))
plt.barh(importance['feature'][:20], importance['importance'][:20])
plt.xlabel('Importance')
plt.title('Top 20 Feature Importances')
plt.gca().invert_yaxis()
plt.tight_layout()
plt.show()

print(importance.head(20))
```

---

## Step 5: Recursive Multi-Step Forecasting

For forecasting multiple steps ahead, use **recursive forecasting** (predict one step, use prediction as input for next step).

```python
def recursive_forecast(model, last_known_data, n_steps, feature_cols):
    """
    Recursively forecast n_steps ahead.
    
    Parameters
    ----------
    model : trained model
        Fitted LightGBM/XGBoost model
    last_known_data : pd.DataFrame
        Last row of training data with all features
    n_steps : int
        Number of steps to forecast
    feature_cols : list
        List of feature column names
    
    Returns
    -------
    forecasts : list
        List of forecasted values
    """
    forecasts = []
    current_features = last_known_data[feature_cols].copy()
    
    for step in range(n_steps):
        # Predict next value
        pred = model.predict(current_features.values.reshape(1, -1))[0]
        forecasts.append(pred)
        
        # Update lag features for next prediction
        # This is simplified - in production, update all lag/rolling features
        if 'lag_1' in feature_cols:
            current_features['lag_1'] = pred
        if 'lag_7' in feature_cols and len(forecasts) >= 7:
            current_features['lag_7'] = forecasts[-7]
        
        # Update date features (increment by 1 day)
        # (Implementation depends on your date features)
    
    return forecasts

# Usage
last_row = df_features.iloc[-1:].copy()
forecasts = recursive_forecast(model, last_row, n_steps=30, feature_cols=feature_cols)
```

**Note:** Recursive forecasting accumulates errors. For long horizons, consider direct forecasting (train separate model for each horizon).

---

## Step 6: Direct Multi-Step Forecasting (Alternative)

Train separate models for each forecast horizon.

```python
def train_direct_models(X_train, y_train, horizons=[1, 7, 14, 30]):
    """
    Train separate models for each forecast horizon.
    
    Parameters
    ----------
    X_train : pd.DataFrame
        Training features
    y_train : pd.Series
        Training target
    horizons : list
        List of forecast horizons (in days)
    
    Returns
    -------
    models : dict
        Dictionary of trained models {horizon: model}
    """
    models = {}
    
    for h in horizons:
        # Create target shifted by h steps
        y_train_h = y_train.shift(-h).dropna()
        X_train_h = X_train.loc[y_train_h.index]
        
        # Train model
        model_h = lgb.LGBMRegressor(n_estimators=1000, learning_rate=0.01, 
                                     max_depth=8, random_state=42, verbose=-1)
        model_h.fit(X_train_h, y_train_h)
        
        models[h] = model_h
        print(f"Trained model for horizon {h}")
    
    return models

# Usage
models = train_direct_models(X_train, y_train, horizons=[1, 7, 14, 30])

# Predict for each horizon
for horizon, model_h in models.items():
    pred_h = model_h.predict(X_test)
    print(f"Horizon {horizon}: Predictions made")
```

---

## Step 7: Hyperparameter Tuning with Optuna

```python
import optuna

def objective(trial):
    """Optuna objective function for LightGBM hyperparameter tuning."""
    params = {
        'objective': 'regression',
        'metric': 'mae',
        'learning_rate': trial.suggest_float('learning_rate', 0.001, 0.1, log=True),
        'max_depth': trial.suggest_int('max_depth', 3, 12),
        'num_leaves': trial.suggest_int('num_leaves', 20, 100),
        'subsample': trial.suggest_float('subsample', 0.5, 1.0),
        'colsample_bytree': trial.suggest_float('colsample_bytree', 0.5, 1.0),
        'n_estimators': 1000,
        'random_state': 42,
        'verbose': -1
    }
    
    model = lgb.LGBMRegressor(**params)
    model.fit(
        X_train, y_train,
        eval_set=[(X_test, y_test)],
        callbacks=[lgb.early_stopping(stopping_rounds=50), lgb.log_evaluation(0)]
    )
    
    y_pred = model.predict(X_test)
    mae = mean_absolute_error(y_test, y_pred)
    
    return mae

# Run optimization
study = optuna.create_study(direction='minimize')
study.optimize(objective, n_trials=50, show_progress_bar=True)

print(f"Best MAE: {study.best_value:.2f}")
print(f"Best params: {study.best_params}")

# Train final model with best params
best_model = lgb.LGBMRegressor(**study.best_params, n_estimators=1000, verbose=-1)
best_model.fit(X_train, y_train)
```

---

## Complete Production Pipeline

```python
def ml_forecast_pipeline(df, target_col='value', n_forecast_days=30):
    """
    Complete ML-based forecasting pipeline.
    
    Parameters
    ----------
    df : pd.DataFrame
        DataFrame with datetime index and target column
    target_col : str
        Name of target column
    n_forecast_days : int
        Number of days to forecast
    
    Returns
    -------
    y_pred : np.ndarray
        Test set predictions
    forecast : list
        Future forecasts
    model : trained model
        Fitted LightGBM model
    """
    # 1. Feature engineering
    df_features = create_ts_features(df, target_col=target_col)
    df_features = df_features.dropna()
    
    # 2. Train/test split (80/20)
    train_size = int(len(df_features) * 0.8)
    feature_cols = [col for col in df_features.columns if col != target_col]
    
    X_train = df_features[feature_cols][:train_size]
    X_test = df_features[feature_cols][train_size:]
    y_train = df_features[target_col][:train_size]
    y_test = df_features[target_col][train_size:]
    
    # 3. Train model
    model = lgb.LGBMRegressor(
        objective='regression',
        n_estimators=1000,
        learning_rate=0.01,
        max_depth=8,
        num_leaves=31,
        subsample=0.8,
        colsample_bytree=0.8,
        random_state=42,
        verbose=-1
    )
    
    model.fit(
        X_train, y_train,
        eval_set=[(X_test, y_test)],
        callbacks=[lgb.early_stopping(50), lgb.log_evaluation(0)]
    )
    
    # 4. Predict on test set
    y_pred = model.predict(X_test)
    
    # 5. Recursive forecast
    last_row = df_features.iloc[-1:]
    forecast = recursive_forecast(model, last_row, n_forecast_days, feature_cols)
    
    # 6. Metrics
    mae = mean_absolute_error(y_test, y_pred)
    rmse = mean_squared_error(y_test, y_pred, squared=False)
    print(f"Test MAE: {mae:.2f}, RMSE: {rmse:.2f}")
    
    return y_pred, forecast, model

# Usage
y_pred, forecast, model = ml_forecast_pipeline(df, target_col='sales', n_forecast_days=30)
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Correct Approach |
|--------------|----------------|------------------|
| **Not shifting lag features** | Uses future data (leakage) | Always `.shift()` lag features |
| **Rolling without shift** | Includes current value (leakage) | `.shift(1).rolling()` |
| **Using train_test_split with shuffle** | Breaks temporal order (leakage) | Use TimeSeriesSplit |
| **Not removing NaN rows** | Model can't train on NaN | `.dropna()` after feature creation |
| **Ignoring feature importance** | Misses insights | Always inspect feature importance |

---

## Related

- [feature-engineering-ts.md](../concepts/feature-engineering-ts.md) — Detailed feature creation guide
- [evaluation-ts.md](evaluation-ts.md) — Evaluation metrics and walk-forward validation
- [forecasting-models.md](../concepts/forecasting-models.md) — Model comparison
