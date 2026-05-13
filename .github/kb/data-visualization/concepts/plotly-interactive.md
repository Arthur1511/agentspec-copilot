# Plotly Interactive Visualization

## Two APIs

| API | When to Use |
|-----|------------|
| `plotly.express` (px) | Fast, one-liner charts; best for EDA |
| `plotly.graph_objects` (go) | Full control; custom traces, mixed chart types |

```python
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
```

## Plotly Express Essentials

```python
# Scatter
fig = px.scatter(df, x="a", y="b", color="class",
                 size="weight", hover_data=["id"],
                 title="Scatter Plot")

# Histogram
fig = px.histogram(df, x="value", color="group",
                   nbins=30, marginal="box",
                   barmode="overlay", opacity=0.7)

# Line
fig = px.line(df, x="date", y="value", color="series",
              line_group="series", markers=True)

# Box
fig = px.box(df, x="group", y="value", points="outliers",
             color="group")

# Heatmap (correlation matrix)
fig = px.imshow(corr, text_auto=".2f", color_continuous_scale="RdBu_r",
                zmin=-1, zmax=1, title="Correlation Matrix")

# Facet
fig = px.scatter(df, x="a", y="b", facet_col="group",
                 facet_col_wrap=3, height=400)
fig.show()
```

## Graph Objects — Custom Traces

```python
fig = go.Figure()

# Add traces
fig.add_trace(go.Scatter(
    x=x, y=y, mode="lines+markers",
    name="Signal A",
    line=dict(color="steelblue", width=2),
    marker=dict(size=6),
    hovertemplate="x=%{x:.1f}<br>y=%{y:.4f}<extra></extra>"
))

fig.add_trace(go.Bar(
    x=categories, y=values,
    name="Counts",
    marker_color="tomato",
    showlegend=True
))

# Layout
fig.update_layout(
    title=dict(text="Combined Chart", font_size=16),
    xaxis_title="X Axis",
    yaxis_title="Y Axis",
    template="plotly_white",   # white | plotly_dark | ggplot2 | seaborn
    legend=dict(x=1.02, y=1, xanchor="left"),
    hovermode="x unified",
    width=900, height=500,
)
```

## Subplots

```python
fig = make_subplots(
    rows=2, cols=2,
    subplot_titles=("ROC Curve", "PR Curve", "Calibration", "Feature Importance"),
    shared_xaxes=False,
    vertical_spacing=0.12,
    horizontal_spacing=0.10
)

fig.add_trace(go.Scatter(x=fpr, y=tpr, name="ROC"), row=1, col=1)
fig.add_trace(go.Scatter(x=rec, y=prec, name="PR"), row=1, col=2)

fig.update_layout(height=700, showlegend=True, template="plotly_white")
```

## Annotations and Shapes

```python
fig.add_hline(y=threshold, line_dash="dash", line_color="red",
              annotation_text=f"Threshold={threshold:.2f}")

fig.add_vrect(x0=start, x1=end, fillcolor="green", opacity=0.1,
              line_width=0, annotation_text="Period A")

fig.add_annotation(x=x0, y=y0, text="Peak",
                   showarrow=True, arrowhead=2,
                   font=dict(size=12, color="black"))
```

## Export

```python
fig.write_html("chart.html")                     # interactive HTML
fig.write_image("chart.png", scale=2)            # raster (requires kaleido)
fig.write_image("chart.pdf")                     # vector
fig.write_json("chart.json")                     # reloadable
```

## Dash Basics

```python
from dash import Dash, dcc, html, Input, Output

app = Dash(__name__)
app.layout = html.Div([
    dcc.Dropdown(id="group-select", options=["A", "B", "C"], value="A"),
    dcc.Graph(id="main-chart"),
])

@app.callback(Output("main-chart", "figure"), Input("group-select", "value"))
def update_chart(group):
    filtered = df[df.group == group]
    return px.histogram(filtered, x="value", title=f"Group {group}")

if __name__ == "__main__":
    app.run(debug=True)
```
