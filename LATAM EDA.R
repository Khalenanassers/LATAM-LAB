# ============================================================
# latam_eda.R -- Reusable EDA Toolkit | LATAM Analytics Series
# ============================================================
# Usage (from any R Markdown notebook or script):
#
#   source("latam_eda.R")
#   eda <- run_eda()
#
# All charts print to the R Plots pane AND save to eda_output/
# Returns a named list -- eda$churn_rate, eda$hypothesis_table, etc.
# ============================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(ggcorrplot)
  library(moments)
  library(knitr)
  library(vcd)
  library(scales)
  library(patchwork)
  library(readr)
})

# -- Palette ------------------------------------------------------------------
.TEAL  <- "#008866"
.AMBER <- "#FFB800"
.RED   <- "#C94F4F"
.DARK  <- "#374151"
.GRID  <- "#E5E7EB"
.BG    <- "#FFFFFF"

# -- Base theme ----------------------------------------------------------------
.base_theme <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.background  = element_rect(fill = .BG, color = NA),
      panel.background = element_rect(fill = .BG, color = NA),
      plot.title       = element_text(face = "bold", size = 13, color = .DARK),
      plot.subtitle    = element_text(size = 10, color = "#555555"),
      plot.caption     = element_text(size = 8, color = "#888888", hjust = 1),
      axis.title       = element_text(size = 10, color = .DARK),
      axis.text        = element_text(size = 8,  color = .DARK),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = .GRID),
      legend.position  = "bottom",
      legend.title     = element_blank()
    )
}


# # ===============================================================
# # HELPERS                                                                   
# # ===============================================================

.detect_types <- function(df) {
  num <- names(df)[sapply(df, is.numeric)]
  cat <- names(df)[sapply(df, function(x) is.character(x) || is.factor(x) || is.logical(x))]
  list(numerical = num, categorical = cat)
}

.positive_class <- function(x) {
  vals <- unique(as.character(x[!is.na(x)]))
  if ("Yes"  %in% vals) return("Yes")
  if ("1"    %in% vals) return("1")
  if ("TRUE" %in% vals) return("TRUE")
  tbl <- table(as.character(x))
  names(tbl)[which.min(tbl)]
}

.save_plot <- function(p, filename, output_dir, width = 10, height = 6, dpi = 150) {
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  path <- file.path(output_dir, filename)
  ggplot2::ggsave(path, plot = p, width = width, height = height,
                  dpi = dpi, bg = "white")
}


# # ===============================================================
# # Block 1 * Descriptive Statistics (Location & Spread)                      
# # ===============================================================

.block1_descriptive <- function(df, types) {
  cat("\n[ Block 1 ] Descriptive statistics...\n")

  # -- Numerical -------------------------------------------------------------
  num_stats <- do.call(rbind, lapply(types$numerical, function(col) {
    x <- df[[col]][!is.na(df[[col]])]
    if (length(x) == 0) return(NULL)
    sk <- round(moments::skewness(x), 3)
    data.frame(
      column   = col,
      n        = length(x),
      mean     = round(mean(x), 3),
      median   = round(median(x), 3),
      sd       = round(sd(x), 3),
      min      = round(min(x), 3),
      max      = round(max(x), 3),
      IQR      = round(IQR(x), 3),
      skewness = sk,
      kurtosis = round(moments::kurtosis(x), 3),
      flag     = ifelse(abs(sk) > 1.5, "[!] skewed", ""),
      stringsAsFactors = FALSE
    )
  }))

  cat("\n-- Numerical Summary -----------------------------------------\n")
  if (!is.null(num_stats) && nrow(num_stats) > 0)
    print(knitr::kable(num_stats, format = "simple"))

  # -- Categorical -----------------------------------------------------------
  cat_stats <- do.call(rbind, lapply(types$categorical, function(col) {
    x       <- as.character(df[[col]])
    x_valid <- x[!is.na(x)]
    if (length(x_valid) == 0) return(NULL)
    counts   <- table(x_valid)
    mode_val <- names(counts)[which.max(counts)]
    data.frame(
      column      = col,
      n           = length(x_valid),
      n_unique    = length(unique(x_valid)),
      mode        = mode_val,
      mode_pct    = round(max(counts) / length(x_valid) * 100, 1),
      missing_pct = round(sum(is.na(df[[col]])) / nrow(df) * 100, 1),
      stringsAsFactors = FALSE
    )
  }))

  cat("\n-- Categorical Summary ---------------------------------------\n")
  if (!is.null(cat_stats) && nrow(cat_stats) > 0)
    print(knitr::kable(cat_stats, format = "simple"))

  list(numerical_stats = num_stats, categorical_stats = cat_stats)
}


# # ===============================================================
# # Block 2 * Numerical vs Categorical Split                                  
# # ===============================================================

