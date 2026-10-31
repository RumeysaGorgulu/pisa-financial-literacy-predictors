# Predictors of adolescent financial literacy: PISA 2018 and 2022
# United States, Poland, Spain
#
# Methods
#   - Weighted multiple regression of financial literacy on student, family and
#     school predictors, fitted separately for each country x cycle
#   - 10 plausible values (PVs) for financial literacy
#   - Fay's BRR variance estimation with 80 replicate weights (rho = 0.5)
#   - Multiple imputation of missing predictors with mice (m = 10)
#   - Imputation k is paired with PV k; the 10 fits are pooled with Rubin's rules
#
# Input : data/CY07_MSU_FLT_QQQ.SAV (2018), data/CY08MSP_FLT_QQQ.SAV (2022)
# Output: output/*.csv, output/results_table.md, plots/*.png
#
# Run from the repository root: Rscript R/analysis.R
# Runtime: about 10–30 minutes (mostly the imputation step).

# 0. Setup --------------------------------------------------------------------
# install.packages(c("tidyverse", "haven", "mice", "survey", "mitools", "car", "lmtest"))

suppressPackageStartupMessages({
  library(tidyverse)
  library(haven)
  library(mice)
  library(survey)
  library(mitools)
  library(car)
  library(lmtest)
})

# Thesis setting: the imputation model contains the predictors only.
# Set to TRUE for a sensitivity analysis in which imputation k also includes
# PV k of the outcome (recommended in the MI literature; can change estimates).
IMPUTE_WITH_OUTCOME <- FALSE

dir.create("output", showWarnings = FALSE)
dir.create("plots",  showWarnings = FALSE)

# 1. Import -------------------------------------------------------------------
fl18 <- read_sav("data/CY07_MSU_FLT_QQQ.SAV")
fl22 <- read_sav("data/CY08MSP_FLT_QQQ.SAV")

# 2. Variables ----------------------------------------------------------------
id      <- c("CNTRYID", "CNT", "CNTSTUID", "CNTSCHID")
student <- c("ST004D01T", "IMMIG", "FCFMLRTY", "FLCONFIN", "FLCONICT")
parent  <- c("MISCED", "FISCED", "BMMJ1", "BFMJ2", "HOMEPOS", "FLFAMILY")
school  <- c("FLSCHOOL", "ESCS")
repw    <- paste0("W_FSTURWT", 1:80)
weights <- c("W_FSTUWT", repw)
flscore <- paste0("PV", 1:10, "FLIT")
all_vars <- c(id, student, parent, school, weights, flscore)

countries <- c(USA = "USA", POL = "Poland", ESP = "Spain")

predictors  <- c("ST004D01T", "IMMIG", "FCFMLRTY", "MISCED", "FISCED",
                 "FLCONFIN", "FLCONICT", "HOMEPOS", "FLFAMILY",
                 "FLSCHOOL", "BMMJ1", "BFMJ2", "SCHESCS")
categorical <- c("ST004D01T", "IMMIG")
continuous  <- setdiff(predictors, categorical)

predictor_labels <- c(
  ST004D01T = "Gender", IMMIG = "Immigrant background",
  FCFMLRTY = "Familiarity with financial concepts",
  FLCONFIN = "Confidence about financial matters",
  FLCONICT = "Confidence with digital financial tools",
  MISCED = "Mother's education", FISCED = "Father's education",
  BMMJ1 = "Mother's occupational status", BFMJ2 = "Father's occupational status",
  HOMEPOS = "Home possessions", FLFAMILY = "Parental involvement in financial matters",
  FLSCHOOL = "Financial education at school", SCHESCS = "School mean ESCS"
)

# 3. Recode missing-value codes -----------------------------------------------
# read_sav() already converts SPSS user-defined missing values to NA; this step
# catches any remaining PISA missing codes that were not declared as missing.
to_na <- function(x, codes) replace(x, x %in% codes, NA)

codes_cat   <- c(5, 7, 8, 9)            # single-digit categorical variables
codes_index <- c(95, 97, 98, 99)        # derived indices and 2022 ISCED
codes_isei  <- c(995, 997, 998, 999)    # occupational status (ISEI)

