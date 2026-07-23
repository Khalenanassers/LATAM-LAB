# Month 3 — Can We See It Coming?

**AI LATAM Lab · Open-Source Business Intelligence for Latin American SMEs**
*A 12-month series applying AI and analytics to real business problems — without cloud infrastructure or deep technical teams.*

---

## :dart: Business Scenario

In Latin America, the cash crisis is not the surprise. The timing is.

> Distribuidora VIVA is a mid-size food & beverage distributor operating across Latin America. Customers pay on 30–60 day terms. Suppliers want payment on the 15th. Payroll lands on the last Friday of the month. VIVA's finance team does not have a cash flow model — they have a spreadsheet and a prayer.

Per the Coface 2025 Latin America Corporate Payment Survey (300+ companies across Argentina, Brazil, Chile, Colombia, Ecuador, and Peru): the average granted payment term is **59 days**, and **77% of companies** report that customers pay late — by an average of **42 additional days**. Cash arrives roughly 3 months after the sale. The supplier bill arrives 2 months after. That gap is where the crisis lives.

Last month was about protecting customers you already have. This month is about protecting the cash that keeps the business running.

> **The question: can we see the cash crisis coming 2–3 months before it hits?**

We build an early warning system using time series decomposition, hypothesis testing, and four forecasting approaches — from pure business logic to Bayesian ML. The goal is not a perfect model. The goal is enough warning to make the call before it becomes an emergency.

---

## :file_folder: Dataset

