"""
Saves the report charts (English and Spanish) from Models/results.json:
  late_money_by_customer[_es].png   late money by customer (the size of the problem)
  model_clue_weights[_es].png       which clues push an invoice toward "late" (the model's reasoning)
Run after Models/run_models.py:  python "Business Report/make_charts.py"
"""
import json, pathlib
import matplotlib.pyplot as plt

# M4 brand palette (dark theme).
BG, CARD, INK, INK2, LINE = "#080D12", "#0D141B", "#F0F4F8", "#A0AAB8", "#1A2530"
TEAL, AMBER, GOOD, BAD = "#00F0C0", "#FFB800", "#41A964", "#E26B6B"
plt.rcParams.update({"font.family": ["Segoe UI", "DejaVu Sans"], "figure.facecolor": BG, "savefig.facecolor": BG,
                     "axes.facecolor": CARD, "axes.edgecolor": LINE, "axes.labelcolor": INK2, "text.color": INK,
                     "xtick.color": INK2, "ytick.color": INK, "axes.grid": True, "grid.color": LINE, "axes.axisbelow": True})

here = pathlib.Path(__file__).resolve().parent
R = json.loads((here.parent / "Models" / "results.json").read_text(encoding="utf8"))
K, LR = R["company"], R["lr"]

T = {
 "en": dict(suf="", sep=",", title1="5 customers hold {pct:.0%} of the €{m:.2f}M VIVA was paid late",
            xl1="Late money (€ thousands, invoices paid more than 30 days late)", inv="late invoices",
            chronic="Chronic late payer", mod="Sometimes-late customer",
            foot1="All {n} invoices, €{b:.1f}M billed. Late = paid more than 30 days after the due date. Practice dataset.",
            title2="The model mostly reads the customer's risk tier",
            xl2="Weight of each clue (log-odds). Right = pushes toward “late”, left = toward “paid on time”",
            toward_late="Toward late", toward_ok="Toward on time", odds="odds ×",
            foot2="Logistic regression, clues standardized. Odds ratio = how much one step up multiplies the odds of “late”.",
            labels={"log_amt": "Invoice size (log euros)", "month": "Month issued", "prior_n": "Invoices the customer had before",
                    "prior_late_rate": "Customer's past late rate", "tier_Reliable": "Customer is a Reliable payer",
                    "tier_Moderate": "Customer is a Sometimes-late payer", "tier_Chronic": "Customer is a Chronic late payer"}),
 "es": dict(suf="_es", sep=".", title1="5 clientes concentran el {pct:.0%} de los €{m:.2f} M que VIVA cobró tarde",
            xl1="Dinero cobrado tarde (miles de €, facturas pagadas con más de 30 días de retraso)", inv="facturas tardías",
            chronic="Pagador tardío crónico", mod="Cliente a veces tardío",
            foot1="Las {n} facturas, €{b:.1f} M facturados. Tarde = pagada más de 30 días después del vencimiento. Datos de práctica.",
            title2="El modelo lee sobre todo el nivel de riesgo del cliente",
            xl2="Peso de cada pista (log-odds). Derecha = empuja a «tarde», izquierda = a «paga a tiempo»",
            toward_late="Hacia tarde", toward_ok="Hacia a tiempo", odds="odds ×",
            foot2="Regresión logística, pistas estandarizadas. Odds ratio = cuánto multiplica las probabilidades de «tarde» un paso hacia arriba.",
            labels={"log_amt": "Tamaño de la factura (log euros)", "month": "Mes de emisión", "prior_n": "Facturas previas del cliente",
                    "prior_late_rate": "Tasa histórica de atraso del cliente", "tier_Reliable": "Cliente es pagador Confiable",
                    "tier_Moderate": "Cliente es pagador A veces tardío", "tier_Chronic": "Cliente es pagador Tardío crónico"}),
}

for lang, t in T.items():
    # Chart 1: late money by customer
    top = K["top"][::-1]
    col = {"Chronic": BAD, "Moderate": AMBER}
    top5 = sum(c["eur"] for c in K["top"][:5])
    fig, ax = plt.subplots(figsize=(10, 6))
    bars = ax.barh([c["customer"] for c in top], [c["eur"] / 1e3 for c in top], color=[col[c["tier"]] for c in top])
    for b, c in zip(bars, top):
        ax.text(b.get_width() + 8, b.get_y() + b.get_height() / 2, f"€{c['eur']/1e3:,.0f}k  ({c['n']} {t['inv']})", va="center", fontsize=9, color=INK)
    ax.set_title(t["title1"].format(pct=top5 / K["late_eur"], m=K["late_eur"] / 1e6), fontsize=14, fontweight="bold", loc="left")
    ax.set_xlabel(t["xl1"], fontsize=11)
    ax.set_xlim(0, max(c["eur"] for c in top) / 1e3 * 1.4)
    ax.spines[["top", "right"]].set_visible(False); ax.grid(axis="y", visible=False)
    ax.legend(handles=[plt.Rectangle((0, 0), 1, 1, color=col["Chronic"]), plt.Rectangle((0, 0), 1, 1, color=col["Moderate"])],
              labels=[t["chronic"], t["mod"]], loc="lower right", frameon=False, labelcolor=INK2)
    fig.text(0.01, -0.01, t["foot1"].format(n=K["n_invoices"], b=K["billed"] / 1e6), fontsize=8, color=INK2)
    plt.tight_layout(); plt.savefig(here / f"late_money_by_customer{t['suf']}.png", dpi=150, bbox_inches="tight"); plt.close()

    # Chart 2: clue weights of the logistic regression
    cs = sorted(LR["coefs"], key=lambda c: c["coef"])
    fig, ax = plt.subplots(figsize=(10, 5.2))
    ax.barh([t["labels"][c["feature"]] for c in cs], [c["coef"] for c in cs], color=[BAD if c["coef"] > 0 else GOOD for c in cs])
    for i, c in enumerate(cs):
        ax.text(c["coef"] + (0.05 if c["coef"] > 0 else -0.05), i, f"{t['odds']}{c['odds_ratio']:.2f}", va="center", ha="left" if c["coef"] > 0 else "right", fontsize=9, color=INK)
    ax.axvline(0, color=INK, lw=1.2)
    ax.set_xlim(-2.5, 2.3)
    ax.set_ylim(-1.3, len(cs) - 0.4)
    ax.set_title(t["title2"], fontsize=14, fontweight="bold", loc="left")
    ax.set_xlabel(t["xl2"], fontsize=10)
    ax.spines[["top", "right"]].set_visible(False); ax.grid(axis="y", visible=False)
    ax.text(2.25, -1.05, t["toward_late"] + " →", ha="right", fontsize=9, color=BAD)
    ax.text(-2.45, -1.05, "← " + t["toward_ok"], ha="left", fontsize=9, color=GOOD)
    fig.text(0.01, -0.01, t["foot2"], fontsize=8, color=INK2)
    plt.tight_layout(); plt.savefig(here / f"model_clue_weights{t['suf']}.png", dpi=150, bbox_inches="tight"); plt.close()
print("ok")