recode_missing <- function(df, cycle) {
  isced_codes <- if (cycle == 2018) c(7, 8, 9) else codes_index  # 2018 ISCED 0–6
  df %>%
    mutate(
      across(c(ST004D01T, IMMIG), ~ to_na(., codes_cat)),
      across(c(FCFMLRTY, FLCONFIN, FLCONICT, HOMEPOS, FLFAMILY, FLSCHOOL, ESCS),
             ~ to_na(., codes_index)),
      across(c(MISCED, FISCED), ~ to_na(., isced_codes)),
      across(c(BMMJ1, BFMJ2), ~ to_na(., codes_isei))
    )
}

# 2022 ISCED (1–10) mapped onto the 2018 scale (0–6) for comparability
harmonize_isced_2022 <- function(x) {
  case_when(
    x == 1 ~ 0, x == 2 ~ 1, x == 3 ~ 2, x == 4 ~ 3,
    x %in% c(5, 6) ~ 4, x == 7 ~ 5, x %in% c(8, 9, 10) ~ 6,
    TRUE ~ as.numeric(x)
  )
}

# Labelled categorical variables become factors; everything else numeric
convert <- function(df) {
  df %>%
    mutate(across(-all_of(id), ~ {
      if (!is.labelled(.)) .
      else if (cur_column() %in% categorical) as_factor(., levels = "labels")
      else as.numeric(zap_labels(.))
    })) %>%
    mutate(across(all_of(categorical), droplevels))
}

prepare <- function(df, cycle) {
  out <- df %>%
    select(all_of(all_vars)) %>%
    filter(CNT %in% names(countries)) %>%
    recode_missing(cycle)

  if (cycle == 2022) {
    out <- out %>% mutate(across(c(MISCED, FISCED), harmonize_isced_2022))
  }

  out %>%
    convert() %>%
    mutate(CNT = as.character(CNT)) %>%
    # School socioeconomic composition: weighted school mean of student ESCS
    group_by(CNTSCHID) %>%
    mutate(SCHESCS = weighted.mean(ESCS, W_FSTUWT, na.rm = TRUE),
           SCHESCS = if_else(is.nan(SCHESCS), NA_real_, SCHESCS)) %>%
    ungroup() %>%
    select(-ESCS)
}

fl <- list("2018" = prepare(fl18, 2018), "2022" = prepare(fl22, 2022))
rm(fl18, fl22); invisible(gc())

# One data set per country x cycle
datasets <- list()
for (cycle in names(fl)) {
  for (cnt in names(countries)) {
    datasets[[paste(cnt, cycle, sep = "_")]] <- fl[[cycle]] %>% filter(CNT == cnt)
  }
}

# 4. Missingness ----------------------------------------------------------------
missingness <- imap_dfr(datasets, function(df, key) {
  tibble(dataset = key, variable = predictors,
         missing_pct = map_dbl(predictors, ~ round(mean(is.na(df[[.x]])) * 100, 2)))
}) %>%
  pivot_wider(names_from = dataset, values_from = missing_pct)
write_csv(missingness, "output/missingness.csv")

sample_sizes <- imap_dfr(datasets, ~ tibble(dataset = .y, n = nrow(.x)))
write_csv(sample_sizes, "output/sample_sizes.csv")
print(sample_sizes)

# 5. Weighted descriptive statistics ----------------------------------------------
designs <- map(datasets, ~ svydesign(ids = ~1, weights = ~W_FSTUWT, data = .x))

descriptives_continuous <- imap_dfr(designs, function(des, key) {
  map_dfr(continuous, function(v) {
    f <- as.formula(paste0("~", v))
    m <- svymean(f, des, na.rm = TRUE)
    s <- svyvar(f, des, na.rm = TRUE)
    tibble(dataset = key, variable = v,
           mean_w = as.numeric(coef(m)), sd_w = sqrt(as.numeric(coef(s))))
  })
})
write_csv(descriptives_continuous, "output/descriptives_continuous.csv")

descriptives_categorical <- imap_dfr(designs, function(des, key) {
  map_dfr(categorical, function(v) {
    tab <- svytable(as.formula(paste0("~", v)), design = des)
    tibble(dataset = key, variable = v, level = names(tab),
           count_w = as.numeric(tab), percent_w = as.numeric(100 * prop.table(tab)))
  })
})
write_csv(descriptives_categorical, "output/descriptives_categorical.csv")