.block2_split <- function(df, types) {
  cat("\n[ Block 2 ] Numerical vs categorical split...\n")
  cat(sprintf("  %d numerical | %d categorical\n",
              length(types$numerical), length(types$categorical)))

  if (length(types$numerical)   > 0)
    cat("  Numerical  :", paste(types$numerical,   collapse = ", "), "\n")
  if (length(types$categorical) > 0)
    cat("  Categorical:", paste(types$categorical, collapse = ", "), "\n")

  possibly_cat <- Filter(function(col) {
    n_uniq <- length(unique(df[[col]][!is.na(df[[col]])]))
    if (n_uniq < 10L) {
      cat(sprintf("  [!] '%s' has only %d unique values -- possibly categorical\n",
                  col, n_uniq))
      TRUE
    } else FALSE
  }, types$numerical)

  list(possibly_categorical = if (length(possibly_cat) > 0) possibly_cat else NULL)
}


# # ===============================================================
# # Block 3 * Numerical Correlations                                          
# # ===============================================================

.block3_correlations <- function(df, types, dataset_name, output_dir) {
  cat("\n[ Block 3 ] Numerical correlations...\n")

  num_df <- df[, types$numerical, drop = FALSE]
  num_df <- num_df[, sapply(num_df, function(x) {
    x2 <- x[!is.na(x)]; length(x2) > 1 && length(unique(x2)) > 1
  }), drop = FALSE]

  if (ncol(num_df) < 2L) {
    cat("  Not enough valid numerical columns for correlation.\n")
    return(list(high_correlations = data.frame(), plot = NULL))
  }

  cor_mat <- stats::cor(num_df, use = "pairwise.complete.obs", method = "pearson")

  # High-correlation pairs
  pairs_idx <- which(lower.tri(cor_mat), arr.ind = TRUE)
  high_corr <- do.call(rbind, Filter(Negate(is.null), lapply(seq_len(nrow(pairs_idx)), function(i) {
    r_val <- cor_mat[pairs_idx[i, 1], pairs_idx[i, 2]]
    if (!is.na(r_val) && abs(r_val) > 0.7)
      data.frame(col1 = rownames(cor_mat)[pairs_idx[i, 1]],
                 col2 = colnames(cor_mat)[pairs_idx[i, 2]],
                 r    = round(r_val, 3), stringsAsFactors = FALSE)
  })))
  if (is.null(high_corr)) high_corr <- data.frame()

  title_str <- if (nrow(high_corr) > 0) {
    top <- high_corr[which.max(abs(high_corr$r)), ]
    sprintf("'%s' & '%s' share the strongest relationship (r = %.2f)",
            top$col1, top$col2, top$r)
  } else "No strong pairwise correlations detected (|r| < 0.7)"

  p <- ggcorrplot::ggcorrplot(
    cor_mat, type = "lower", lab = TRUE, lab_size = 3,
    colors        = c(.AMBER, "white", .TEAL),
    outline.color = "white",
    ggtheme       = theme_minimal()
  ) +
    labs(title    = title_str,
         subtitle = "Pearson Correlation -- Numerical Features",
         caption  = paste0("Source: ", dataset_name)) +
    .base_theme()

  print(p)
  .save_plot(p, "correlation_heatmap.png", output_dir)
  cat("  Saved: correlation_heatmap.png\n")

  if (nrow(high_corr) > 0) {
    cat("  High correlations (|r| > 0.7):\n")
    print(knitr::kable(high_corr, format = "simple"))
  }

  list(high_correlations = high_corr, plot = p)
}


# # ===============================================================
# # Block 4 * Categorical Correlations (Cramer's V)                           
# # ===============================================================

.block4_cat_correlations <- function(df, target_var, types, dataset_name, output_dir) {
  cat("\n[ Block 4 ] Categorical correlations (Cramer's V)...\n")

  .cramers_v <- function(x, y) {
    tbl  <- table(x, y)
    chi2 <- suppressWarnings(chisq.test(tbl, correct = FALSE)$statistic)
    n    <- sum(tbl); phi2 <- chi2 / n
    sqrt(phi2 / min(nrow(tbl) - 1, ncol(tbl) - 1))
  }

  cat_cols <- setdiff(types$categorical, target_var)
  if (length(cat_cols) == 0L) {
    cat("  No categorical columns available.\n")
    return(list(cramers_v = data.frame(), significant_assoc = data.frame(), plot = NULL))
  }

  target_vec <- df[[target_var]]

  cv_df <- do.call(rbind, lapply(cat_cols, function(col) {
    cv <- tryCatch(.cramers_v(df[[col]], target_vec), error = function(e) NA_real_)
    pv <- tryCatch(suppressWarnings(chisq.test(table(df[[col]], target_vec),
                                               correct = FALSE)$p.value),
                   error = function(e) NA_real_)
    data.frame(variable = col, cramers_v = round(cv, 3),
               p_value = round(pv, 4), stringsAsFactors = FALSE)
  }))
  cv_df <- cv_df[order(-cv_df$cramers_v, na.last = TRUE), ]

  sig_assoc <- cv_df[!is.na(cv_df$p_value) & cv_df$p_value < 0.05,
                     c("variable", "p_value"), drop = FALSE]

  cat("\n-- Cramer's V by variable -----------------------------------\n")
  print(knitr::kable(cv_df, format = "simple"))

  cv_plot   <- cv_df[!is.na(cv_df$cramers_v), ]
  top_var   <- cv_plot$variable[1]
  title_str <- sprintf("'%s' is the strongest categorical predictor of %s", top_var, target_var)

  p <- ggplot(cv_plot, aes(x = cramers_v, y = reorder(variable, cramers_v))) +
    geom_col(fill = .TEAL, width = 0.65) +
    geom_vline(xintercept = 0.1, linetype = "dashed", color = .AMBER, linewidth = 0.8) +
    geom_vline(xintercept = 0.3, linetype = "dashed", color = .RED,   linewidth = 0.8) +
    annotate("text", x = 0.1, y = Inf, label = "weak",
             hjust = -0.15, vjust = 1.8, size = 3, color = .AMBER) +
    annotate("text", x = 0.3, y = Inf, label = "moderate",
             hjust = -0.1,  vjust = 1.8, size = 3, color = .RED) +
    scale_x_continuous(expand = expansion(mult = c(0, 0.05))) +
    labs(title   = title_str,
         subtitle = "Cramer's V -- Categorical Association with Target",
         x       = "Cramer's V",
         y       = NULL,
         caption = paste0("Source: ", dataset_name)) +
    .base_theme()

  print(p)
  .save_plot(p, "cramers_v_chart.png", output_dir)
  cat("  Saved: cramers_v_chart.png\n")

  list(cramers_v = cv_df, significant_assoc = sig_assoc, plot = p)
}


