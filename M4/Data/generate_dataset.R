# M4 Collections and Late Payment Intelligence — synthetic VIVA dataset generator
# Spec source: Projects/LATAM Lab/M04 Collections.md
# Window Dec 2009-Nov 2011, 60 customers, 800 invoices, ~19M EUR total,
# Pareto-weighted customer concentration, log-normal amounts, tiered days-late.

# Seed chosen via search (see seed_search.R): lands at late rate 20.75%
# (spec target 20.8%) and 1 zero-invoice customer (matches spec's validated
# Python run), avoiding pathological single-anchor draws from the
# infinite-variance Pareto(1.5) concentration weights.
set.seed(396)

n_customers <- 60
n_invoices  <- 800
target_total_eur <- 19000000

# --- Customers: risk tiers ---
tier_probs <- c(Reliable = 0.50, Moderate = 0.30, Chronic = 0.20)
customer_ids <- sprintf("CUST-%03d", 1:n_customers)
customer_tier <- sample(names(tier_probs), n_customers, replace = TRUE, prob = tier_probs)

# --- Customers: Pareto-weighted invoice count concentration ---
# np.random.pareto(1.5) equivalent: (1/U^(1/1.5) - 1), U ~ Uniform(0,1)
u <- runif(n_customers)
pareto_raw <- (1 / u^(1/1.5)) - 1 + 0.5
weights <- pareto_raw / sum(pareto_raw)

invoice_customer_idx <- sample(1:n_customers, n_invoices, replace = TRUE, prob = weights)

# --- Invoice dates: uniform across 24-month window ---
window_start <- as.Date("2009-12-01")
window_end   <- as.Date("2011-11-30")
window_days  <- as.integer(window_end - window_start)
invoice_date <- window_start + sample(0:window_days, n_invoices, replace = TRUE)

# --- Invoice amounts: log-normal, mu=log(17000), sigma=0.9, rescaled to target total ---
amount_raw <- rlnorm(n_invoices, meanlog = log(17000), sdlog = 0.9)
amount_eur <- amount_raw * (target_total_eur / sum(amount_raw))

# --- Days late: per invoice, drawn from customer's tier distribution ---
tier_params <- list(
  Reliable = c(mean = -2, sd = 8),
  Moderate = c(mean = 15, sd = 20),
  Chronic  = c(mean = 45, sd = 35)
)

invoice_tier <- customer_tier[invoice_customer_idx]
days_late <- mapply(function(t) {
  p <- tier_params[[t]]
  rnorm(1, mean = p["mean"], sd = p["sd"])
}, invoice_tier)
days_late <- round(days_late)

late_flag <- as.integer(days_late > 30)

df <- data.frame(
  invoice_id    = sprintf("INV-%05d", 1:n_invoices),
  customer_id   = customer_ids[invoice_customer_idx],
  customer_tier = invoice_tier,
  invoice_date  = invoice_date,
  amount_eur    = round(amount_eur, 2),
  days_late     = days_late,
  late_flag     = late_flag
)

# Report which customers (if any) drew zero invoices — open decision item
zero_invoice_customers <- customer_ids[!(1:n_customers %in% unique(invoice_customer_idx))]
if (length(zero_invoice_customers) > 0) {
  cat("Customers with 0 invoices (open decision: drop vs keep as inactive/churned):\n")
  print(zero_invoice_customers)
} else {
  cat("No customers with 0 invoices in this run.\n")
}

# --- Sanity checks against spec ---
cat("\n--- Validation ---\n")
cat("Total invoiced (EUR):", format(sum(df$amount_eur), big.mark = ","), "\n")
cat("Median amount (EUR):", median(df$amount_eur), "\n")
cat("Mean amount (EUR):", round(mean(df$amount_eur), 1), "\n")
cat("Late (>30d) rate:", round(mean(df$late_flag) * 100, 1), "%\n")
cat("Tier distribution:\n")
print(table(customer_tier))

# --- Write outputs ---
write.csv(df, file.path(getwd(), "viva_invoices.csv"), row.names = FALSE)

customers_df <- data.frame(
  customer_id = customer_ids,
  customer_tier = customer_tier,
  invoice_count = as.integer(table(factor(invoice_customer_idx, levels = 1:n_customers)))
)
write.csv(customers_df, file.path(getwd(), "viva_customers.csv"), row.names = FALSE)

cat("\nWrote viva_invoices.csv (", n_invoices, "rows) and viva_customers.csv (", n_customers, "rows) to", getwd(), "\n")