# Financial literacy: weighted mean and SD, averaged over the 10 PVs
fl_summary <- imap_dfr(datasets, function(df, key) {
  w <- df$W_FSTUWT
  stats <- map_dfr(flscore, function(pv) {
    m <- weighted.mean(df[[pv]], w, na.rm = TRUE)
    v <- sum(w * (df[[pv]] - m)^2, na.rm = TRUE) / sum(w, na.rm = TRUE)
    tibble(mean = m, var = v)
  })
  tibble(dataset = key, fl_mean_w = mean(stats$mean), fl_sd_w = sqrt(mean(stats$var)))
})
write_csv(fl_summary, "output/financial_literacy_summary.csv")

# 6. Regression diagnostics (PV1, complete cases) ---------------------------------
diag_formula <- reformulate(predictors, "PV1FLIT")

diagnostics <- imap_dfr(datasets, function(df, key) {
  mod <- lm(diag_formula, data = df, weights = W_FSTUWT)
  png(paste0("plots/diagnostics_", key, ".png"), width = 1400, height = 1400, res = 150)
  par(mfrow = c(2, 2)); plot(mod); dev.off()
  v <- vif(mod)
  v <- if (is.matrix(v)) v[, "GVIF^(1/(2*Df))"]^2 else v
  bp <- bptest(mod)
  tibble(dataset = key, max_vif = round(max(v), 2),
         max_vif_variable = names(v)[which.max(v)],
         breusch_pagan_p = signif(bp$p.value, 3))
})
write_csv(diagnostics, "output/diagnostics.csv")

# 7. Multiple imputation -------------------------------------------------------------
# Returns 10 completed data sets per country x cycle. Data set k is analysed
# with PV k in step 8.

impute <- function(df, key) {
  message("Imputing ", key)
  iv_data <- df %>% select(all_of(predictors))
  method_for <- function(dat) {
    meth <- make.method(dat); meth[] <- "pmm"
    for (v in names(dat)[sapply(dat, is.factor)]) {
      meth[v] <- if (nlevels(dat[[v]]) == 2) "logreg" else "polyreg"
    }
    meth
  }
  base <- df %>% select(CNTSTUID, CNT, CNTRYID, all_of(flscore), all_of(weights))

  if (!IMPUTE_WITH_OUTCOME) {
    imp <- mice(iv_data, m = 10, method = method_for(iv_data),
                seed = 2025, printFlag = FALSE)
    map(1:10, ~ bind_cols(base, complete(imp, .x)))
  } else {
    map(1:10, function(k) {
      pv  <- paste0("PV", k, "FLIT")
      dat <- bind_cols(iv_data, df[pv])
      meth <- method_for(dat); meth[pv] <- ""
      imp <- mice(dat, m = 1, method = meth, seed = 2025 + k, printFlag = FALSE)
      bind_cols(base, complete(imp, 1) %>% select(all_of(predictors)))
    })
  }
}

imputed <- imap(datasets, impute)

# 8. Survey-weighted regression, pooled with Rubin's rules --------------------------
weighted_r2 <- function(fit, y, w) {
  e <- y - fitted(fit)
  1 - sum(w * e^2) / sum(w * (y - weighted.mean(y, w))^2)
}

analyse <- function(dfs) {
  fits <- map(seq_along(dfs), function(k) {
    dfk <- dfs[[k]]
    rw  <- as.matrix(dfk[, repw]); storage.mode(rw) <- "double"
    des <- svrepdesign(weights = ~W_FSTUWT, repweights = rw, type = "Fay",
                       rho = 0.5, combined.weights = TRUE, data = dfk)
    svyglm(reformulate(predictors, paste0("PV", k, "FLIT")), design = des)
  })
  pooled <- MIcombine(fits)
  est <- coef(pooled)
  se  <- sqrt(diag(pooled$variance))
  z   <- est / se
  r2  <- map2_dbl(fits, seq_along(dfs), function(f, k) {
    weighted_r2(f, dfs[[k]][[paste0("PV", k, "FLIT")]], dfs[[k]]$W_FSTUWT)
  })
  list(
    coefs = tibble(term = names(est), estimate = est, std.error = se,
                   conf.low = est - 1.96 * se, conf.high = est + 1.96 * se,
                   z = z, p.value = 2 * pnorm(-abs(z))),
    r2 = tibble(r2_mean = mean(r2), r2_min = min(r2), r2_max = max(r2))
  )
}