# # ===============================================================
# # Block 5 * Distributions & Box Plots                                       
# # ===============================================================

.block5_distributions <- function(df, target_var, types, dataset_name, output_dir) {
  cat("\n[ Block 5 ] Distributions and box plots...\n")

  target_vec    <- as.character(df[[target_var]])
  target_levels <- unique(target_vec[!is.na(target_vec)])
  pal_2         <- setNames(c(.TEAL, .AMBER), target_levels[1:min(2, length(target_levels))])
  disc_vars     <- character(0)
  num_cols      <- setdiff(types$numerical, target_var)

  for (col in num_cols) {
    x <- df[[col]]
    if (all(is.na(x))) next

    plot_df <- data.frame(value  = x,
                          target = target_vec,
                          stringsAsFactors = FALSE)
    plot_df <- plot_df[!is.na(plot_df$value) & !is.na(plot_df$target), ]
    if (nrow(plot_df) == 0) next

    # Check discriminating power
    grps <- split(plot_df$value, plot_df$target)
    if (length(grps) >= 2) {
      meds       <- sapply(grps, median)
      pooled_iqr <- IQR(plot_df$value)
      if (!is.na(pooled_iqr) && pooled_iqr > 0 &&
          abs(diff(range(meds))) / pooled_iqr > 0.3)
        disc_vars <- c(disc_vars, col)
    }

    # Histogram + KDE
    p_hist <- ggplot(plot_df, aes(x = value, fill = target, color = target)) +
      geom_histogram(aes(y = after_stat(density)), alpha = 0.45,
                     position = "identity", bins = 30, linewidth = 0) +
      geom_density(alpha = 0, linewidth = 0.9) +
      scale_fill_manual(values  = pal_2) +
      scale_color_manual(values = pal_2) +
      labs(title   = sprintf("Distribution of %s", col),
           x       = col, y = "Density",
           caption = paste0("Source: ", dataset_name)) +
      .base_theme()

    # Box plot
    p_box <- ggplot(plot_df, aes(x = target, y = value, fill = target)) +
      geom_boxplot(alpha = 0.7, outlier.size = 1.2, outlier.alpha = 0.4,
                   linewidth = 0.5) +
      scale_fill_manual(values = pal_2) +
      labs(title   = sprintf("%s by %s", col, target_var),
           x       = target_var, y = col,
           caption = paste0("Source: ", dataset_name)) +
      .base_theme() +
      theme(legend.position = "none")

    p_combined <- p_hist + p_box +
      plot_layout(ncol = 2) +
      plot_annotation(
        title   = sprintf("%s distribution by %s", col, target_var),
        caption = paste0("Source: ", dataset_name),
        theme   = theme(plot.title = element_text(face = "bold", size = 13, color = .DARK))
      )

    print(p_combined)
    .save_plot(p_combined, paste0("dist_", col, ".png"), output_dir,
               width = 12, height = 5)
    cat(sprintf("  Saved: dist_%s.png\n", col))
  }

  if (length(disc_vars) > 0)
    cat(sprintf("  Discriminating variables: %s\n", paste(disc_vars, collapse = ", ")))
  else
    cat("  No strongly discriminating numerical variables found.\n")

  list(discriminating_vars = disc_vars)
}


# # ===============================================================
# # Block 6 * Hypothesis Testing Recommendations                              
# # ===============================================================

