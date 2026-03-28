# Stop Feeding the Dumpster
## How a free forecasting model recovers $15,000/month in spoiled produce — at one store

> A Quito grocery store was losing over $1.4M in spoiled produce — not because demand was unpredictable, but because the humans ordering inventory weren't reacting to it fast enough. A forecasting model, built in a week with open-source tools, cuts that waste by 43% in the first 30 days. Here's exactly how — and why you can do the same.

---

## 🎯 Business Scenario

Every grocery store in Latin America is running the same quiet calculation: order enough to avoid empty shelves, accept that some of it will spoil. It feels like the cost of doing business.

>The region produces enough food to feed itself and export to the world — yet 15% of total food production in Latin America and the Caribbean is lost or wasted along the supply chain (IDB / FAO). Of all the stages where that waste happens, retail is where Latin America is most exposed: the region has the highest retail-stage food wastage rate of any region globally at 17% — above Europe, North America, and Asia (Journal of Consumer Protection and Food Safety, 2025). Despite this, LAC generates 20% of all food lost globally from post-harvest through to retail (FAO) — a disproportionate share for its economic size.
The business case for fixing it is unambiguous: for every $1 invested in food waste reduction, the average return is $14 in cost savings (World Bank / FAO).

Store 47 — a flagship Supermaxi in Quito — could generated **$1.46M in estimated produce spoilage** over the analysis period. Not because customers are unpredictable. Because the ordering system wasn't listening to them.

---

## 📁 Dataset

**Source:** [Corporación Favorita Grocery Sales Forecasting](https://www.kaggle.com/competitions/favorita-grocery-sales-forecasting) — Kaggle (Educational Use License)

**Scope:** Store 47 (Quito) · January 2015 – August 2017 · 2,333,689 transactions filtered from the 125M-row national dataset

**Key tables used:**

| Table | What it contains |
|---|---|
| `waste_metrics` | Daily sales, simulated orders, waste quantity and cost per item |
| `items` | Product family, class, perishability flag |
| `holidays_events` | National and regional holidays with transfer flags |
| `oil` | Daily WTI oil price (macroeconomic proxy) |

**Data note — the simulated order layer:** Physical waste logs are not part of standard retail databases. The waste column was constructed by simulating the most common manager behavior: *order last week's average + 20% safety buffer.* This is a rational heuristic — but its cost becomes visible when you run it at scale. The simulation is calibrated against FAO regional spoilage benchmarks and documented in full in the notebook.

---

## 🔧 Tools & Libraries

| Tool | Why |
|---|---|
| Python 3.11 · Jupyter Notebook | Open-source. Runs on standard back-office hardware. No cloud required. |
| SQLite | Handles the full 2.3M-row filtered dataset without a server. |
| `statsmodels` (Holt-Winters) | The chosen production model — transparent, testable, explainable to non-technical stakeholders. |
| `prophet` (Meta) | Benchmarked against Holt-Winters. Higher raw accuracy; rejected on statistical grounds (see below). |
| `scikit-learn` (Random Forest) | Top accuracy on the leaderboard. Also rejected on statistical grounds. |
| `scipy` | Statistical hypothesis testing (Pearson, ANOVA, Levene, Shapiro-Wilk). |
| `pandas` · `matplotlib` · `seaborn` | Data transformation and visualization. |

---

## 📊 Analysis Steps

1. **Built a pilot database** — filtered 2.3M Store 47 transactions from the 125M-row national dataset into a local SQLite file.
2. **Simulated the baseline** — reconstructed the manager's ordering behavior (prior week average + 20% buffer) to establish a waste cost baseline.
3. **Sized the problem** — aggregated total spoilage cost by item to identify the top offenders and the departments driving losses.
4. **Tested three hypotheses** — ran Pearson correlation, ANOVA, and Coefficient of Variation analysis to understand *why* waste happens, not just how much.
5. **Built and ranked six forecasting models** — trained Random Forest, Holt-Winters, Prophet, Linear Regression, 7-day repeat, and 30-day average on 914 days of produce sales data.
6. **Applied a second filter** — ran diagnostic tests (Shapiro-Wilk, Levene, residual analysis) on each model to check whether its statistical assumptions held. This is the step most comparisons skip.
7. **Selected Holt-Winters** — not the highest accuracy, but the most trustworthy in production conditions.
8. **Calculated the 30-day financial impact** — compared actual waste cost under status quo vs. Holt-Winters forecast at Store 47, then projected to the full 54-store network.

