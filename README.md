<img width="1280" height="400" alt="banner" src="https://github.com/user-attachments/assets/d9d62e14-7fae-4f4a-b802-ec35621334dc" />

#LATAM Lab

**Practical AI & Analytics for the businesses that run Latin America.**

> *AI adoption in Latin America continues to grow but maintains a narrative of careful hopefulness. Latin America’s AI adoption rate stands at 40 percent, trailing behind leading regions such as India (59 percent), the United Arab Emirates (58 percent), and Singapore (53 percent), (Hispanic Executive, May 2025).*
>
> *The biggest issue? --- access and stability* 
> 
> *So, the aim of the series is to learn how AI or/and analytics can answer business questions*

---

## The Question Behind Every Project

Each month starts with one question — the kind that can save money when we know the answer.

Not "how do we implement a machine learning pipeline."

**"Why did I waste $40,000 in inventory last December, and how do I make sure it doesn't happen again?"**

That question drives the analysis. The answer drives the decision. The decision drives the business forward.


---

## What This Is

**AI LATAM Lab** is a 12-month, a mostly free series building practical AI and analytics solutions applied to real Latin American business problems. Its about bring us to the present and maybe future is learn correctly. 

Every project follows the same structure:

- A business problem framed from the perspective of an SME owner
- A real or publicly available dataset or created
- A clean, reproducible implementation in Python or R (mostly)
- A business report written for the person making the decision — not the person writing the code
- A governance note: what can go wrong, and how to protect against it

---

## The Narrative — Autopsy vs. Early Warning

Most businesses operate in autopsy mode.

Something goes wrong. A team pulls data. A report lands on a desk three weeks later. A post-mortem happens. Everyone agrees it won't happen again.

Then it happens again.

Every project in this series is built around one shift: from **reactive** (what went wrong?) to **predictive** (what's about to go wrong, and what do we do before it does?).

The destination is agentic AI. The journey is learning how each building block works before connecting them all.

---

## Who This Is For

This series is designed for those willing to learn and make mistake along the way

---

Each monthly folder follows the same internal structure:

```
mXX-project-name/
├── README.md          # Business scenario · dataset · steps · report · governance
├── notebook.ipynb     # or analysis.R — fully documented, reproducible
├── outputs/
│   └── report.md      # Business report — written for the decision-maker

```
## Roadmap 

 :one: -> [Stop Feeding the Dumpster](https://github.com/Khalenanassers/LATAM-LAB/tree/5ff36a1ff6edfed9e4d232bb0f525b1c33722d0d/Month%20%231)
 
 :two: -> [Who is about to leave?](https://github.com/Khalenanassers/LATAM-LAB/blob/main/Month%20%232%20%20%E2%80%9C/README.md)
 
---

## Tech Stack

This series uses **free, open-source tools** — deliberately. The point is not to demonstrate what's possible with a six-figure software budget. The point is to show what's possible with the tools already available to most LATAM businesses.

**Languages:** Python 3.11+ · R 4.3+

**Python core:** `pandas` · `numpy` · `scikit-learn` · `xgboost` · `prophet` · `shap` · `matplotlib` · `seaborn` · `plotly`

**R core:** `tidyverse` · `tidymodels` · `ggplot2` · `plotly` · `prophet` · `kableExtra`

**Visualization standard:** All charts use a pre build pallete and design standart.

---

## Design Philosophy

### On governance

Governance is not a chapter at the end of the series. It is a thread running through every project.

Every notebook includes a section called **"What Could Go Wrong"** — not as a disclaimer, but as a genuine design question. Who does this model affect? What happens if the data is biased? Who should sign off before this goes to production?

### On data

Most real business data is unavailable to the public for good reasons. This series uses one of two strategies:

**Real public datasets** — sourced from Kaggle, UCI, official statistical agencies, and open government portals. Cited in every project.

**Calibrated synthetic data** — when the specific scenario requires data that doesn't exist publicly (e.g., a company's internal cash flow), synthetic data is generated and calibrated against credible benchmarks (FAO, IDB, ECLAC). The calibration methodology is always documented.


### On accessibility

Every project is documented in **English**. But, the business report are always in Spanish and English so everybody can use it. 
---


## Connect

**LinkedIn:** [linkedin.com/in/khalenanassers](https://linkedin.com/in/khalenanassers)
**Website:** [khalenanasser.com](https://khalenanasser.figma.site/)
**GitHub:** You're already here.

Questions, feedback, or a business problem you'd like to see in a future month — open an issue or send a message.

---

*AI LATAM Lab · 2026 · Built in Hamburg, thinking in LATAM.*