.block6_hypothesis <- function(df, target_var, types, b1, b5, b4) {
  cat("\n[ Block 6 ] Hypothesis testing recommendations...\n")

  num_stats <- b1$numerical_stats
  disc_vars <- b5$discriminating_vars
  cv_df     <- b4$cramers_v
  n_target  <- length(unique(df[[target_var]][!is.na(df[[target_var]])]))
  rows      <- list()

  for (col in setdiff(types$numerical, target_var)) {
    sk <- if (!is.null(num_stats) && nrow(num_stats) > 0) {
      r <- num_stats[num_stats$column == col, "skewness"]
      if (length(r) > 0 && !is.na(r[1])) r[1] else 0
    } else 0

    priority <- if (col %in% disc_vars) "High" else "Medium"

    if (n_target == 2L) {
      if (abs(sk) < 1) {
        test   <- "Independent t-test"
        reason <- "Numerical, near-normal (|skew| < 1), two groups."
      } else {
        test   <- "Mann-Whitney U"
        reason <- "Skewed numerical; non-parametric test preferred."
      }
    } else {
      if (abs(sk) < 1) {
        test   <- "One-way ANOVA"
        reason <- "Numerical, near-normal, 3+ groups."
      } else {
        test   <- "Kruskal-Wallis"
        reason <- "Skewed numerical; non-parametric ANOVA equivalent."
      }
    }
    rows[[length(rows) + 1]] <- data.frame(variable = col, test = test,
                                           reason = reason, priority = priority,
                                           stringsAsFactors = FALSE)
  }

  for (col in setdiff(types$categorical, target_var)) {
    tbl      <- table(df[[col]], df[[target_var]])
    expected <- tryCatch(suppressWarnings(chisq.test(tbl)$expected),
                         error = function(e) matrix(5, 1, 1))
    use_fisher <- any(expected < 5, na.rm = TRUE)

    test   <- if (use_fisher) "Fisher's Exact Test" else "Chi-squared test"
    reason <- if (use_fisher)
      "Categorical vs categorical; expected cell < 5."
    else
      "Categorical vs categorical; expected cells >= 5."

    cv_val <- if (!is.null(cv_df) && nrow(cv_df) > 0) {
      r <- cv_df[cv_df$variable == col, "cramers_v"]
      if (length(r) > 0 && !is.na(r[1])) r[1] else NA_real_
    } else NA_real_

    priority <- if (!is.na(cv_val) && cv_val >= 0.3) "High"
    else if (!is.na(cv_val) && cv_val >= 0.1) "Medium" else "Low"

    rows[[length(rows) + 1]] <- data.frame(variable = col, test = test,
                                           reason = reason, priority = priority,
                                           stringsAsFactors = FALSE)
  }

  if (length(rows) == 0L) {
    cat("  No variables available.\n")
    return(list(hypothesis_table = data.frame()))
  }

  hyp_df <- do.call(rbind, rows)
  hyp_df <- hyp_df[order(match(hyp_df$priority, c("High", "Medium", "Low"))), ]

  cat("\n-- Hypothesis Testing Recommendations ----------------------\n")
  print(knitr::kable(hyp_df, format = "simple"))

  list(hypothesis_table = hyp_df)
}


# # ===============================================================
# # Block 7 * Data Cleaning Recommendations & Warnings                        
# # ===============================================================

