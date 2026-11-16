# M4 · Call the Right Customers First

**Month 4 of [LATAM Lab](../README.md): which invoices will be paid more than 30 days late, and who should the collections team call first?**

> *"Why is VIVA waiting 60+ days for money it already earned, and which five phone calls would change that?"*

A logistic regression flags risky invoices **before** they become late, so a small collections team can chase the right customers first. Everything runs on free tools (Python, scikit-learn) on a normal laptop.

> **About the data.** VIVA's 800 invoices are a **practice dataset** (59 customers, about €19M, December 2009 to November 2011), not real ledger data. Its shape comes from a real public payment dataset and its severity is calibrated to Latin America with the Coface 2025 payment survey. Read the percentages as a demonstration of the method. See [Reference/Data Sources.md](Reference/Data%20Sources.md).

---

## Business reports (start here)

| Language | Report |
|---|---|
| English | [business-report-EN.md](Business%20Report/business-report-EN.md) |
| Español | [business-report-ES.md](Business%20Report/business-report-ES.md) |

The reports are written for the person who decides whom to call, not for the person who writes the code.

## Headline results

| | |
|---|---|
| Late invoices | 166 of 800 (20.8%), **€3.58M, 19% of everything billed** |
| Concentration | **5 customers hold 70%** of the late money; chronic payers hold 81% |
| Model | Logistic regression, random stratified 80/20 split (640 train, 160 test) |
| Test result | Caught **27 of 33** late invoices; 23 false alarms, 6 missed |
| Calls needed | 50 instead of 160 (**-69%**) |
| Doing nothing | 79.4% accurate, **catches 0 late invoices** |

![Late money by customer](Business%20Report/late_money_by_customer.png)

![Weight of each clue in the model](Business%20Report/model_clue_weights.png)

**Honest caveats** (more in the reports): the test has only 33 late invoices; the model mostly reads the customer's risk tier, which is also how the practice data was built; and on a strict past-to-future split the model is right on only 40% of its alarms, so the random-split scores are a best case.

---

## Model settings in the code

| Step | Setting | Why |
|---|---|---|
| Split | `train_test_split(test_size=0.2, stratify=y, shuffle=True, random_state=2995)` | Random 80/20; stratify keeps the same late rate (20.8% / 20.6%) in both groups; fixed seed gives the same split every run |
| Scaling | `StandardScaler()` | Puts every clue on one scale so weights are comparable |
| Model | `LogisticRegression(max_iter=1000, class_weight="balanced", random_state=2995)` | Balanced weights make each late invoice count about 2.4x, catching more late payers at the cost of more false alarms |
| Defaults | `penalty="l2"`, `C=1.0`, `solver="lbfgs"` | Standard regularization; tuning `C` over a 1,000,000x range changed test accuracy by only 2 points |
| Decision rule | probability at or above 0.5 means "late" | Standard cut-off |

---

## Repository layout

```
M4/
├── README.md
├── Data/
│   ├── generate_dataset.R      # builds the practice dataset (R)
│   ├── viva_invoices.csv       # 800 invoices
│   └── viva_customers.csv      # 59 customers
├── Models/
│   ├── run_models.py           # trains and scores the models, writes results.json
│   └── results.json            # output read by the charts
├── Business Report/
│   ├── business-report-EN.md
│   ├── business-report-ES.md
│   ├── make_charts.py          # results.json -> report charts (EN + ES)
│   └── *.png                   # charts used in the reports (same colors as the M4 brand)
└── Reference/
    └── Data Sources.md         # where the data shape and calibration come from
```

## Reproduce it

Requires Python 3.11+ with `pandas`, `numpy`, `scikit-learn`, `matplotlib`.

```bash
python Models/run_models.py                      # train, score, write Models/results.json
python "Business Report/make_charts.py"          # rebuild the report charts
```

The seed is fixed (2995), so reruns give identical numbers. To regenerate the dataset itself, run `Data/generate_dataset.R` in R.

## What could go wrong

- **Practice data.** Rerun on your own invoices and compare with what your collections team already knows before acting on any number.
- **Circularity.** The tier clue mirrors how the practice data was generated, so real-world accuracy would likely be lower.
- **Not a savings number.** We did not measure how much faster customers pay after a call. Pilot the calls before putting a euro figure on it.
- **Who owns the decision.** A model flags risk. People decide whom to call and how.

---

[← Back to LATAM Lab](../README.md)