results <- imap(imputed, function(dfs, key) { message("Modelling ", key); analyse(dfs) })

split_key <- function(key) {
  parts <- str_split_1(key, "_")
  list(country = countries[[parts[1]]], year = parts[2])
}

coefficients <- imap_dfr(results, function(r, key) {
  k <- split_key(key)
  r$coefs %>% mutate(country = k$country, year = k$year, .before = 1)
})
write_csv(coefficients %>% mutate(across(where(is.double), ~ signif(., 4))),
          "output/coefficients.csv")

r2_table <- imap_dfr(results, function(r, key) {
  k <- split_key(key)
  r$r2 %>% mutate(country = k$country, year = k$year, .before = 1)
})
write_csv(r2_table %>% mutate(across(where(is.double), ~ round(., 3))), "output/r2.csv")
print(r2_table)

# 9. Coefficient plot ----------------------------------------------------------------
# Continuous predictors are shown per 1 SD (weighted SD within country x cycle),
# so effects are comparable across predictors; units stay in PISA score points.

sd_lookup <- descriptives_continuous %>%
  mutate(country = countries[str_sub(dataset, 1, 3)], year = str_sub(dataset, 5, 8)) %>%
  select(country, year, term = variable, sd_w)

plot_df <- coefficients %>%
  filter(term %in% continuous) %>%
  left_join(sd_lookup, by = c("country", "year", "term")) %>%
  mutate(across(c(estimate, conf.low, conf.high), ~ . * sd_w),
         term = factor(predictor_labels[term],
                       levels = rev(predictor_labels[continuous])))

p_coef <- ggplot(plot_df, aes(estimate, term, color = year)) +
  geom_vline(xintercept = 0, color = "grey60") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high),
                  position = position_dodge(width = 0.6), size = 0.25) +
  facet_wrap(~ country) +
  scale_color_manual(values = c("2018" = "grey50", "2022" = "steelblue")) +
  labs(title = "Predictors of financial literacy, PISA 2018 vs 2022",
       subtitle = "Change in score points per 1 SD of each predictor, 95% CI (BRR + Rubin's rules)",
       x = "Score points per 1 SD", y = NULL, color = "Cycle") +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom")
ggsave("plots/coefficients_by_country.png", p_coef, width = 11, height = 6, dpi = 150)

# 10. Markdown tables for the README -------------------------------------------------
md_table <- function(df) {
  c(paste0("| ", paste(names(df), collapse = " | "), " |"),
    paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|"),
    apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")))
}

r2_md <- r2_table %>%
  transmute(Country = country, Cycle = year,
            `R² (mean over PVs)` = sprintf("%.3f", r2_mean),
            `Range` = sprintf("%.3f–%.3f", r2_min, r2_max))

stars <- function(p) case_when(p < .001 ~ "***", p < .01 ~ "**", p < .05 ~ "*", TRUE ~ "")
coef_md <- coefficients %>%
  filter(term != "(Intercept)") %>%
  mutate(cell = sprintf("%.2f%s", estimate, stars(p.value)),
         col = paste(country, year)) %>%
  select(term, col, cell) %>%
  pivot_wider(names_from = col, values_from = cell) %>%
  mutate(term = case_when(
    term %in% names(predictor_labels) ~ predictor_labels[term],
    str_starts(term, "ST004D01T") ~ paste("Gender:", str_remove(term, "^ST004D01T")),
    str_starts(term, "IMMIG") ~ paste("Immigrant background:", str_remove(term, "^IMMIG")),
    TRUE ~ term
  )) %>%
  rename(Predictor = term)

writeLines(c("### Variance explained", "", md_table(r2_md), "",
             "### Unstandardized coefficients (score points)", "",
             md_table(coef_md), "",
             "\\* p < .05, \\*\\* p < .01, \\*\\*\\* p < .001"),
           "output/results_table.md")

writeLines(capture.output(sessionInfo()), "output/sessionInfo.txt")
message("Done. Results are in output/ and plots/.")