.block7_cleaning <- function(df, target_var, output_dir) {
  cat("\n[ Block 7 ] Data cleaning recommendations...\n")

  n_rows   <- nrow(df)
  warnings <- list()
  lines    <- character(0)

  .log <- function(...) {
    ln <- paste0(...); cat(ln, "\n"); lines <<- c(lines, ln)
  }

  .log("============================================================")
  .log("  EDA DATA QUALITY REPORT")
  .log("============================================================")
  .log("")

  # 1. Missing values
  .log("-- 1. Missing Values ------------------------------------------")
  miss_pct  <- sapply(df, function(x) sum(is.na(x)) / n_rows * 100)
  crit_miss <- names(miss_pct[miss_pct == 100])
  high_miss <- names(miss_pct[miss_pct > 5 & miss_pct < 100])

  for (col in crit_miss) .log(sprintf("  [!!] CRITICAL: '%s' -- 100%% missing. Drop candidate.", col))
  for (col in high_miss) {
    strategy <- if (is.numeric(df[[col]])) "median imputation or MICE"
    else "mode imputation or 'Unknown' level"
    .log(sprintf("  [!]  '%s' -- %.1f%% missing. Suggested: %s.", col, miss_pct[col], strategy))
  }
  if (length(crit_miss) == 0 && length(high_miss) == 0)
    .log("  [OK] No columns exceed 5% missing values.")

  warnings$critical_missing <- if (length(crit_miss) > 0) crit_miss else NULL
  warnings$high_missing     <- if (length(high_miss) > 0) high_miss else NULL

  # 2. Outliers
  .log(""); .log("-- 2. Outliers (IQR method) -----------------------------------")
  num_cols  <- names(df)[sapply(df, is.numeric)]
  out_flags <- character(0)
  for (col in num_cols) {
    x <- df[[col]][!is.na(df[[col]])]
    Q1 <- quantile(x, 0.25); Q3 <- quantile(x, 0.75); IQR_v <- Q3 - Q1
    n_out <- sum(x < Q1 - 1.5 * IQR_v | x > Q3 + 1.5 * IQR_v)
    out_pct <- n_out / length(x) * 100
    if (out_pct > 5) {
      out_flags <- c(out_flags, col)
      .log(sprintf("  [!]  '%s' -- %.1f%% outliers detected.", col, out_pct))
    }
  }
  if (length(out_flags) == 0) .log("  [OK] No columns exceed 5% outlier rate.")
  warnings$high_outliers <- if (length(out_flags) > 0) out_flags else NULL

  # 3. Class imbalance
  .log(""); .log("-- 3. Class Imbalance -----------------------------------------")
  if (!is.null(target_var) && nzchar(target_var) && target_var %in% names(df)) {
    target_tbl <- table(df[[target_var]])
    target_pct <- prop.table(target_tbl) * 100
    min_pct    <- min(target_pct)
    .log(sprintf("  Target '%s' distribution:", target_var))
    for (nm in names(target_tbl))
      .log(sprintf("    %-30s  %6d  (%.1f%%)", nm, target_tbl[nm], target_pct[nm]))
    if (min_pct < 20) {
      .log(sprintf("  [!!] CRITICAL: Minority class %.1f%% < 20%%. Consider SMOTE or class weighting.", min_pct))
      warnings$class_imbalance <- TRUE
    } else .log("  [OK] Class distribution is reasonably balanced.")
  } else {
    .log("  [!]  No target variable -- class imbalance check skipped.")
  }

  # 4. Near-zero variance
  .log(""); .log("-- 4. Near-Zero Variance --------------------------------------")
  nzv_cols <- character(0)
  for (col in names(df)) {
    x <- df[[col]][!is.na(df[[col]])]
    if (length(x) == 0) next
    if (max(table(x)) / length(x) > 0.95) {
      nzv_cols <- c(nzv_cols, col)
      .log(sprintf("  [!]  '%s' -- %.1f%% of values are the same.", col,
                   max(table(x)) / length(x) * 100))
    }
  }
  if (length(nzv_cols) == 0) .log("  [OK] No near-zero variance columns detected.")
  warnings$near_zero_variance <- if (length(nzv_cols) > 0) nzv_cols else NULL

  # 5. Duplicates
  .log(""); .log("-- 5. Duplicate Rows ------------------------------------------")
  n_dups <- sum(duplicated(df))
  if (n_dups > 0) {
    .log(sprintf("  [!]  %d duplicate rows (%.2f%%).", n_dups, n_dups / n_rows * 100))
    warnings$duplicate_rows <- n_dups
  } else .log("  [OK] No duplicate rows detected.")

  # 6. Encoding needed
  .log(""); .log("-- 6. Encoding Needed -----------------------------------------")
  chr_cols <- names(df)[sapply(df, is.character)]
  if (length(chr_cols) > 0) {
    .log(sprintf("  [!]  Un-factored character columns: %s", paste(chr_cols, collapse = ", ")))
    warnings$encoding_needed <- chr_cols
  } else .log("  [OK] No raw character columns.")

  # 7. High cardinality
  .log(""); .log("-- 7. High Cardinality ----------------------------------------")
  cat_cols <- names(df)[sapply(df, function(x) is.character(x) || is.factor(x))]
  hi_card  <- character(0)
  for (col in cat_cols) {
    n_u <- length(unique(df[[col]][!is.na(df[[col]])]))
    if (n_u > 20) {
      hi_card <- c(hi_card, col)
      .log(sprintf("  [!]  '%s' -- %d unique values (high cardinality).", col, n_u))
    }
  }
  if (length(hi_card) == 0) .log("  [OK] No high-cardinality columns.")
  warnings$high_cardinality <- if (length(hi_card) > 0) hi_card else NULL

  .log(""); .log("============================================================")

  writeLines(lines, file.path(output_dir, "eda_warnings.txt"))
  cat("  Saved: eda_warnings.txt\n")

  list(warnings = warnings)
}


# # ===============================================================
# # Block 7a * Missing & NA Analysis (Rows + Columns)                         
# # ===============================================================

