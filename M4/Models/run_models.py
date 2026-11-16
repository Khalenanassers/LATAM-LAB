"""
M4 · Late payment model: which invoices will be paid more than 30 days late?

What this script does, in plain words:
  1. Loads the VIVA invoices.
  2. Builds simple clues (features) about each invoice.
  3. Splits the data: random 80% of invoices to learn from, 20% to test on (stratified).
  4. Trains the main model (Logistic Regression) plus a "do nothing" baseline and
     three other models for comparison, then scores each one.
  5. Opens up the Logistic Regression: which clues push an invoice toward "late",
     and what the settings (class_weight, regularization, split) change.
  6. Works out the money at stake and who to call first.
  7. Sizes the problem for the whole company (late money by customer).
  8. Saves everything to results.json, which Business Report/make_charts.py
     turns into the report charts.

Run from any folder:  python Models/run_models.py   then   python "Business Report/make_charts.py"
"""
import pathlib, json
import pandas as pd, numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier, HistGradientBoostingClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import make_pipeline
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score, confusion_matrix

# ─────────────────────────────────────────────────────────────
# 1. SETTINGS: a fixed "seed" so every run gives the same results
# ─────────────────────────────────────────────────────────────
# Models use randomness (the split, Random Forest). A fixed seed makes the
# results repeatable so they can be reviewed and compared.
SEED = 2995
np.random.seed(SEED)
HERE = pathlib.Path(__file__).resolve().parent          # the Models folder
ROOT = HERE.parent                                      # the M4 folder

# ─────────────────────────────────────────────────────────────
# 2. LOAD THE DATA
# ─────────────────────────────────────────────────────────────
# One row per invoice. late_flag = 1 means paid more than 30 days late (what we predict).
# Sorted by date only so the "customer history" clues below are built in time order.
df = pd.read_csv(ROOT / "Data" / "viva_invoices.csv", parse_dates=["invoice_date"]).sort_values("invoice_date").reset_index(drop=True)

# ─────────────────────────────────────────────────────────────
# 3. BUILD THE CLUES (FEATURES) THE MODEL LEARNS FROM
# ─────────────────────────────────────────────────────────────
# Customer history: how often this customer paid late on their EARLIER invoices.
# Only past invoices are counted, so the model never peeks at the invoice it is predicting.
# (Simplification: a past invoice's outcome is treated as known by the time the next is issued.)
g = df.groupby("customer_id")["late_flag"]
df["prior_n"] = g.cumcount()                                   # how many invoices came before
df["prior_late_rate"] = (g.cumsum() - df["late_flag"]) / df["prior_n"].replace(0, np.nan)
df["prior_late_rate"] = df["prior_late_rate"].fillna(0.2)      # first invoice, no history: assume ~20% (the overall late rate)

# Invoice size (log scale tames very large invoices) and calendar month.
df["log_amt"] = np.log(df["amount_eur"])
df["month"] = df["invoice_date"].dt.month

# Customer risk tier, turned into 0/1 columns the models can read.
for t in ["Reliable", "Moderate", "Chronic"]:
    df["tier_" + t] = (df["customer_tier"] == t).astype(int)

X_cols = ["log_amt", "month", "prior_n", "prior_late_rate", "tier_Reliable", "tier_Moderate", "tier_Chronic"]
# Plain-English names for the clues.
LABELS = {"log_amt": "Invoice size (log euros)", "month": "Month issued",
          "prior_n": "Invoices the customer had before",
          "prior_late_rate": "Customer's past late rate",
          "tier_Reliable": "Customer is a Reliable payer",
          "tier_Moderate": "Customer is a Sometimes-late payer",
          "tier_Chronic": "Customer is a Chronic late payer"}

# ─────────────────────────────────────────────────────────────
# 4. SPLIT: RANDOM 80/20, KEEPING THE LATE/ON-TIME MIX THE SAME
# ─────────────────────────────────────────────────────────────
# 80% of invoices = training set (the model studies these).
# 20% = test set (invoices it has never seen, used only for scoring).
# Random shuffle, stratified on late_flag so both sets keep the same late rate.
X = df[X_cols]
y = df["late_flag"]
Xtr, Xte, ytr, yte = train_test_split(
    X, y,
    test_size=0.2,       # 20% set aside for testing
    random_state=SEED,   # fixed seed: same split every run
    stratify=y,          # preserve class proportions in train and test
    shuffle=True,
)
tr, te = df.loc[Xtr.index], df.loc[Xte.index]   # full rows (dates, amounts) for later steps
print(f"Training set size: {Xtr.shape[0]} samples")
print(f"Test set size: {Xte.shape[0]} samples")

