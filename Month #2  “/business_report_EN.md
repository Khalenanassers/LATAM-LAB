# Who Is About to Leave? 

**AI LATAM Lab · Month 2 of 12**
*Autopsy vs. Early Warning — moving from reactive to predictive intelligence*

---

## The Question You Were Losing Money Not Knowing

> *Which postpaid customers are about to cancel — and who do I call first?*

Most telecom operators in Latin America find out a customer is leaving when the customer calls to cancel. By then, the relationship is already over. The team offers a discount. Sometimes it works. Usually it doesn't.

So, using AI, more specific machine leaning to help predict IF customer are going leave or not. Hopefully with enough time to help the team have a defence plan. 


## What Is Churn?
 
**Churn** is the rate at which customers stop doing business with a company over a given period — the direct opposite of retention (IBM, 2025). There are two types: **voluntary churn**, when a customer actively decides to leave due to price, dissatisfaction, or a better competitor offer; and **involuntary churn**, when a customer drops off without intent — a failed payment, an expired card, a contract lapse. Involuntary churn accounts for 20–40% of total attrition depending on the industry, and most of it is preventable (rethinkCX, 2025).
 
The business model determines which type dominates. In LATAM prepaid telecom, churn is largely competitive and frictionless — a new SIM card costs nothing. In **postpaid**, the dominant risk is voluntary: customers actively weighing alternatives, sensitive to price and service quality, who can still be reached before they make the call.
 
*Sources: IBM Think (2025) · rethinkCX (2025) · BNamericas*

---

## 1. The Business Context

Latin America's telecom market reached **456 million mobile accesses in 2024** — a region of half a billion people where mobile connectivity is the backbone of everyday life. It is also one of the most churned markets in the world.

Switching providers carries almost no friction. In Mexico, the porting process takes 24 hours. In Colombia, less than 3 days. Promotional offers from Claro, Tigo, and Movistar run year-round — and price-sensitive customers take them.

**The numbers behind the problem:**

- LATAM prepaid churn runs between **37–62% annually** (BNamericas). Operators must replace their entire prepaid subscriber base approximately every 21 months.
- Annual churn across telecom globally ranges from **20–50%** (CustomerGauge, 2024). For a 1-million-customer base at $50 ARPU, a 20% churn rate erodes **$120 million in recurring revenue every year**.
- Acquiring a new telecom customer costs **6–7x more** than retaining an existing one. The economics of retention are not a strategy preference — they are a survival calculation.
- A 2024 McKinsey report estimates that AI-powered churn models can reduce churn by **up to 15%** when applied proactively.

The postpaid segment is where this hurts most. These customers generate higher average revenue per user (ARPU), are more likely to hold bundled contracts (mobile + internet + TV), and are harder to replace. Latin America remains predominantly a prepaid market — Mexico alone holds 32.3% of the region's total prepaid subscriptions — but the postpaid base is growing steadily, and every churned postpaid customer carries disproportionate revenue impact.


> [!IMPORTANT]
> :rotating_light:
> *Governance note 1:* Before you build a model, ask if you have a churn problem.
Check your business model first. Prepaid telecom, SaaS, subscription retail — churn looks different in each. If customers can leave without calling you, you probably have one.
If you do, everything in this notebook runs locally in RStudio — free, no cloud account required. Any LLM today can generate the code. That is not the hard part.
The hard part is the decisions: which metric to optimize, where to set the threshold, what the false alarm rate means for your customers. Those stay with you. Use AI to execute — but you ask the questions, you challenge the output, and you own the call.
Especially if you are learning: the model does not know your business. You do. Make the decision. Let AI do the rest. 

---

## 2. What the Data Told Us

We analyzed 7,043 customer records across 21 variables. After removing low-signal noise (gender, phone service type) and addressing multicollinearity (dropping Total Charges, which is essentially a formula derived from tenure and price), we identified five variables that predict churn with statistically meaningful strength.

### Top Predictors of Churn