.block7a_missing <- function(df, dataset_name, output_dir) {
  cat("\n[ Block 7a ] Missing value analysis...\n")

  n_rows <- nrow(df)
  n_cols <- ncol(df)

  # -- By column -------------------------------------------------------------
  miss_col <- data.frame(
    column      = names(df),
    n_missing   = sapply(df, function(x) sum(is.na(x))),
    pct_missing = sapply(df, function(x) round(sum(is.na(x)) / n_rows * 100, 2)),
    stringsAsFactors = FALSE
  )
  miss_col$severity <- dplyr::case_when(
    miss_col$pct_missing == 0                              ~ "none",
    miss_col$pct_missing <  5                              ~ "low",
    miss_col$pct_missing >= 5 & miss_col$pct_missing <= 20 ~ "moderate",
    TRUE                                                   ~ "high"
  )

  all_miss <- miss_col$column[miss_col$pct_missing == 100]
  if (length(all_miss) > 0)
    cat(sprintf("  [!!] CRITICAL: %s -- 100%% missing.\n", paste(all_miss, collapse = ", ")))

  miss_col_plot <- miss_col[miss_col$n_missing > 0, ]

  if (nrow(miss_col_plot) > 0) {
    sev_pal   <- c(low = .TEAL, moderate = .AMBER, high = .RED)
    title_str <- sprintf("%d column(s) contain missing values", nrow(miss_col_plot))

    p_col <- ggplot(miss_col_plot,
                    aes(x = pct_missing, y = reorder(column, pct_missing),
                        fill = severity)) +
      geom_col(width = 0.65) +
      geom_vline(xintercept = 5,  linetype = "dashed", color = .AMBER, linewidth = 0.8) +
      geom_vline(xintercept = 20, linetype = "dashed", color = .RED,   linewidth = 0.8) +
      annotate("text", x = 5,  y = Inf, label = "5%",
               hjust = -0.2, vjust = 1.8, size = 3, color = .AMBER) +
      annotate("text", x = 20, y = Inf, label = "20%",
               hjust = -0.2, vjust = 1.8, size = 3, color = .RED) +
      scale_fill_manual(values = sev_pal, limits = c("low", "moderate", "high")) +
      scale_x_continuous(expand = expansion(mult = c(0, 0.05))) +
      labs(title   = title_str,
           x       = "% Missing",
           y       = NULL,
           caption = paste0("Source: ", dataset_name)) +
      .base_theme()

    print(p_col)
    .save_plot(p_col, "missing_by_column.png", output_dir)
    cat("  Saved: missing_by_column.png\n")
  } else cat("  [OK] No missing values by column.\n")

  # -- By row ----------------------------------------------------------------
  row_miss   <- rowSums(is.na(df))
  n_complete <- sum(row_miss == 0)
  n_one      <- sum(row_miss == 1)
  n_two_plus <- sum(row_miss >= 2)
  n_half     <- sum(row_miss > n_cols / 2)

  miss_by_row <- data.frame(
    category = c("complete", "one_missing", "two_plus_missing"),
    n   = c(n_complete, n_one, n_two_plus),
    pct = round(c(n_complete, n_one, n_two_plus) / n_rows * 100, 1)
  )

  cat(sprintf("  Rows -- %.1f%% complete | %.1f%% with 1 NA | %.1f%% with 2+ NAs\n",
              n_complete / n_rows * 100, n_one / n_rows * 100, n_two_plus / n_rows * 100))
  if (n_half > 0)
    cat(sprintf("  [!!] %d row(s) have > 50%% columns missing -- consider dropping.\n", n_half))

  if (any(row_miss > 0)) {
    row_df <- data.frame(
      n_missing   = row_miss,
      color_group = cut(row_miss,
                        breaks = c(-1, 0, 2, Inf),
                        labels = c("0 missing", "1-2 missing", "3+ missing"))
    )

    p_row <- ggplot(row_df, aes(x = n_missing, fill = color_group)) +
      geom_histogram(binwidth = 1, color = .BG) +
      scale_fill_manual(values = c("0 missing"   = .TEAL,
                                   "1-2 missing" = .AMBER,
                                   "3+ missing"  = .RED)) +
      scale_x_continuous(breaks = scales::pretty_breaks()) +
      labs(title   = "How many columns are missing per row?",
           x       = "Number of missing columns per row",
           y       = "Number of rows",
           caption = paste0("Source: ", dataset_name)) +
      .base_theme()

    print(p_row)
    .save_plot(p_row, "missing_by_row.png", output_dir)
    cat("  Saved: missing_by_row.png\n")
  }

  # -- Overall missingness flag ----------------------------------------------
  total_miss_pct <- sum(is.na(df)) / (n_rows * n_cols) * 100
  if (total_miss_pct > 10)
    cat(sprintf("  [!]  Overall dataset missingness: %.1f%% -- imputation required.\n",
                total_miss_pct))

  # -- Heatmap ----------------------------------------------------------------
  p_heat     <- NULL
  cols_with_na <- miss_col$column[miss_col$n_missing > 0]

  if (length(cols_with_na) > 0) {
    sample_idx <- if (n_rows > 500) sample(n_rows, 500, replace = FALSE) else seq_len(n_rows)
    df_sample  <- df[sample_idx, cols_with_na, drop = FALSE]

    heat_df <- tidyr::pivot_longer(
      dplyr::mutate(df_sample, .row = dplyr::row_number()),
      cols = -".row", names_to = "column", values_to = "val"
    )
    heat_df$is_missing <- is.na(heat_df$val)

    p_heat <- ggplot(heat_df, aes(x = column, y = .row, fill = is_missing)) +
      geom_tile() +
      scale_fill_manual(values = c("FALSE" = "#F0F4F8", "TRUE" = .RED),
                        labels = c("Present", "Missing")) +
      labs(title   = "Where is the data missing?",
           x       = NULL, y = "Row index (sample up to 500)",
           fill    = NULL,
           caption = paste0("Source: ", dataset_name)) +
      .base_theme() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 7))

    print(p_heat)
    .save_plot(p_heat, "missing_heatmap.png", output_dir, width = 10, height = 7)
    cat("  Saved: missing_heatmap.png\n")
  } else cat("  No missing values -- skipping heatmap.\n")

  list(missing_by_col  = miss_col,
       missing_by_row  = miss_by_row,
       missing_heatmap = p_heat)
}


