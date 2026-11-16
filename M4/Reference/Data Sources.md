---
type: reference
project: M4 Collections
last_updated: 2026-08-31
---

# Data Sources — M4 Collections and Late Payment Intelligence

Referents used to build `Data/generate_dataset.R` and its output (`viva_invoices.csv`, `viva_customers.csv`).

## Real dataset — shape/structure only, not used directly
**"Payment Date Dataset"**, Kaggle, by rajattomar132.
- 45,001 real closed B2B invoices, 1,434 customers, ~15 month window.
- Mirror: https://github.com/mundraroshan/Payment-Date-Prediction (Dataset.csv)
- More-than-30-days-late rate: 2.3% (North American discipline level, not LATAM).
- **Rejected for direct use**: no confirmed license, customer field contains lightly obfuscated real company names (e.g. Kroger, Walmart, Sysco).
- What we borrowed: amount distribution shape, days-late curve shape, customer concentration pattern (few anchor accounts, many small ones). Reference only — median 17.3k / mean 32.4k USD amount shape informed our log-normal parameterization.
- **Earlier candidate rejected first**: an initial Kaggle payment dataset had semi-obfuscated real company names and was rejected on the same provenance grounds before this one was found.

## LATAM severity calibration
**Coface, "2025 Latin America Corporate Payment Survey"**
https://www.coface.com/news-economy-and-insights/2025-latin-america-corporate-payment-survey-longer-payment-terms-and-rising-delays
- Average payment terms: 59 days (up from 53 in 2024)
- 77% of companies report late payments (up from 51% in 2024)
- Average length of delay: 42 days (down from 52 in 2024)
- Brazil: longest terms (66 days). Ecuador: longest delays (70 days).
- Covers Argentina, Brazil, Chile, Colombia, Ecuador, Peru, 300+ companies.

**Coface, "2024 Payment Behavior in Latin America"** (prior-year trend context)
https://www.coface.com/news-economy-and-insights/more-restrictive-credit-terms-and-much-longer-payment-delays-in-latin-america
- 51% of companies reported late payment in 2024.
- Average delay duration rose from 36 to 52 days.
- Ultra-long delays (150+ days): 6% of companies in 2024 vs under 1% in 2023.

## Revenue scale anchor
M3's inflow chart (Dec 2009–Nov 2011), monthly inflows ~0.5M–1.17M EUR, informed M4's ~19M EUR total invoiced target for the same window (same narrative continuity as M3).

## How these fed the generator
- Amount distribution (log-normal, median ~16.4k EUR) — shape from the real Kaggle dataset, rescaled to VIVA's ~19M EUR revenue window (M3 anchor).
- Days-late tiers (Reliable/Moderate/Chronic, 50/30/20 split) and severity (means -2/15/45 days) — calibrated to Coface's LATAM delay figures, not the real dataset's North American 2.3% rate.
- Customer concentration (Pareto-weighted invoice counts) — shape from the real dataset's customer concentration pattern.

See [[M04 Collections]] for full generation spec and locked/open decisions.
