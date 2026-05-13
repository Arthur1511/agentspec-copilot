# Matplotlib Foundations

## Figure and Axes Model

Every matplotlib graphic has a strict hierarchy:

```
Figure  — the entire canvas (one per output)
└── Axes (plural: Axes) — individual plot area with coordinate system
    ├── Axis (x, y) — tick marks, labels, limits
    ├── Artists — Lines, Patches, Text, Collections
    └── Legend, Title, Colorbar
```

**Always use the Object-Oriented (OO) API** for reproducible, testable code. Use `plt.show()` only for interactive exploration.

```python
import matplotlib.pyplot as plt
import numpy as np

# OO API — preferred
fig, ax = plt.subplots(figsize=(8, 5), dpi=150)
ax.plot(x, y, color="steelblue", linewidth=2, linestyle="-", label="Signal")
ax.set(xlabel="Time (s)", ylabel="Amplitude", title="Signal over Time")
ax.legend(loc="upper right", framealpha=0.9)
fig.tight_layout()

# Multiple axes
fig, axes = plt.subplots(1, 2, figsize=(12, 4))
for ax in axes.flat:
    ax.set_xlabel("x")
```

## rcParams — Global Style

```python
import matplotlib as mpl

# Override defaults once per session
mpl.rcParams.update({
    "figure.figsize": (8, 5),
    "figure.dpi": 150,
    "axes.spines.top": False,
    "axes.spines.right": False,
    "axes.grid": True,
    "grid.alpha": 0.3,
    "font.size": 11,
    "font.family": "sans-serif",
    "lines.linewidth": 1.8,
    "legend.frameon": True,
    "legend.framealpha": 0.9,
})

# Or use a style sheet
plt.style.use("seaborn-v0_8-whitegrid")   # built-in styles
plt.style.use(["seaborn-v0_8-whitegrid", "custom.mplstyle"])  # stacking
```

## Common Plot Types

```python
# Line
ax.plot(x, y, color="steelblue", lw=2, marker="o", ms=5)

# Scatter
ax.scatter(x, y, c=colors, s=sizes, alpha=0.6, cmap="viridis")

# Bar
ax.bar(categories, values, color="steelblue", edgecolor="white", width=0.6)
ax.barh(categories, values)            # horizontal

# Histogram
ax.hist(data, bins=30, density=True, color="steelblue", alpha=0.7)

# Error bars
ax.errorbar(x, y, yerr=std_err, fmt="o-", capsize=4, color="steelblue")

# Fill between
ax.fill_between(x, y_lower, y_upper, alpha=0.2, color="steelblue")

# Heatmap (imshow)
im = ax.imshow(matrix, cmap="coolwarm", aspect="auto", vmin=-1, vmax=1)
fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
```

## Axes Configuration

```python
ax.set_xlim(0, 100)
ax.set_ylim(bottom=0)                   # only set lower bound
ax.set_xticks([0, 25, 50, 75, 100])
ax.set_xticklabels(["0%", "25%", "50%", "75%", "100%"])
ax.tick_params(axis='x', rotation=45)
ax.yaxis.set_major_formatter(mpl.ticker.PercentFormatter(xmax=1))

# Log scale
ax.set_yscale("log")
ax.yaxis.set_major_formatter(mpl.ticker.ScalarFormatter())
```

## Annotations and Text

```python
# Add reference line
ax.axhline(y=0, color="black", lw=0.8, ls="--")
ax.axvline(x=threshold, color="red", lw=1.2, ls="--", label=f"Threshold={threshold}")

# Shade a region
ax.axhspan(ymin=-1, ymax=1, alpha=0.1, color="green", label="±1σ band")

# Arrow annotation
ax.annotate(
    "Peak", xy=(x_peak, y_peak), xytext=(x_peak + 2, y_peak + 5),
    fontsize=10, arrowprops=dict(arrowstyle="->", color="black")
)

# Text box
ax.text(0.02, 0.97, f"n={n}\nAUC={auc:.3f}", transform=ax.transAxes,
        va="top", fontsize=9,
        bbox=dict(boxstyle="round", facecolor="white", alpha=0.8))
```

## Saving Figures

```python
fig.savefig("output.png", dpi=150, bbox_inches="tight")   # raster
fig.savefig("output.pdf", bbox_inches="tight")             # vector (publication)
fig.savefig("output.svg", bbox_inches="tight")             # editable vector
plt.close(fig)                                              # free memory
```

## Pitfalls

| Pitfall | Fix |
|---------|-----|
| `plt.show()` in scripts | Use `fig.savefig()` instead |
| Hardcoded colors | Define a palette dict at module level |
| `ax = plt.gca()` (implicit state) | Always use `fig, ax = plt.subplots()` |
| Not calling `tight_layout` | Labels get clipped |
| Too many ticks / grid lines | Reduce with `ax.set_xticks()` |