# ─────────────────────────────────────────────────────────────
# 5. THE MODELS: Logistic Regression is the main one
# ─────────────────────────────────────────────────────────────
# Logistic Regression settings (everything not listed uses the scikit-learn default):
#   StandardScaler        puts every clue on the same scale first (mean 0, spread 1)
#   class_weight="balanced"  late invoices are only ~1 in 5, so each late invoice counts
#                         about 2.4x more during training (stops it ignoring the minority)
#   max_iter=1000         enough optimizer steps to converge
#   random_state=SEED     fixed seed
#   (defaults) C=1.0, penalty="l2", solver="lbfgs"
def make_lr(class_weight="balanced", C=1.0):
    return make_pipeline(StandardScaler(), LogisticRegression(C=C, max_iter=1000, class_weight=class_weight, random_state=SEED))

models = {
    # Baseline: always guess "paid on time". Any real model must beat this.
    "Majority baseline": None,
    # Weighs each clue and adds them up. Simple and easy to explain.
    "Logistic Regression": make_lr(),
    # A short flowchart of yes/no questions. Depth is capped at 4 to avoid memorising.
    "Decision Tree": DecisionTreeClassifier(max_depth=4, min_samples_leaf=15, random_state=SEED),
    # 300 decision trees that vote together.
    "Random Forest": RandomForestClassifier(n_estimators=300, min_samples_leaf=5, random_state=SEED),
    # Many small trees, each fixing the previous one's mistakes. Stand-in for XGBoost (not installed).
    "Gradient Boosting (XGBoost stand-in)": HistGradientBoostingClassifier(max_depth=3, learning_rate=0.05, max_iter=200, random_state=SEED),
}

out = {"n_train": len(tr), "n_test": len(te), "test_late_rate": float(yte.mean()),
       "train_late": int(ytr.sum()), "test_late": int(yte.sum()), "train_late_rate": float(ytr.mean()),
       "split_date": "random 80/20 stratified", "models": []}

# ─────────────────────────────────────────────────────────────
# 6. TRAIN EACH MODEL AND SCORE IT ON THE TEST INVOICES
# ─────────────────────────────────────────────────────────────
# The model gives each invoice a late-risk probability; 50% or more = "will be late".
# Scores saved per model:
#   accuracy  = share of all guesses that were right
#   precision = when it says "late", how often it is right
#   recall    = share of truly late invoices it caught
#   f1        = one score blending precision and recall
#   auc       = how well it ranks risky invoices above safe ones (0.5 = coin flip)
#   tp/fp/fn/tn = the four boxes of the confusion matrix (caught, false alarm, missed, correct)
def score(name, pred, proba):
    tn, fp, fn, tp = confusion_matrix(yte, pred, labels=[0, 1]).ravel()
    return dict(name=name, accuracy=accuracy_score(yte, pred),
        precision=precision_score(yte, pred, zero_division=0), recall=recall_score(yte, pred),
        f1=f1_score(yte, pred), auc=(roc_auc_score(yte, proba) if proba.any() else 0.5),
        tp=int(tp), fp=int(fp), fn=int(fn), tn=int(tn))

for name, m in models.items():
    if m is None:
        pred = np.zeros(len(yte), int); proba = np.zeros(len(yte))
    else:
        m.fit(Xtr, ytr); proba = m.predict_proba(Xte)[:, 1]; pred = (proba >= 0.5).astype(int)
    out["models"].append(score(name, pred, proba))

# ─────────────────────────────────────────────────────────────
# 7. LOOK CLOSER AT THE LOGISTIC REGRESSION: MONEY, TIERS, CALL LIST
# ─────────────────────────────────────────────────────────────
best = "Logistic Regression"; out["best"] = best
m = models[best]; p = m.predict_proba(Xte)[:, 1]
t = te.assign(p=p, pred=(p >= .5).astype(int))

# Label every test invoice: TP = late and caught, FP = false alarm, FN = late but missed, TN = correct "on time".
t["outcome"] = np.select([(t.pred == 1) & (t.late_flag == 1), (t.pred == 1) & (t.late_flag == 0), (t.pred == 0) & (t.late_flag == 1)], ["TP", "FP", "FN"], "TN")

# Money at stake: total euros in each outcome group.
out["eur"] = {k: float(t[t.outcome == k].amount_eur.sum()) for k in ["TP", "FP", "FN", "TN"]}

# Per customer tier: how many invoices were late and how many of those the model caught.
out["tier"] = [dict(tier=k, n=int(len(v)), late=float(v.late_flag.mean()),
                    caught=float(((v.pred == 1) & (v.late_flag == 1)).sum() / max(v.late_flag.sum(), 1)))
               for k, v in t.groupby("customer_tier")]

