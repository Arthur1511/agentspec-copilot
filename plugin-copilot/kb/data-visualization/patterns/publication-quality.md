# Publication Quality Figures

## Purpose

Patterns for creating presentation-ready and publication-ready figures: consistent style, proper sizing, vector export, and accessible color palettes.

---

## Style Sheet Setup

```python
import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns

# ── Reusable style constants ─────────────────────────────────────────
PALETTE = {
    "primary":   "#2C6FAC",
    "secondary": "#E07B54",
    "neutral":   "#6C6C6C",
    "positive":  "#2CA25F",
    "negative":  "#D73027",
    "highlight": "#F7A800",
}

STYLE = {
    "figure.figsize":     (8, 5),
    "figure.dpi":         150,
    "figure.facecolor":   "white",
    "axes.spines.top":    False,
    "axes.spines.right":  False,
    "axes.grid":          True,
    "grid.alpha":         0.25,
    "grid.linestyle":     "--",
    "font.family":        "sans-serif",
    "font.size":          11,
    "axes.titlesize":     13,
    "axes.titleweight":   "bold",
    "axes.labelsize":     11,
    "xtick.labelsize":    9,
    "ytick.labelsize":    9,
    "legend.fontsize":    9,
    "legend.frameon":     True,
    "legend.framealpha":  0.9,
    "lines.linewidth":    1.8,
    "patch.edgecolor":    "white",
}

def apply_pub_style():
    mpl.rcParams.update(STYLE)
    sns.set_palette(list(PALETTE.values()))

apply_pub_style()
```

---

## Figure Sizing (Journal Standards)

```python
# Column widths for common journals
SIZES = {
    "single_col":   (3.35, 2.5),    # single column ~85mm
    "double_col":   (7.0, 4.0),     # full page ~180mm
    "half_page":    (5.0, 3.5),     # half page
    "presentation": (10.0, 6.0),    # 16:9 slides
    "poster":       (12.0, 8.0),    # poster panel
}

def create_pub_figure(size: str = "double_col", nrows: int = 1, ncols: int = 1,
                      **kwargs) -> tuple[plt.Figure, any]:
    w, h = SIZES.get(size, SIZES["double_col"])
    fig, axes = plt.subplots(nrows, ncols,
                              figsize=(w * ncols, h * nrows),
                              **kwargs)
    return fig, axes
```

---

## Consistent Color & Style

```python
def style_axis(ax: plt.Axes,
               xlabel: str = "",
               ylabel: str = "",
               title: str = "",
               grid_axis: str = "y") -> plt.Axes:
    """Apply consistent styling to a single Axes."""
    ax.set(xlabel=xlabel, ylabel=ylabel, title=title)
    ax.grid(axis=grid_axis, alpha=0.25, linestyle="--")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    return ax


def add_significance_bracket(ax, x1, x2, y, h, p_val):
    """Draw significance bracket between two x positions."""
    stars = "***" if p_val < 0.001 else "**" if p_val < 0.01 else "*" if p_val < 0.05 else "ns"
    bar_x = [x1, x1, x2, x2]
    bar_y = [y, y + h, y + h, y]
    ax.plot(bar_x, bar_y, color="black", lw=0.8)
    ax.text((x1 + x2) / 2, y + h, stars, ha="center", va="bottom", fontsize=10)
```

---

## Multi-Panel Layout

```python
from matplotlib.gridspec import GridSpec

def create_complex_layout(figsize=(14, 8)) -> tuple[plt.Figure, dict]:
    """Create a 2×3 grid with a wide top panel."""
    fig = plt.figure(figsize=figsize)
    gs = GridSpec(2, 3, figure=fig,
                  height_ratios=[1.4, 1],
                  hspace=0.40, wspace=0.35)

    axes = {
        "main":    fig.add_subplot(gs[0, :]),     # full-width top
        "bot_l":   fig.add_subplot(gs[1, 0]),
        "bot_m":   fig.add_subplot(gs[1, 1]),
        "bot_r":   fig.add_subplot(gs[1, 2]),
    }

    for ax in axes.values():
        style_axis(ax)

    return fig, axes

# Panel labels (a, b, c, d)
def add_panel_labels(axes: dict, fontsize: int = 12):
    for label, ax in zip("abcd", axes.values()):
        ax.text(-0.12, 1.05, f"({label})", transform=ax.transAxes,
                fontsize=fontsize, fontweight="bold", va="top", ha="right")
```

---

## Export

```python
def save_pub_figure(fig: plt.Figure, path: str,
                    formats: list[str] = ("pdf", "png")):
    """Save figure in multiple formats for publication + web."""
    import pathlib
    stem = pathlib.Path(path).stem
    directory = pathlib.Path(path).parent
    directory.mkdir(parents=True, exist_ok=True)

    for fmt in formats:
        fpath = directory / f"{stem}.{fmt}"
        dpi = 300 if fmt == "png" else None
        fig.savefig(fpath, dpi=dpi, bbox_inches="tight", facecolor="white")
        print(f"Saved: {fpath}")
    plt.close(fig)
```

---

## Checklist

```
□ Style applied via apply_pub_style() at top of notebook
□ Figure size matches target medium (journal / slide / poster)
□ All axes labeled with units (e.g., "Revenue ($)", "Time (days)")
□ Title describes finding, not just data ("Treatment increases CTR by 12%")
□ Grid subtle (alpha ≤ 0.25, dashed)
□ Colors from PALETTE dict — colorblind-safe
□ Significance brackets added where needed
□ Panel labels (a, b, c) for multi-panel figures
□ Exported as PDF (vector) for publication; PNG at 300 dpi for web
□ plt.close(fig) called after saving
```