# # ===============================================================
# # run_eda() -- Main Entry Function                                           
# # ===============================================================

run_eda <- function(df, target_var = NULL, dataset_name, output_dir = "eda_output") {

  if (!is.data.frame(df)) stop("[run_eda] 'df' must be a data.frame or tibble.")
  if (nrow(df) == 0)      stop("[run_eda] Data frame has 0 rows.")

  # Validate target if provided
  has_target <- !is.null(target_var) && nzchar(target_var)
  if (has_target && !target_var %in% names(df))
    stop(sprintf("[run_eda] target_var '%s' not found.\n  Columns: %s",
                 target_var, paste(names(df), collapse = ", ")))

  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

  # Banner
  target_label <- if (has_target) target_var else "none (unsupervised)"
  cat("\n", strrep("=", 58), "\n", sep = "")
  cat(sprintf("# EDA: %-53s\n", dataset_name))
  cat(sprintf("# Target : %-51s\n", target_label))
  cat(sprintf("# Rows   : %-51d\n", nrow(df)))
  cat(sprintf("# Columns: %-51d\n", ncol(df)))
  cat("", strrep("=", 58), "\n\n", sep = "")

  # Type detection
  types <- .detect_types(df)

  all_na_cols <- names(df)[sapply(df, function(x) all(is.na(x)))]
  if (length(all_na_cols) > 0) {
    cat(sprintf("  [!!] All-NA columns excluded: %s\n", paste(all_na_cols, collapse = ", ")))
    types$numerical   <- setdiff(types$numerical,   all_na_cols)
    types$categorical <- setdiff(types$categorical, all_na_cols)
  }

  zv_cols <- names(df)[sapply(df, function(x) {
    x2 <- x[!is.na(x)]; length(x2) > 0 && length(unique(x2)) == 1
  })]
  if (length(zv_cols) > 0) {
    cat(sprintf("  [!]  Zero-variance columns excluded: %s\n", paste(zv_cols, collapse = ", ")))
    types$numerical   <- setdiff(types$numerical,   zv_cols)
    types$categorical <- setdiff(types$categorical, zv_cols)
  }

  # Blocks 1-3 always run (no target needed)
  b1  <- .block1_descriptive(df, types)
  b2  <- .block2_split(df, types)
  b3  <- .block3_correlations(df, types, dataset_name, output_dir)

  # Blocks 4-6 need a target -- skip gracefully if none
  if (has_target) {
    b4 <- .block4_cat_correlations(df, target_var, types, dataset_name, output_dir)
    b5 <- .block5_distributions(df, target_var, types, dataset_name, output_dir)
    b6 <- .block6_hypothesis(df, target_var, types, b1, b5, b4)
  } else {
    cat("\n[!] No target variable -- skipping blocks 4 (Cramer's V), 5 (distributions by group), 6 (hypothesis recommendations).\n")
    b4 <- list(cramers_v = data.frame(), significant_assoc = data.frame(), plot = NULL)
    b5 <- list(discriminating_vars = character(0))
    b6 <- list(hypothesis_table = data.frame())
  }

  b7  <- .block7_cleaning(df, target_var, output_dir)
  b7a <- .block7a_missing(df, dataset_name, output_dir)

  # Target rate (only if target provided)
  churn_rate <- if (has_target) {
    pos_class <- .positive_class(df[[target_var]])
    mean(as.character(df[[target_var]]) == pos_class, na.rm = TRUE)
  } else NULL

  cat(sprintf("\n[OK] EDA complete. %d charts saved to '%s/'\n",
              length(list.files(output_dir, pattern = "\\.png$")), output_dir))
  if (has_target)
    cat(sprintf("   %s rate: %.1f%%\n\n", target_var, churn_rate * 100))

  invisible(list(
    numerical_stats     = b1$numerical_stats,
    categorical_stats   = b1$categorical_stats,
    high_correlations   = b3$high_correlations,
    cramers_v           = b4$cramers_v,
    significant_assoc   = b4$significant_assoc,
    discriminating_vars = b5$discriminating_vars,
    hypothesis_table    = b6$hypothesis_table,
    warnings            = c(b7$warnings, list(possibly_categorical = b2$possibly_categorical)),
    churn_rate          = churn_rate,
    missing_by_col      = b7a$missing_by_col,
    missing_by_row      = b7a$missing_by_row,
    missing_heatmap     = b7a$missing_heatmap
  ))
}


# # ===============================================================
# # Block 0 * File Reader                                                     
# # ===============================================================
#
# load_data(path, sheet, ...)
#
# Supported formats (auto-detected from extension):
#   .csv / .tsv / .txt   -> readr::read_csv / read_tsv
#   .xlsx / .xls         -> readxl::read_excel
#   .rds / .RDS          -> readRDS
#   .RData / .rda        -> load()  (returns first data.frame found)
#   .json                -> jsonlite::fromJSON
#   .parquet             -> arrow::read_parquet
#
# After loading, prints: rows, columns, missing %, duplicates, and a head(5).
# All character columns kept as-is -- no silent type coercion.
# Returns a plain data.frame.

