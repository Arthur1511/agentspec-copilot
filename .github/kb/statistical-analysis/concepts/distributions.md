# Distributions

## What Is a Probability Distribution?

A probability distribution describes how values of a random variable are spread. It defines:
- **PMF / PDF** — probability of each value (discrete / continuous)
- **CDF** — cumulative probability up to a value
- **Parameters** — shape, location, scale

## Common Distributions

### Continuous

| Distribution | Parameters | Use Case |
|---|---|---|
| Normal (Gaussian) | μ, σ | Heights, errors, test scores |
| Log-normal | μ, σ | Salaries, asset prices, survival times |
| Exponential | λ (rate) | Time between events, wait times |
| Beta | α, β | Probabilities, proportions in [0,1] |
| Gamma | k, θ | Waiting time for k events |
| Uniform | a, b | Random sampling baseline |

### Discrete

| Distribution | Parameters | Use Case |
|---|---|---|
| Binomial | n, p | Count of successes in n trials |
| Poisson | λ | Count of events per interval |
| Negative Binomial | r, p | Count until r-th success (overdispersed) |
| Bernoulli | p | Single binary trial |

## SciPy Distribution API

```python
from scipy import stats

# Continuous distribution
dist = stats.norm(loc=5, scale=2)       # N(5, 2)
dist.pdf(x=5.0)                          # P(X = 5)
dist.cdf(x=6.0)                          # P(X ≤ 6)
dist.ppf(q=0.975)                        # inverse CDF (quantile)
dist.rvs(size=1000)                      # random samples
dist.interval(0.95)                      # 95% probability interval

# Discrete distribution
binom = stats.binom(n=20, p=0.3)
binom.pmf(k=6)                           # P(X = 6)
binom.mean(), binom.var()
```

## Fitting a Distribution

```python
import numpy as np
from scipy import stats

data = np.random.lognormal(mean=2, sigma=0.5, size=500)

# Fit log-normal
mu, sigma = stats.norm.fit(np.log(data))   # fit on log-scale
print(f"Fitted lognormal: mu={mu:.3f}, sigma={sigma:.3f}")

# Fit any SciPy distribution
params = stats.lognorm.fit(data, floc=0)   # floc=0 fixes location
shape, loc, scale = params

# Kolmogorov-Smirnov goodness-of-fit
ks_stat, p_val = stats.kstest(data, 'lognorm', args=params)
print(f"KS test: stat={ks_stat:.4f}, p={p_val:.4f}")
```

## QQ-Plots (Normality Visual Check)

```python
import matplotlib.pyplot as plt
import statsmodels.api as sm

fig, axes = plt.subplots(1, 2, figsize=(12, 4))

# QQ-plot vs Normal
sm.qqplot(data, line='s', ax=axes[0])
axes[0].set_title("QQ-Plot vs Normal")

# Histogram + fitted PDF
x_range = np.linspace(data.min(), data.max(), 200)
axes[1].hist(data, bins=40, density=True, alpha=0.5)
axes[1].plot(x_range, stats.lognorm.pdf(x_range, *params), 'r-', lw=2)
axes[1].set_title("Histogram + Fitted PDF")
plt.tight_layout()
```

## Simulation

```python
rng = np.random.default_rng(seed=42)    # reproducible

# Simple sampling
samples = rng.normal(loc=0, scale=1, size=10_000)

# Mixture distribution
mask = rng.random(10_000) < 0.3          # 30% from component A
x = np.where(mask, rng.normal(0, 1, 10_000), rng.normal(5, 1.5, 10_000))

# Bootstrap
boot_means = [rng.choice(data, len(data), replace=True).mean()
              for _ in range(10_000)]
boot_ci = np.percentile(boot_means, [2.5, 97.5])
```

## Decision Guide

| Observation | Likely Distribution |
|---|---|
| Symmetric, bell-shaped | Normal |
| Right-skewed, positive values | Log-normal or Gamma |
| Count of rare events | Poisson |
| Proportion bounded [0,1] | Beta |
| Heavy tails, outliers | Student-t or Cauchy |
| Always use QQ-plot to verify | — |