**Primary — Inflows**
**Source:** [UCI Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii) · [Kaggle Mirror](https://www.kaggle.com/datasets/mashlyn/online-retail-ii-uci)
**License:** CC BY 4.0 — free to use and adapt
**Records:** ~1 million invoice-level transactions
**Scenario period:** January 2025 – December 2026 *(underlying UCI source data: Dec 2009 – Nov 2011, dates shifted +15 years for narrative currency)*

**LATAM Calibration — Seasonality Anchor**
**Source:** [Corporación Favorita Grocery Sales — Ecuador](https://www.kaggle.com/competitions/favorita-grocery-sales-forecasting) · Kaggle competition, educational use

**Outflows — Synthetic (Calibrated)**
No public SME outflows dataset exists for Latin America. Outflows are generated synthetically using cost benchmarks from IDB, World Bank, and ECLAC, calibrated to a LATAM food & beverage distributor profile.

| Cost Category | % of Revenue | Payment Timing |
|---|---|---|
| COGS / Supplier payments | 55–65% | 30–60 day terms |
| Payroll | 10–15% | Monthly, end of month |
| Rent | 3–5% | 1st of month |
| Utilities | 2–3% | Mid-month |

**Key data decisions:**

| Decision | Why |
|---|---|
| `InvoiceDate` treated as sale date, not cash date | Realistic LATAM B2B payment behaviour — cash and invoice date are not the same thing |
| Collection lag: 23% on-term (~59 days), 77% late (~101 days) | Calibrated to Coface 2025 LATAM Corporate Payment Survey |
| Dec 2011 dropped (9 days only) | Prevents artificial cliff-edge at series end |
| Jan–Feb 2025 backfilled via YoY ratio (0.99) | Boundary months have incomplete lag coverage — disclosed assumption, not raw data |
| Price ≤ 0 rows excluded (6,207 rows) | Damages, write-offs, and adjustment entries — not real sales |
| Cancellations retained (negative quantity) | Returns reduce real cash received — they belong in the model |

---

## :wrench: Tools & Libraries

| Tool | Why |
|---|---|
| Python + Jupyter Notebook | Primary environment — open-source, runs locally |
| `pandas` / `numpy` | Data manipulation and time series aggregation |
| `statsmodels` | Decomposition (STL), ADF/KPSS stationarity tests, ARIMA, ACF/PACF |
| `prophet` | Bayesian forecasting with interpretable seasonal components |
| `scipy` + `pymannkendall` | Kruskal-Wallis and Mann-Kendall hypothesis tests |
| `matplotlib` / `plotly` | KN dark theme visualisations |
| `pmdarima` | AIC grid search for SARIMA parameter selection |

All code runs locally. No cloud account required. No API keys. No paid tier.

---

## :bar_chart: Analysis Steps

> :warning: **A note on sample size.** This analysis runs on 24 monthly observations — exactly 2 seasonal cycles. That is the minimum for seasonal decomposition, and it makes certain statistical tests (notably Kruskal-Wallis for seasonality) severely underpowered. Every step flags this honestly. The methods are correct; the conclusions are calibrated to what 24 data points can and cannot support.

1. **Build the cash flow series** — aggregate UCI invoices to monthly inflows by *cash-received date* (applying Coface-calibrated collection lag per invoice), generate synthetic outflows from LATAM cost benchmarks, compute Net Cash = Inflows − Outflows
2. **Decomposition (STL)** — separate the series into trend, seasonality, and residual; choose additive vs. multiplicative based on data (negative values force additive — multiplicative is mathematically invalid)
3. **Stationarity testing (ADF + KPSS)** — determine if differencing is needed before forecasting; use both tests together to avoid false conclusions from either alone
4. **ACF / PACF analysis** — read autocorrelation structure; use as sanity check (with n=24, confidence bounds ±0.40 are too wide for reliable parameter selection)
5. **Hypothesis testing** — Kruskal-Wallis (does seasonal variation exist across months?); Mann-Kendall (is the cash position trending worse over time?)
6. **Model selection** — run AIC grid search across trend degrees and Fourier periods to identify the data-driven structure for the deterministic regression
7. **Four forecasting models** — Business Logic (no fitting), Fourier Regression (OLS), Prophet (Bayesian), ARIMA(1,0,2) (classical); compare on MAE, R², F1, recall, false alarm rate, overall bias (PBIAS), and crisis-month bias
8. **Bias analysis** — measure whether each model is systematically optimistic or pessimistic, especially on crisis months where the direction of error has direct business cost (optimistic = missed crises; pessimistic = safe early warnings)
9. **Alert logic** — set safety buffer at p10 of historical net cash (€-84k); translate forecast into a Monday morning decision rule

---

## :green_book: Business Report

:globe_with_meridians: *[Leer en Español](./business_report_ES.md)*
:globe_with_meridians: *[Read in English](./business_report_EN.md)*

---

## :card_index_dividers: Repository Structure

```
Month #3/
├── M03_notebook.ipynb              # Full annotated notebook (three-tier: Executive / Manager / Analyst)
├── synthetic_outflows.py           # Reusable LATAM SME outflow generator (M3 onward)
├── m03_collection_lag.py           # Reusable Coface-calibrated collection lag module
├── README.md                       # This file
├── business_report_EN.md           # Business report, English
└── business_report_ES.md           # Business report, Spanish
```

---

## :warning: What Could Go Wrong

This model makes predictions — it does not make decisions. Before adapting this to a real business context:

- **Data drift.** The UCI Online Retail II dataset is a UK-based B2B wholesaler from 2009–2011, adapted to a LATAM F&B distributor scenario. Real LATAM businesses face additional volatility: currency fluctuations, local supplier payment norms, informal credit arrangements, and seasonal patterns driven by local holidays rather than UK retail cycles. Calibrate with your own numbers before relying on forecasts.

- **Sample size ceiling.** 24 monthly observations is the floor for seasonal decomposition — not the ideal. The Kruskal-Wallis test is essentially meaningless with 2 observations per month group. The seasonal layer of SARIMA cannot resolve with this data volume — which is why we replaced it with pure ARIMA(1,0,2), which works well at 24 points. More history improves every model here, but you can start with what you have.

- **Safety buffer governance.** The p10 threshold (€-84k) is a starting point, not a fixed rule. The right buffer depends on your access to emergency credit, your supplier relationships, and the cost of acting early versus late. Review it quarterly.

- **Backfilled months.** January and February 2025 are estimated values, not raw data — derived from the median year-over-year ratio across clean overlapping months. This is disclosed in the notebook and should be disclosed in any business communication built on this analysis.

- **Data privacy.** Even aggregated cash flow models can reveal sensitive business performance patterns. If deploying to a multi-entity distributor or sharing outputs with external parties, apply applicable LATAM data protection frameworks: LGPD (Brazil), Ley Habeas Data (Colombia), Ley Federal de Datos Personales (Mexico).

---

## :paperclip: Data Attribution

UCI Online Retail II · [UC Irvine Machine Learning Repository](https://archive.ics.uci.edu/dataset/502/online+retail+ii) · CC BY 4.0
Corporación Favorita · [Kaggle](https://www.kaggle.com/competitions/favorita-grocery-sales-forecasting) · Educational use
Collection delay calibration: [Coface — 2025 Latin America Corporate Payment Survey](https://www.coface.com/news-economy-and-insights/2025-latin-america-corporate-payment-survey-longer-payment-terms-and-rising-delays)
Cost benchmarks: [IDB — SME Financing in Latin America](https://www.iadb.org/en/improving-lives/small-and-medium-enterprises) · [World Bank — MSME Finance Gap](https://www.smefinanceforum.org/data-sites/msme-finance-gap) · [ECLAC — Business Statistics LATAM](https://www.cepal.org/en/topics/statistics)

---

*Part of the [AI LATAM Lab](https://github.com/Khalenanassers/LATAM-LAB) — 12 months of open-source business intelligence for Latin American SMEs.*
*By Claude - Revview by [Khalena Nasser](https://linkedin.com/in/khalenanassers) · Business Intelligence & Strategy · Hamburg*