| Variable | Association with Churn (Cramér's V) | Business Translation |
|---|---|---|
| Contract Type | **0.41** | Month-to-month = no commitment, no friction to leave |
| Online Security | 0.35 | No security bundle = less embedded in the ecosystem |
| Tech Support | 0.34 | Unresolved issues are the last straw before cancellation |
| Internet Service Type | 0.32 | Fiber Optic customers are price-sensitive and volatile |
| Payment Method | 0.30 | Electronic check correlates with higher churn risk |

*Cramér's V measures statistical association between categorical variables and a binary target. Range: 0 (no association) to 1 (perfect association). Values above 0.30 are considered meaningful for business decision-making.*

### Three Patterns Every Telecom Manager Should Know

**Pattern 1 — The Month-to-Month Trap**
Customers on month-to-month contracts churn at dramatically higher rates than those on annual plans. The contract itself is both symptom and cause: customers who haven't committed are already evaluating alternatives. The retention team's primary call-to-action should not be a discount — it should be an offer to convert to a 1-year plan.

**Pattern 2 — The Fiber Optic Paradox**
Fiber is a premium product, priced accordingly. But premium pricing comes with premium expectations. When service has an outage, or a competitor runs a promotional rate, high-paying Fiber customers are more likely to leave than othes customers — not less. Price point creates vulnerability, not loyalty.

**Pattern 3 — The First-12-Months Danger Zone**
Churn risk is highest in the first year. Customers who have not yet built a history with the provider have not yet built a reason to stay. The partial dependence analysis of tenure confirms a clear inflection point: customers who survive past month 12 show substantially lower churn probability. The first year is where the relationship is won or lost.

---

## 3. Model Design

Before selecting a model, there are three questions every team needs to answer. The framework below makes them explicit.

<img width="2752" height="1536" alt="unnamed" src="https://github.com/user-attachments/assets/43629f13-7e49-4f8c-8821-972fd911a62d" />

*A practical decision framework for model selection in churn prediction. Three building blocks: What are you predicting? What does your data look like? What constraints do you have?*

### The Three Building Blocks

**Block 1 — What are you predicting?**
There are two fundamentally different churn problems. *Predict "IF"* — will this customer ever leave? — is a classification problem. *Predict "WHEN"* — how long until they leave? — is a survival analysis / lifetime value problem. This project solves the first: a binary Yes/No prediction of churn within the current period. For LATAM SMEs with limited data history, the "IF" question delivers faster, more actionable output.

**Block 2 — What does your data look like?**
Our dataset is tabular: tenure, monthly charges, contract type, service add-ons. This rules out deep learning (designed for sequential data like clickstreams) and points clearly to standard algorithms built for structured "Spend & Tenure" profiles.

**Block 3 — What are the hard constraints?**
Dataset size is 7,043 rows. That is a small-to-medium dataset by ML standards. Privacy: the IBM Telco data is educational — but in a real deployment, LATAM data protection law applies. These constraints directly inform the model choice: a computationally expensive, data-hungry model is the wrong tool here.

### The Three Approaches We Evaluated

**Logistic Regression — The Transparent Baseline**
Assumes customer behavior follows a straight line: "Each additional dollar in monthly charges increases churn probability by X%." Easy to audit. Easy to explain to a regulator or a non-technical executive. Struggles with complex, overlapping profiles — like a Fiber Optic customer on a month-to-month plan with no tech support who has been a customer for 8 months. Sets the performance floor.

**XGBoost — The Aggressive Challenger**
Builds 100 sequential decision trees, each correcting the errors of the last. Achieves the highest recall on this dataset. The tradeoff: it memorizes patterns aggressively on small data volumes, which can make it brittle when next quarter's customer behavior shifts. Excellent for benchmarking and short-cycle campaigns. Higher maintenance burden over time.

**Random Forest — The Production Recommendation**
Builds 500 independent decision trees and takes a majority vote — the "Wisdom of the Crowd" approach. Naturally robust to outliers and unusual customer profiles. Handles categorical variables natively without bloating the dataset into hundreds of binary columns. Does not require ongoing hyperparameter tuning. Most importantly: it will not fail quietly when a small batch of unusual customer data arrives next month. Per the model selector framework above — general robust accuracy on tabular data, moderate dataset size — Random Forest is the right fit.

### Why We Set the Threshold at 30%

The standard classification threshold is 50% — a model flags a customer as "churn risk" only if it is more than 50% confident. That is the right threshold when every false alarm is expensive.

In a telecom retention context, the math shifts. The cost of an automated email or a 10% discount on the next bill is negligible. The cost of missing a churner — losing their recurring monthly revenue permanently — is not. We lower the threshold to 30% to cast a wider net, accepting some false alarms in exchange for catching significantly more real churners in time.

---

## 4. Model Results

All models evaluated on a held-out test set of 2,113 customers, of whom 534 were confirmed churners.

### Confusion Matrix Summary — At 30% Threshold

| Model | Accuracy | Churners Caught | Churners Missed | False Alarms |
|---|---|---|---|---|
| Logistic Regression | 75.96% | 421 (78.8%) | 113 | 395 |
| Random Forest | 79.08% | 345 (64.6%) | 189 | 253 |
| XGBoost | 76.53% | 419 (78.5%) | 115 | 381 |

Reading this table: XGBoost at 30% is the recommendation — it catches the most churners (419 vs. 345 for Random Forest), misses the fewest (115 vs. 189), and generates 381 false alarms. In an automated campaign context, those false alarms are not a cost — they are customers who were not going to leave and who just received a retention offer. The worst outcome is a slightly happier customer. The 74 extra churners that Random Forest misses represent real recurring revenue leaving permanently. Also, the logistic regression has good results, it can be use but XCGboost has a -3% lower false alarms.

---

## 5. Business Impact

The model identified **419 of 534 confirmed churners** in the test set using XGBoost at a 30% threshold.

The model flagged 419 of 534 real churners in the test set — customers who were about to leave and can now be reached before they do.
Assume a conservative 30% of them respond to a retention offer. At $45 ARPU (Average Revevnue per user) and a 24-month average lifetime, that is ~126 customers retained and ~$136,000 in protected recurring revenue. The automated campaign costs roughly $840 to run.

That is a 160x return on campaign spend — before a single human picks up the phone.

*These figures are illustrative and based on industry-average assumptions for LATAM postpaid telecom. Apply your own ARPU and retention rate data to calibrate the model for your market.*

---

## 6. Who to Target First (another valuable output of the model)

The chart below shows how much each variable contributed to the XGBoost model's predictions — the features that matter most when deciding who is at risk.

<img width="778" height="547" alt="image" src="https://github.com/user-attachments/assets/1478710f-6f89-4123-87c9-62dadc5d3cd5" />

This translates directly into a targeting profile. The highest-risk customer looks like this:
 
| Variable | Risk Profile |
|---|---|
| Contract | Month-to-Month |
| Internet Service | Fiber Optic |
| Tenure | Under 12 months |
| Payment Method | Electronic check |
| Tech Support | No active subscription |
 
Customers matching all five are extreme flight risks. The retention call-to-action for this segment should not be a bill discount — it should be a conversion offer to a 1-year contract. The discount is the incentive. The contract is the outcome. That removes the top churn driver entirely.

---

## 7. What Could Go Wrong

Building a model is easy with AI. Deploying it responsibly is where the real work begins.

**Model drift.** This model was trained on IBM Telco data — a US-based dataset used here for educational purposes and adapted to a LATAM postpaid context. Customer behavior in Chile, Mexico, or Colombia may have different seasonality patterns, different price elasticity curves, and different competitive dynamics. Retrain the model on local data at least quarterly.

**Threshold governance.** The 30% threshold is a business decision, not a technical one. It should be reviewed by someone who understands the cost structure of each retention campaign. As campaign costs change — or as macroeconomic conditions shift ARPU — the right threshold shifts with them.

**False alarms at scale.** Every false alarm is a customer who receives an unsolicited retention offer. At a small scale, this is harmless. At scale, it can feel intrusive and create the perception that the company is anxious — not confident. Define a maximum false alarm rate before launch.

**Data privacy.** Even behavioral models carry privacy implications. Know which data protection regulations apply in your market before deploying to a production CRM. In Brazil: LGPD. In Colombia: Ley Habeas Data. In Mexico: Ley Federal de Datos Personales en Posesión de los Particulares.

---

## 8. Monday Morning Decision Rule

 >:pushpin: Where to start
>This is not a copy-paste template — the numbers depend on your context. But if you run a subscription business, some of this will feel familiar.
>First, check if someone on your team can help you set it up. RStudio is free, any LLM can write the code, and the data is probably already sitting in your CRM.
>Start with Logistic Regression. It is simple, transparent, and explainable to your team. Get comfortable with the results, then upgrade to the model that fits your data and your scale.
The model finds the names. You make the call.

That is the shift from autopsy to early warning.

---

*Part of the [AI LATAM Lab](https://github.com/Khalenanassers/LATAM-LAB) · Month 2 of 12*
*By [Khalena Nasser](https://linkedin.com/in/khalenanassers) · Business Intelligence & Strategy · Hamburg*
*"Autopsy vs. Early Warning — moving from reactive to predictive intelligence"*
