# Dashboard Layout Pattern

## Purpose

Multi-panel figure layouts for reports and dashboards: matplotlib GridSpec layouts, Plotly subplots, and responsive Plotly Dash applications.

---

## Matplotlib — GridSpec Layouts

```python
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import numpy as np

# ── Pattern 1: Standard 2×2 grid ────────────────────────────────────
fig, axes = plt.subplots(2, 2, figsize=(14, 10),
                          constrained_layout=True)
titles = ["Distribution", "Box Plot", "Correlation", "Feature Importance"]
for ax, title in zip(axes.flat, titles):
    ax.set_title(title, fontweight="bold")

# ── Pattern 2: Wide header + small panels ───────────────────────────
fig = plt.figure(figsize=(16, 9))
gs = gridspec.GridSpec(3, 4, figure=fig,
                        height_ratios=[2, 1, 1],
                        hspace=0.45, wspace=0.35)

ax_header  = fig.add_subplot(gs[0, :])    # full-width top
ax_mid_l   = fig.add_subplot(gs[1, :2])   # left half middle
ax_mid_r   = fig.add_subplot(gs[1, 2:])   # right half middle
ax_bot_1   = fig.add_subplot(gs[2, 0])
ax_bot_2   = fig.add_subplot(gs[2, 1])
ax_bot_3   = fig.add_subplot(gs[2, 2])
ax_bot_4   = fig.add_subplot(gs[2, 3])

# ── Pattern 3: Shared x-axis (time series + residuals) ──────────────
fig, (ax_top, ax_bot) = plt.subplots(
    2, 1, figsize=(14, 7), sharex=True,
    gridspec_kw={"height_ratios": [3, 1]},
    constrained_layout=True
)
ax_top.set_title("Signal", fontweight="bold")
ax_bot.set_title("Residuals", fontweight="bold")
ax_bot.axhline(0, color="red", ls="--", lw=1)
```

---

## Plotly — Subplot Dashboard

```python
import plotly.graph_objects as go
from plotly.subplots import make_subplots

def create_model_dashboard(
    fpr, tpr, auc,
    prec, rec, ap,
    y_true, y_pred, y_prob,
    feature_names, importances
) -> go.Figure:

    fig = make_subplots(
        rows=2, cols=2,
        subplot_titles=("ROC Curve", "PR Curve",
                        "Predicted vs Actual", "Feature Importance"),
        vertical_spacing=0.13,
        horizontal_spacing=0.10
    )

    # ROC
    fig.add_trace(go.Scatter(x=fpr, y=tpr, mode="lines",
                              name=f"ROC (AUC={auc:.3f})",
                              line=dict(color="steelblue", width=2)),
                  row=1, col=1)
    fig.add_trace(go.Scatter(x=[0,1], y=[0,1], mode="lines", name="Random",
                              line=dict(color="gray", dash="dash", width=1),
                              showlegend=False), row=1, col=1)

    # PR
    fig.add_trace(go.Scatter(x=rec, y=prec, mode="lines",
                              name=f"PR (AP={ap:.3f})",
                              line=dict(color="tomato", width=2)),
                  row=1, col=2)

    # Actual vs Predicted
    fig.add_trace(go.Scatter(x=y_pred, y=y_true, mode="markers",
                              name="Observations",
                              marker=dict(color="steelblue", size=4, opacity=0.5)),
                  row=2, col=1)
    mn, mx = float(min(y_pred.min(), y_true.min())), float(max(y_pred.max(), y_true.max()))
    fig.add_trace(go.Scatter(x=[mn, mx], y=[mn, mx], mode="lines",
                              name="Perfect", line=dict(color="red", dash="dash"),
                              showlegend=False), row=2, col=1)

    # Feature Importance
    top_idx = np.argsort(importances)[-15:]
    fig.add_trace(go.Bar(x=importances[top_idx], y=[feature_names[i] for i in top_idx],
                          orientation="h", name="Importance",
                          marker_color="steelblue"),
                  row=2, col=2)

    fig.update_layout(
        height=700, width=1100,
        title_text="Model Evaluation Dashboard",
        title_font_size=16,
        template="plotly_white",
        showlegend=True,
    )
    return fig
```

---

## Plotly Dash — Minimal App Template

```python
from dash import Dash, dcc, html, Input, Output
import plotly.express as px

def build_eda_app(df, numeric_cols: list[str], target: str) -> Dash:
    app = Dash(__name__)

    app.layout = html.Div([
        html.H2("EDA Dashboard", style={"fontFamily": "sans-serif"}),
        html.Div([
            dcc.Dropdown(id="x-axis", options=numeric_cols,
                         value=numeric_cols[0], clearable=False),
            dcc.Dropdown(id="y-axis", options=numeric_cols,
                         value=numeric_cols[1] if len(numeric_cols) > 1 else numeric_cols[0],
                         clearable=False),
        ], style={"display": "flex", "gap": "20px", "padding": "10px"}),
        dcc.Graph(id="scatter-plot"),
        dcc.Graph(id="dist-plot"),
    ], style={"maxWidth": "1200px", "margin": "auto"})

    @app.callback(Output("scatter-plot", "figure"),
                  Input("x-axis", "value"), Input("y-axis", "value"))
    def update_scatter(x, y):
        return px.scatter(df, x=x, y=y, color=target,
                          trendline="ols", template="plotly_white",
                          title=f"{x} vs {y}")

    @app.callback(Output("dist-plot", "figure"), Input("x-axis", "value"))
    def update_dist(col):
        return px.histogram(df, x=col, color=target, marginal="box",
                             barmode="overlay", opacity=0.6,
                             template="plotly_white", title=f"Distribution: {col}")

    return app


if __name__ == "__main__":
    # app = build_eda_app(df, numeric_cols, target="label")
    # app.run(debug=True, port=8050)
    pass
```

---

## Layout Checklist

```
□ constrained_layout=True (or tight_layout) — no overlapping labels
□ Consistent figsize — match target medium (report vs screen)
□ Subplot titles added to every panel
□ Shared axes (sharex/sharey) where appropriate
□ Legend placed outside plot area for multi-panel figures
□ For Plotly: template="plotly_white", height/width set explicitly
□ Dash: dropdowns use clearable=False for required fields
□ Save: fig.write_html for interactive; savefig for static
```
