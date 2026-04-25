# Month 2 — Who Is About to Leave?

**AI LATAM Lab · Open-Source Business Intelligence for Latin American SMEs**
*A 12-month series applying AI and analytics to real business problems — without cloud infrastructure or deep technical teams.*

---

## 🎯 Business Scenario

In Latin America, switching telecom providers costs customers almost nothing.

>No cancellation fee. No long wait. Just a new SIM card and a better promotional rate. LATAM prepaid churn runs between 37–62% annually (BNamericas) — meaning operators must replace their entire prepaid subscriber base approximately every 21 months. Claro, Tigo, and Movistar compete in a market where acquiring a new customer costs **6–7 times more** than retaining an existing one — yet most operators still wait for the cancellation call before offering a discount.

Last monnth was about demand, this month is protecting customers you arelady have.

A critical question — but most aren't tracking in real time:

> **Which postpaid customers are about to leave — and can we reach them in time?**

We use machine learning to move from reactive postmorten to proactive retention. The model doesn't predict all customers equally — it's calibrated specifically to catch the ones most likely to leave, even at the cost of a few extra outreach calls.

---

## 📁 Dataset

**Source:** [IBM Telco Customer Churn — Kaggle](https://www.kaggle.com/datasets/blastchar/telco-customer-churn)
**License:** Public domain / educational use
**Records:** 7,043 customers · 21 variables · 0 duplicate rows · 11 missing values (removed)

**This is a postpaid dataset.** In the LATAM context, that matters: postpaid customers represent the highest-value, highest-margin segment — and the one most worth retaining. The prepaid market (dominant in markets like Mexico) has different churn dynamics entirely.

**Key variables used in modeling:**

| Variable | Type | Why It Matters |
|---|---|---|
| `tenure` | Numerical | Months as a customer — the single strongest loyalty signal |
| `MonthlyCharges` | Numerical | Price sensitivity driver |
| `Contract` | Categorical | Month-to-month vs. annual commitment |
| `OnlineSecurity` | Categorical | Proxy for how embedded the customer is in the ecosystem |
| `TechSupport` | Categorical | Unresolved issues = churn trigger |
| `InternetService` | Categorical | Fiber Optic customers churn at disproportionately high rates |
| `PaymentMethod` | Categorical | Electronic check correlates with higher churn risk |

**Dropped variables:**
- `TotalCharges` — r = 0.83 with `tenure`. Including both causes multicollinearity and model instability. Tenure is the stronger behavioral predictor.
- `Gender`, `PhoneService` — Cramér's V < 0.02. Statistically useless for predicting churn.
- `customerID` — identifier, not a predictor.

---

## 🔧 Tools & Libraries

| Tool | Why |
|---|---|
| R + base R | Open-source, no cloud dependency — runs on any machine |
| `randomForest` | Production model — stable, handles categorical data natively |
| `xgboost` | Challenger model — highest benchmark recall, used for comparison |
| `ggplot2`
| `caret` / manual matrix | Confusion matrix and threshold tuning |

All code runs locally. No cloud account required. No API keys. No paid tier.

---

## 📊 Analysis Steps

>  [!IMPORTANT]
> The data use is pretty clean and structure which is not how happens in real life, the transformation and preparation of the data is critical. With public datasets like this one,usually the process is already done, however, is always important to check. 

1. **Load and inspect the dataset** — 7,043 rows, 21 columns, class imbalance check (26.5% churn rate)
2. **Feature selection — Cramér's V** — measure association between each categorical variable and Churn; drop low-signal features
3. **Multicollinearity check** — Pearson correlation matrix; drop `TotalCharges` (r = 0.83 with `tenure`)
4. **Train/test split** — 70% train / 30% test, stratified by Churn target
5. **Scale numerical features** — z-score standardization on `tenure` and `MonthlyCharges` using training set statistics only
6. **Logistic Regression (baseline)** — interpretable linear model; sets the performance floor
7. **Random Forest (production candidate)** — 500 trees, variable importance extraction, partial dependence plots
8. **XGBoost (challenger)** — gradient boosted trees, 100 rounds, AUC evaluation metric
9. **Threshold optimization** — shift classification threshold from 50% → 30% to maximize recall
10. **Business output** — confusion matrix translated into revenue impact and campaign targeting rules

## 📙 Business Report

→ [Read the full business report](./M02_Business_Report.md) for the executive summary, ROI calculation, campaign targeting profile, and Monday morning decision rule.

---

## 🗂️ Repository Structure

```
Month #2/
├── M02_Churn_Prediction.Rmd     # Full annotated notebook
├── latam_eda.R                  # Reusable EDA toolkit (all months)
├── M02_README.md                # This file
└── M02_Business_Report.md       # Executive business report
```

---

## ⚠️ What Could Go Wrong

This model makes predictions — it does not make decisions. Before deploying in a real telecom environment:

- **Data drift:** IBM Telco is a US-based postpaid dataset. LATAM prepaid dynamics, local carrier promotions, and economic volatility (exchange rates, inflation) can all shift churn patterns rapidly. Retrain every quarter.
- **Label leakage:** Ensure `TotalCharges` stays out of production pipelines — it encodes tenure implicitly and can inflate apparent performance.
- **Threshold governance:** The 30% threshold creates false alarms. Every false alarm is a customer who receives an unnecessary retention offer. Track false alarm rates quarterly and adjust.
- **Data privacy:** Even aggregated churn models can reveal sensitive behavioral patterns. Follow applicable LATAM data protection frameworks (LGPD in Brazil, Ley Habeas Data in Colombia, Ley Federal de Datos Personales in Mexico) before production deployment.

---

## 📎 Data Attribution

IBM Sample Data · [Kaggle Dataset](https://www.kaggle.com/datasets/blastchar/telco-customer-churn) · Educational use
LATAM telecom statistics: CIU Mexico (2021), GSMA Intelligence (2023)

---

*Part of the [AI LATAM Lab](https://github.com/Khalenanassers/LATAM-LAB) — 12 months of open-source business intelligence for Latin American SMEs.*
*By [Khalena Nasser](https://linkedin.com/in/khalenanassers) · Business Intelligence & Strategy · Hamburg*