# ─────────────────────────────────────────────────────────────
# 8. WHY THE MODEL SAYS "LATE": COEFFICIENTS AND ODDS RATIOS
# ─────────────────────────────────────────────────────────────
# Logistic regression is a weighted sum of the clues, turned into a probability.
# Each clue has a coefficient (its weight, in log-odds). Because the clues were
# standardized first, the weights are comparable: coef = change in log-odds when
# the clue rises by one standard deviation. exp(coef) = odds ratio: values above 1
# push toward "late", below 1 push toward "on time".
sc, lr = m.named_steps["standardscaler"], m.named_steps["logisticregression"]
coef = lr.coef_[0]
out["lr"] = dict(intercept=float(lr.intercept_[0]), C=float(lr.C), solver=lr.solver, max_iter=int(lr.max_iter),
                 coefs=[dict(feature=f, label=LABELS[f], coef=float(c), odds_ratio=float(np.exp(c)),
                             mean=float(mu), sd=float(sd))
                        for f, c, mu, sd in zip(X_cols, coef, sc.mean_, sc.scale_)])

# Per-invoice reasons: contribution of each clue = its weight x how unusual the invoice is on it.
contrib = sc.transform(Xte) * coef
# A tier clue is only a "reason" when the customer really is in that tier (value 1).
def reasons(row, raw):
    ok = [i for i in np.argsort(-row) if row[i] > 0 and not (X_cols[i].startswith("tier_") and raw[i] == 0)]
    return [LABELS[X_cols[i]] for i in ok[:2]]
t["why"] = [reasons(r, raw) for r, raw in zip(contrib, Xte.values)]

# Call list: the 10 invoices the model thinks are most likely to be late.
out["top_calls"] = t.sort_values("p", ascending=False).head(10)[["invoice_id", "customer_id", "customer_tier", "amount_eur", "p", "days_late", "outcome", "why"]].round(3).to_dict("records")

# ─────────────────────────────────────────────────────────────
# 9. WHAT THE SETTINGS CHANGE
# ─────────────────────────────────────────────────────────────
# (a) class_weight: same model with and without "balanced".
lr_plain = make_lr(class_weight=None).fit(Xtr, ytr)
pp = lr_plain.predict_proba(Xte)[:, 1]
out["lr_unweighted"] = score("Logistic Regression, no class_weight", (pp >= .5).astype(int), pp)

# (b) Regularization strength C (smaller C = stronger penalty = simpler model).
# Train vs test accuracy and recall at each C. If train keeps rising while test
# falls, the model is memorising; for 7 clues logistic regression barely does.
out["complexity"] = []
for C in [0.001, 0.01, 0.1, 1, 10, 100, 1000]:
    mc = make_lr(C=C).fit(Xtr, ytr)
    pc = mc.predict(Xte)
    out["complexity"].append(dict(C=C, train=float(mc.score(Xtr, ytr)), test=float(mc.score(Xte, yte)),
                                  recall=float(recall_score(yte, pc))))

# (c) Random split vs time split: same model, trained on the oldest 80% and tested on the newest 20%.
cut = int(len(df) * 0.8)
mt = make_lr().fit(df.iloc[:cut][X_cols], df.iloc[:cut]["late_flag"])
yt, pt = df.iloc[cut:]["late_flag"], mt.predict(df.iloc[cut:][X_cols])
out["time_split"] = dict(accuracy=float(accuracy_score(yt, pt)), recall=float(recall_score(yt, pt)),
                         precision=float(precision_score(yt, pt, zero_division=0)),
                         n_test=int(len(yt)), n_late=int(yt.sum()))

# ─────────────────────────────────────────────────────────────
# 10. THE COMPANY'S SITUATION: LATE MONEY ACROSS ALL 800 INVOICES
# ─────────────────────────────────────────────────────────────
# Not about the model: the size of the problem. Late money by customer (top 10)
# and its share of everything billed. Used by the late-money chart in the business reports.
L = df[df.late_flag == 1]
bycust = L.groupby(["customer_id", "customer_tier"]).amount_eur.agg(["sum", "size"]).reset_index().sort_values("sum", ascending=False)
out["company"] = dict(billed=float(df.amount_eur.sum()), late_eur=float(L.amount_eur.sum()),
                      n_invoices=int(len(df)), n_late=int(len(L)), n_late_customers=int(len(bycust)),
                      n_customers=int(df.customer_id.nunique()),
                      top=[dict(customer=r.customer_id, tier=r.customer_tier, eur=float(r["sum"]), n=int(r["size"]))
                           for _, r in bycust.head(10).iterrows()],
                      tier_eur={k: float(v) for k, v in L.groupby("customer_tier").amount_eur.sum().items()})

# ─────────────────────────────────────────────────────────────
# 11. SAVE RESULTS (read by make_charts.py) AND PRINT A SUMMARY
# ─────────────────────────────────────────────────────────────
json.dump(out, open(HERE / "results.json", "w"), indent=1)
for r in out["models"] + [out["lr_unweighted"]]:
    print({k: (round(v, 3) if isinstance(v, float) else v) for k, v in r.items()})
print(best, out["eur"], out["n_test"], out["test_late_rate"])