load_data <- function(path, sheet = 1, ...) {

  if (!file.exists(path))
    stop(sprintf("[load_data] File not found:\n  %s", path))

  ext <- tolower(tools::file_ext(path))

  df <- switch(ext,

    # -- Delimited text ------------------------------------------------------
    "csv" = {
      suppressPackageStartupMessages(library(readr))
      as.data.frame(readr::read_csv(path, show_col_types = FALSE, ...))
    },
    "tsv" = ,
    "txt" = {
      suppressPackageStartupMessages(library(readr))
      as.data.frame(readr::read_tsv(path, show_col_types = FALSE, ...))
    },

    # -- Excel ---------------------------------------------------------------
    "xlsx" = ,
    "xls"  = {
      if (!requireNamespace("readxl", quietly = TRUE))
        stop("[load_data] Package 'readxl' required. Run: install.packages('readxl')")
      as.data.frame(readxl::read_excel(path, sheet = sheet, ...))
    },

    # -- R native ------------------------------------------------------------
    "rds" = readRDS(path),

    "rdata" = ,
    "rda"   = {
      env  <- new.env()
      load(path, envir = env)
      objs <- ls(env)
      dfs  <- Filter(function(x) is.data.frame(env[[x]]), objs)
      if (length(dfs) == 0) stop("[load_data] No data.frame found in .RData file.")
      if (length(dfs) >  1) message(sprintf(
        "[load_data] Multiple data.frames found: %s. Returning '%s'.",
        paste(dfs, collapse = ", "), dfs[1]))
      env[[dfs[1]]]
    },

    # -- JSON ----------------------------------------------------------------
    "json" = {
      if (!requireNamespace("jsonlite", quietly = TRUE))
        stop("[load_data] Package 'jsonlite' required. Run: install.packages('jsonlite')")
      result <- jsonlite::fromJSON(path, flatten = TRUE)
      if (!is.data.frame(result))
        stop("[load_data] JSON did not parse to a data.frame. Check file structure.")
      result
    },

    # -- Parquet -------------------------------------------------------------
    "parquet" = {
      if (!requireNamespace("arrow", quietly = TRUE))
        stop("[load_data] Package 'arrow' required. Run: install.packages('arrow')")
      as.data.frame(arrow::read_parquet(path, ...))
    },

    # -- Unknown -------------------------------------------------------------
    stop(sprintf(
      "[load_data] Unsupported file type: '.%s'\n  Supported: csv, tsv, txt, xlsx, xls, rds, RData, json, parquet",
      ext
    ))
  )

  # -- Normalise to plain data.frame -----------------------------------------
  df <- as.data.frame(df)

  # -- Silently coerce columns that look numeric but loaded as character ------
  # (Common in CSVs with blank cells -- e.g. IBM Telco TotalCharges)
  df <- as.data.frame(lapply(df, function(x) {
    if (!is.character(x)) return(x)
    converted <- suppressWarnings(as.numeric(x))
    # Only coerce if conversion succeeds for > 90% of non-NA values
    n_valid    <- sum(!is.na(x))
    n_ok       <- sum(!is.na(converted))
    if (n_valid > 0 && n_ok / n_valid >= 0.9) converted else x
  }), stringsAsFactors = FALSE)

  # -- Load report -----------------------------------------------------------
  n_rows  <- nrow(df)
  n_cols  <- ncol(df)
  n_na    <- sum(is.na(df))
  na_pct  <- round(n_na / (n_rows * n_cols) * 100, 1)
  n_dups  <- sum(duplicated(df))

  cat("\n", strrep("=", 58), "\n", sep = "")
  cat(sprintf("# load_data() -- File loaded successfully%s\n",
              strrep(" ", 19)))
  cat("", strrep("=", 58), "\n", sep = "")
  cat(sprintf("# File    : %-47s\n", basename(path)))
  cat(sprintf("# Rows    : %-47d\n", n_rows))
  cat(sprintf("# Columns : %-47d\n", n_cols))
  cat(sprintf("# Missing : %-47s\n",
              sprintf("%d cells (%.1f%% of total)", n_na, na_pct)))
  cat(sprintf("# Dupes   : %-47s\n",
              sprintf("%d rows (%.1f%%)", n_dups, n_dups / n_rows * 100)))
  cat("", strrep("=", 58), "\n\n", sep = "")
  print(head(df, 5))
  cat("\n")

  df
}


# # ===============================================================
# # EXECUTION -- Edit the three lines below, then source() this file          
# # ===============================================================

FILE_PATH    <- "D:/2doBrain/KNS Brain/02 - Projects/LATAM Lab-subfolders/M02+Chustomer Churn/IBM Churn/WA_Fn-UseC_-Telco-Customer-Churn.csv"
TARGET_VAR   <- "Churn"   # Set to NULL if no target column: TARGET_VAR <- NULL
DATASET_NAME <- "IBM Telco -- LATAM Lab M2"

df  <- load_data(FILE_PATH)
eda <- run_eda(df, target_var = TARGET_VAR, dataset_name = DATASET_NAME)
