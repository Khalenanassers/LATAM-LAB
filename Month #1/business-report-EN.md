# Stop Feeding the Dumpster
## How a free forecasting model recovers $15,000/month in spoiled produce — at one store

### The Problem in plain numbers

Grocery retail in Latin America runs on net margins of 2–3%. In that environment, every dollar of spoilage isn't an inconvenience — it's a direct hit to the bottom line.

Store 47's produce department generated an estimated **$1.46M in waste costs** across the analysis period. Three items alone accounted for over $235,000 of that:

| Item | Estimated Loss |
|---|---|
| Plantain (Maqueño) | $92,983 |
| Tomato (Riñón) | $76,257 |
| Yellow Peaches | $66,749 |
| Watermelon (Sandía) | $58,282 |
| Green Banana (Orito) | $37,505 |

This is the classic revenue vs. profit mismatch: the aisles that sell the most are not the ones destroying your margin. The ones with the shortest shelf life are.

---

### Three Findings That Change How You Think About Ordering

Before building any model, we ran formal statistical tests to understand *why* waste happens. The results dismantled several common assumptions.

**1. The human reaction to demand is more volatile than demand itself.**

We measured variability using the Coefficient of Variation (CV) — a ratio that tells you how erratic a number is relative to its average.

- Customer demand CV: **0.33** (relatively stable)
- Manager-driven waste CV: **0.52** (highly erratic)

It is not the customer who introduces chaos into the inventory. It is the ordering decision. That's the problem worth solving.

**2. Slow days are the most dangerous.**

Pearson correlation testing confirmed a strong inverse relationship between daily sales and daily waste. When fewer customers shop, managers don't order less — they order for the busy weekend they're expecting. The excess sits on the shelf and spoils.

**3. Thursday is always the worst day — and we can predict it.**

ANOVA testing confirmed that spoilage is not randomly distributed across the week. Managers over-order heading into the Saturday/Sunday peak. By Thursday, the buffer has been sitting for four days. The result is a predictable weekly spoilage spike — same day, every week.

Predictable problems are solvable problems.

>  [!IMPORTANT]
> *Governance note #1* When ordering decisions are informal, undocumented, and invisible to management, there is no way to audit them, improve them, or hold them accountable. A forecasting model doesn't just improve accuracy — it makes the decision-making process transparent.

---

### Why We Rejected the "Best" AI Model

We tested six forecasting approaches against the manager baseline. Round one went to accuracy.

| Model | Accuracy | MAPE | MAE (Units) | RMSE | Bias |
|---|---:|---:|---:|---:|---:|
| **Random Forest** | **91.87%** | **8.13%** | 454.69 | 571.49 | +0.65% |
| Holt-Winters | 91.14% | 8.86% | 499.79 | 669.28 | -2.00% |
| FB Prophet | 91.08% | 8.92% | 473.67 | 594.75 | +5.72% |
| Manager (7-day repeat) | 90.92% | 9.08% | 515.15 | 657.51 | -3.02% |
| 30-Day Average | 79.79% | 20.21% | 1,053.05 | 1,238.86 | +7.61% |
| Linear Regression | 54.41% | 45.59% | 2,341.06 | 2,559.12 | +40.69% |

Random Forest wins on MAPE. We still didn't choose it. Here's why.

<img width="2684" height="885" alt="image" src="https://github.com/user-attachments/assets/144c8c41-e8a2-4310-8122-af2c55b68dbb" />

Every model rests on statistical assumptions about how its errors behave. Before trusting a model in production, you test whether those assumptions hold — the same way you check you have all the ingredients before cooking a recipe. Random Forest failed two of those tests:

- **Heteroscedasticity** (Levene test): its errors grew larger and less predictable in high-volume conditions — exactly when accurate forecasting matters most.
- **Non-normal error distribution** (Shapiro-Wilk test): its residuals were skewed, meaning its reported accuracy metrics were unreliable.

A model that violates these assumptions doesn't just have larger errors — it has *unpredictable* errors. A store manager relying on it during a holiday week would be flying blind, armed with false confidence from a leaderboard number.

**Holt-Winters**, by contrast, showed consistent, symmetrical errors — a clean bell curve. It captured the 7-day weekly seasonality clearly. Its slight negative bias (-2%) means it would rather leave the shelf slightly under-stocked than buried in waste.

In supply chain management, a predictable, stable error is worth more than an occasionally-brilliant one that fails without warning.

> **On the manager baseline:** The manager's 90.92% accuracy looks respectable — but it's a data artifact. Strong weekly cyclicality inflates accuracy for any method that repeats the prior week. In real conditions with irregular demand shocks — holidays, weather, promotions, oil price drops — this approach fails suddenly and without warning.

---

### The Numbers That Matter

**30-Day Pilot — Store 47**

<img width="3571" height="1911" alt="image" src="https://github.com/user-attachments/assets/ad11a15b-6202-475b-b7e6-74ca3a0460ab" />

| | Status Quo | With Holt-Winters | Difference |
|---|---:|---:|---:|
| Waste cost | $35,925 | $20,460 | **-$15,465** |
| Reduction | — | — | **-43%** |

**Annualized projection — 54-store network**

| Scenario | Estimated Annual Savings |
|---|---:|
| All 54 stores adopt Holt-Winters | **$10,021,388** |

These are conservative. The 30-day pilot used produce only. Bakery, dairy, and meat departments have comparable or higher spoilage profiles.

---

### Can You Build This Yourself?

Yes. This matters more than the model selection.

High-impact analytics does not require a cloud budget or a data science team. In 2026, the barrier to entry is lower than it has ever been.

**The technology stack: free.**
This entire pipeline runs in Python and SQLite on Jupyter Notebook — open-source tools available on any back-office machine. No licenses. No cloud fees. No vendor contracts.

**The model: transparent.**
Holt-Winters was chosen not just because it performed well, but because its assumptions are visible and testable. Before deploying it, you verify they hold for your data. A model you can explain to your operations manager is a model you can actually use.

**The AI sidekick: optional but powerful.**
You don't need to code this from scratch. Pull your sales data, prepare your business context, and bring it to any LLM (this analysis used Gemini 2.5 Pro via Google AI Studio — free tier). Ask it to walk through the implementation step by step.

But challenge it. Ask why. Question the model assumptions. Your business knowledge is not replaceable — it's the reason the output is useful. The goal is not to automate your judgment. It is to give your judgment better inputs.

> ⚠️ **One critical prerequisite:** Data quality is non-negotiable. If your sales records have gaps, inconsistent SKU mapping, or uncorrected returns, don't start with models. Start with the data. A 91% accurate model on bad data is still a bad model.

---

### Monday Morning Decision Rule

**This week:** Pull your top 10 perishable items by sales volume. Calculate the standard deviation of daily orders for each one. If the variability in your *orders* is higher than the variability in your *sales*, you have a human-driven waste problem — not a demand problem. That's the signal. This analysis shows what to do next.

> [!IMPORTANT]
> *Governance note #2: On open-source tools and your data.* 
>Every library used in this project — Python, SQLite, pandas, statsmodels, Prophet — is open-source. That means the code is publicly readable, freely auditable, and maintained by global communities. There are no black boxes.
> The entire analysis runs locally. No API calls to external servers. No cloud storage. No vendor with access to your transaction history. SQLite is a file on your computer — it goes nowhere unless you send it somewhere.
> Open-source removes the vendor risk. It doesn't remove the governance requirement. Someone in the organization should understand what the model is doing, check its assumptions periodically, and own the decision to act on its forecasts.


[← Back to Series README](../README.md) 
