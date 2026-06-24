# Can We See It Coming?

**AI LATAM Lab · Month 3 of 12**
*Autopsy vs. Early Warning — moving from reactive to predictive intelligence*

---

## The Question

> *"I know I'm going to run short. I just never know when — until it's too late to call my supplier."*

This month we build an early warning system for Distribuidora VIVA — a mid-size food & beverage distributor operating across Latin America. The question is not whether the next cash gap will happen. It will. The question is whether we can see it 2–3 months before it does.

---

## The Business Context

Latin America's payment culture is not broken — it is just slow. Per the Coface 2025 Latin America Corporate Payment Survey (300+ companies across six countries): the average B2B payment term is **59 days**, **77% of companies** report late payment, and the average delay is an additional **42 days**.

Cash from a sale arrives roughly 3 months later. The supplier bill arrives in 2. That one-month gap is where the crisis lives.

VIVA runs short in four months out of every 24. Not because the business is failing. Because the timing is structural, predictable, and preventable.

 <img width="1570" height="962" alt="image" src="https://github.com/user-attachments/assets/465e827c-c655-407d-9cc0-b2982300cb97" />

*Red zones = months where net cash went negative. Both clusters trace to the same mechanism: lagged COGS bills landing against post-holiday revenue that arrived later than expected.*

---

## What the Data Told Us

We built a 24-month cash flow series using real invoice data (UCI Online Retail II, adapted to a LATAM F&B context) with synthetic outflows calibrated to IDB, World Bank, and ECLAC cost benchmarks.

Both crisis clusters follow the same pattern. Holiday-season sales generate large supplier bills 2 months later — but the cash from those sales doesn't arrive until 3 months later, because customers pay late. The bill arrives before the money does. This is a timing problem. Timing problems are foreseeable.

The series decomposes into a gently declining trend (the cash cushion is slowly eroding), a strong annual seasonal rhythm (peaks in January, troughs in April–May), and noise. The cash position is stationary — crises are recurring shocks within a stable process, not a downward spiral.

---

## Four Models, One Winner

We ran four forecasting approaches, each representing a different philosophy. The goal was not the best algorithm — it was the most honest answer.

![Four-Model Comparison](./charts/M03_step5_comparison.png)

| Metric | Business Logic | Fourier Reg. | Prophet | ARIMA(1,0,2) |
|---|---|---|---|---|
| MAE | **€37k** | €74k | €67k | €97k |
| R² | **0.880** | 0.550 | 0.585 | 0.296 |
| F1 (crisis detection) | **1.000** | 0.571 | 0.857 | 0.667 |
| False Alarms | **0** | 1 | 0 | **0** |
| Overall Bias (PBIAS) | **-0.6%** ✓ | 0.0% | -0.1% ✓ | +6.0% ⚠️ |
| Crisis-Month Bias | **-€71k** ✓ | +€128k ⚠️ | +€112k ⚠️ | +€164k ⚠️ |

**Business Logic** — pure arithmetic from Coface and IDB benchmarks, no fitting — outperforms every ML and statistical model on every metric. With 24 observations and a known mechanism, encoding the business logic directly beats trying to learn it from limited data.

**The bias finding is the strongest argument.** Business Logic is the only model that's pessimistic on crisis months — when things go wrong, it predicts they're worse than they actually are (by €71k on average). That's exactly what an early warning system should do. Every other model is optimistic on crisis months (by €112k–€164k), systematically underestimating the danger in exactly the moments when the alert needs to fire.

**Prophet** is the best data-driven model (F1=0.857, zero false alarms), but its optimistic crisis bias means it softens the alarm. **Fourier Regression** bridges business logic and ML with interpretable sin/cos terms. **ARIMA(1,0,2)** replaced our initial SARIMA — the seasonal MA term was causing false alarms because 24 months isn't enough for a 12-month seasonal structure.

---

## 3-Month Forecast

| Month | Business Logic | Prophet | Fourier Reg. | ARIMA(1,0,2) |
|---|---|---|---|---|
| Jan 2027 | €199k | €424k | €379k | €225k |
| Feb 2027 | €85k | €292k | €251k | €45k |
| Mar 2027 | €174k | €60k | €74k | €100k |

No model's point forecast breaches zero. But Business Logic shows February thinning to €85k, and Prophet shows March below €100k with confidence intervals reaching into negative territory. The models don't agree on where exactly the risk is. They agree it exists.

---

## What Could Go Wrong

**Data drift.** The underlying data is a UK wholesaler adapted to a LATAM scenario. Real LATAM businesses face currency fluctuations, informal credit, and local seasonal patterns. Calibrate with your own numbers.

**Sample size.** 24 months is the floor, not the ideal. Pure ARIMA works at this scale — the seasonal layer of SARIMA does not. More history helps every model.

**Backfilled months.** January and February 2025 are estimated values (median YoY ratio from clean overlapping months), not raw data. Disclosed assumption.

**Safety buffer.** The p10 threshold (€-84k) is a starting point. The right buffer depends on your cost of acting early versus acting late. Review it quarterly.

---

## Monday Morning Decision Rule

> 📌 Business Logic flags February 2027 at €85k — the thinnest margin in the next 3 months. Prophet and Fourier Regression both show March below €100k.
>
> None of the models is screaming crisis. All of them are saying: the margin is narrowing.
>
> **"You have 2 months. Call your supplier. The cost of this conversation is zero. The cost of not having it is emergency credit at 18%."**

The model finds the window. You make the call.

---

*Part of the [AI LATAM Lab](https://github.com/Khalenanassers/LATAM-LAB) · Month 3 of 12*
*By [Khalena Nasser](https://linkedin.com/in/khalenanassers) · Business Intelligence & Strategy · Hamburg*
