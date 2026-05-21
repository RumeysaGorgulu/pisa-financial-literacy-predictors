# Installing needed packages
#install.packages(c("mice", "tidyverse",
#                   "haven", "naniar", "psych", "car",
#                   "plotly", "purrr", "survey", "mitools",
#                   "parameters","performance","see", "lmtest"))
library(mice)
library(tidyverse)
library(haven)
library(naniar)
library(psych)
library(car)
library(plotly)
library(purrr)
library(survey)
library(mitools)
library(ggplot2)
library(parameters)
library(performance)
library(see)
library(lmtest)
                   
# 1. Importing PISA 2018 and 2022 Datasets
fl18 <- read_sav("data/CY07_MSU_FLT_QQQ.SAV")
fl22 <- read_sav("data/CY08MSP_FLT_QQQ.SAV")

# 2. Identify Variables
id <- c("CNTRYID", "CNT", "CNTSTUID", "CNTSCHID")
student <- c("ST004D01T", "IMMIG",
             "FCFMLRTY", "FLCONFIN", "FLCONICT")
parent <- c("MISCED", "FISCED", "BMMJ1", "BFMJ2",
            "HOMEPOS", "FLFAMILY")
school <- c("FLSCHOOL", "ESCS")
weights <- c("W_FSTUWT", paste0("W_FSTURWT", 1:80))
flscore <- paste0("PV", 1:10, "FLIT")
all.variables <- c(id, student, parent, school, weights, flscore)

# 3. Filter Countries and Select/Filter Variables
countries <- c("POL", "USA", "ESP")
fl18.1 <- fl18 %>%
  select(all_of(all.variables)) %>%
  filter(CNT %in% countries)
fl22.1 <- fl22 %>%
  select (all_of(all.variables)) %>%
  filter(CNT %in% countries)

# 4. Recode Missing Values and MISCED/FISCED
fl18.2 <- fl18.1 %>%
  mutate(
    ST004D01T = replace(ST004D01T, ST004D01T %in%
                          c(9,8,7,5), NA),
    IMMIG = replace(IMMIG, IMMIG %in%
                      c(9, 8, 7, 5), NA),
    FCFMLRTY = replace(FCFMLRTY, FCFMLRTY %in%
                         c(99,98, 97, 95), NA),
    FLCONFIN = replace(FLCONFIN, FLCONFIN %in%
                         c(99.0000, 98.0000, 97.0000,
                           95.0000), NA),
    FLCONICT = replace(FLCONICT, FLCONICT %in%
                         c(99.0000, 98.0000, 97.0000,
                           95.0000), NA),
    MISCED = replace(MISCED, MISCED %in%
                       c(99, 98, 98, 95), NA),
    FISCED = replace(FISCED, FISCED %in%
                       c(99, 98, 98, 95), NA),
    BMMJ1 = replace(BMMJ1, BMMJ1 %in%
                      c(999.00,998.00, 997.00,
                        995.00), NA),
    BFMJ2 = replace(BFMJ2, BFMJ2 %in%
                      c(999.00, 998.00, 997.00,
                        995.00), NA),
    HOMEPOS = replace(HOMEPOS, HOMEPOS %in%
                        c(99.0000, 98.0000, 97.0000,
                          95.0000), NA),
    FLFAMILY = replace(FLFAMILY, FLFAMILY %in%
                         c(99.0000, 98.0000, 97.0000,
                           95.0000), NA),
    FLSCHOOL = replace(FLSCHOOL, FLSCHOOL %in%
                         c(99.0000, 98.0000, 97.0000,
                           95.0000), NA),
    ESCS = replace(ESCS, ESCS %in%
                     c(99.0000, 98.0000, 97.0000,
                       95.0000), NA)
  )
fl22.2 <- fl22.1 %>%
  mutate(
    ST004D01T = replace(ST004D01T, ST004D01T %in%
                          c(9,8,7,5), NA),
    IMMIG = replace(IMMIG, IMMIG %in%
                      c(9, 8, 7, 5), NA),
    FCFMLRTY = replace(FCFMLRTY, FCFMLRTY %in%
                         c(99,98, 97, 95), NA),
    FLCONFIN = replace(FLCONFIN, FLCONFIN %in%
                         c(99.0000, 98.0000, 97.0000,
                           95.0000), NA),
    FLCONICT = replace(FLCONICT, FLCONICT %in%
                         c(99.0000, 98.0000, 97.0000,
                           95.0000), NA),
    MISCED = replace(MISCED, MISCED %in%
                       c(99, 98, 98, 95), NA),
    FISCED = replace(FISCED, FISCED %in%
                       c(99, 98, 98, 95), NA),
    BMMJ1 = replace(BMMJ1, BMMJ1 %in%
                      c(999.00,998.00, 997.00,
                        995.00), NA),
    BFMJ2 = replace(BFMJ2, BFMJ2 %in%
                      c(999.00, 998.00, 997.00,
                        995.00), NA),
    HOMEPOS = replace(HOMEPOS, HOMEPOS %in%
                        c(99.0000, 98.0000, 97.0000,
                          95.0000), NA),
    FLFAMILY = replace(FLFAMILY, FLFAMILY %in%
                         c(99.0000, 98.0000, 97.0000,
                           95.0000), NA),
    FLSCHOOL = replace(FLSCHOOL, FLSCHOOL %in%
                         c(99.0000, 98.0000, 97.0000,
                           95.0000), NA),
    ESCS = replace(ESCS, ESCS %in%
                     c(99.0000, 98.0000, 97.0000,
                       95.0000), NA)
  )
fl22.2 <- fl22.2 %>%
  mutate(
    MISCED = case_when(
      MISCED == 1 ~ 0,
      MISCED == 2 ~ 1,
      MISCED == 3 ~ 2,
      MISCED == 4 ~ 3,
      MISCED == 5 ~ 4,
      MISCED == 6 ~ 4,
      MISCED == 7 ~ 5,
      MISCED %in% c(8,9,10) ~ 6,
      TRUE ~ MISCED
    ),
    FISCED = case_when(
      FISCED == 1 ~ 0,
      FISCED == 2 ~ 1,
      FISCED == 3 ~ 2,
      FISCED == 4 ~ 3,
      FISCED == 5 ~ 4,
      FISCED == 6 ~ 4,
      FISCED == 7 ~ 5,
      FISCED %in% c(8,9,10) ~ 6,
      TRUE ~ FISCED
    )
  )

# 5. Convert labelled variables
convert <- function(df, id) {
  categorical <- c("ST004D01T", "IMMIG")
  df %>%
    dplyr::mutate(
      dplyr::across(-dplyr::all_of(id), ~{
        if (!haven::is.labelled(.)) {
          .
        } else {
          nm <- dplyr::cur_column()
          if (nm %in% categorical) {
            haven::as_factor(., levels = "labels")
          } else {
            as.numeric(haven::zap_labels(.))
          }
        }
      })
    )
}
fl18.3 <- convert(fl18.2, id)
fl22.3 <- convert(fl22.2, id)

# 6. Adding Mean of Schools ESCS
fl18.3 <- convert(fl18.2, id) %>%
  group_by(CNTSCHID) %>%
  mutate(SCHESCS = weighted.mean(ESCS, W_FSTUWT, na.rm = TRUE)) %>%
  ungroup() %>%
  select(-ESCS)
fl22.3 <- convert(fl22.2, id) %>%
  group_by(CNTSCHID) %>%
  mutate(SCHESCS = weighted.mean(ESCS, W_FSTUWT, na.rm = TRUE)) %>%
  ungroup() %>%
  select(-ESCS)

# 7. Check Missingness
all.variables[all.variables == "ESCS"] <- "SCHESCS"
withoutcnt <- setdiff(all.variables, "CNT")
cnt.missing18 <- fl18.3 %>%
  group_by(CNT) %>%
  summarise(across(all_of(withoutcnt), ~ mean(is.na(.)) * 100, .names = "miss_{.col}")) %>%
  pivot_longer(-CNT, names_to = "variable", values_to = "miss_2018")
View(cnt.missing18)
cnt.missing22 <- fl22.3 %>%
  group_by(CNT) %>%
  summarise(across(all_of(withoutcnt), ~ mean(is.na(.)) * 100, .names = "miss_{.col}")) %>%
  pivot_longer(-CNT, names_to = "variable", values_to = "miss_2022")
View(cnt.missing22)

# 8. Select Countries for Final Analysis
usa18 <- fl18.3 %>% filter(CNT == "USA")
usa22 <- fl22.3 %>% filter(CNT == "USA")
poland18 <- fl18.3 %>% filter(CNT == "POL")
poland22 <- fl22.3 %>% filter(CNT == "POL")
spain18 <- fl18.3 %>% filter(CNT == "ESP")
spain22 <- fl22.3 %>% filter(CNT == "ESP")

# 9. Descriptive Statistics and Frequency
categorical <- c("ST004D01T","IMMIG")
continuous <- c("MISCED","FISCED","FCFMLRTY","FLCONFIN","FLCONICT",
                "HOMEPOS","FLFAMILY","FLSCHOOL","BMMJ1","BFMJ2","SCHESCS")
datasets <- list(
  usa18 = usa18, usa22 = usa22,
  poland18 = poland18, poland22 = poland22,
  spain18 = spain18, spain22 = spain22
)
designs <- purrr::imap(datasets, ~ svydesign(ids = ~1, weights = ~W_FSTUWT, data = .x))
continuous.summary_w <- purrr::imap_dfr(designs, function(des, name) {
  m <- svymean(as.formula(paste("~", paste(continuous, collapse = "+"))),
               design = des, na.rm = TRUE)
  v <- svyvar(as.formula(paste("~", paste(continuous, collapse = "+"))),
              design = des, na.rm = TRUE)
  sd_vec <- sqrt(diag(as.matrix(v)))
  tibble::tibble(
    dataset = name,
    variable = names(coef(m)),
    mean_w = as.numeric(coef(m)),
    sd_w = as.numeric(sd_vec)
  )
})
View(continuous.summary_w)
categorical.freq_w <- purrr::imap_dfr(designs, function(des, name) {
  purrr::map_dfr(intersect(categorical, names(des$variables)), function(v) {
    tab <- svytable(as.formula(paste0("~", v)), design = des)
    pct <- 100 * prop.table(tab)
    tibble::tibble(
      dataset = name,
      variable = v,
      level = names(tab),
      count_w = as.numeric(tab),
      percent_w = as.numeric(pct)
    )
  })
})
View(categorical.freq_w)
weighted_pv_summary <- function(data, pvlabel = "FLIT") {
  pv_cols <- paste0("PV", 1:10, pvlabel)
  weights <- data$W_FSTUWT
  means <- sapply(pv_cols, function(pv) {
    weighted.mean(data[[pv]], weights, na.rm = TRUE)
  })
  vars <- sapply(pv_cols, function(pv) {
    # Formula: sum(w * (x - mean_w)^2) / sum(w)
    m <- weighted.mean(data[[pv]], weights, na.rm = TRUE)
    sum(weights * (data[[pv]] - m)^2, na.rm = TRUE) / sum(weights, na.rm = TRUE)
  })
  data.frame(
    mean_w = mean(means),
    sd_w = sqrt(mean(vars))
  )
}
pv.summary_w <- purrr::imap_dfr(datasets, function(df, name) {
  weighted_pv_summary(df, "FLIT") %>% dplyr::mutate(dataset = name, .before = 1)
})
View(pv.summary_w)

# 10. Model Assumptions and Diagnostics
df.1 <- poland22
mod.1 <- lm(PV1FLIT ~ ST004D01T + IMMIG + FCFMLRTY + MISCED + FISCED +
              FLCONFIN + FLCONICT + HOMEPOS +
              FLFAMILY + FLSCHOOL + BMMJ1 + BFMJ2 + SCHESCS,
            data = df.1)
check_model(mod.1, panel = TRUE)
crPlots(mod.1)
vif(mod.1)
qqnorm(residuals(mod.1)); qqline(residuals(mod.1))
bptest(mod.1)

# 11. Imputation for Missing Variables (per country)
iv <- c("ST004D01T", "IMMIG", "FCFMLRTY", "FLCONFIN",
        "FLCONICT", "MISCED", "FISCED", "BMMJ1",
        "BFMJ2", "HOMEPOS", "FLFAMILY", "FLSCHOOL", "SCHESCS")
set.seed(2025)
imputation.1 <- function(df, name) {
  iv.data <- df %>% select(all_of(iv))
  fac <- sapply(iv.data, is.factor)
  nlev <- if (any(fac)) sapply(iv.data[fac], nlevels) else integer(0)
  meth <- make.method(iv.data); meth[] <- "pmm"
  if (length(nlev)) {
    meth[names(nlev)[nlev == 2]] <- "logreg"
    meth[names(nlev)[nlev > 2]] <- "polyreg"
  }
  imp <- mice(iv.data, m = 10, method = meth, seed = 2025)
  base <- df %>% select(CNTSTUID, CNT, CNTRYID, all_of(flscore), all_of(weights))
  for (i in 1:10) {
    assign(paste0(name, "_final", i),
           bind_cols(base, complete(imp, i)),
           envir = .GlobalEnv)
  }
  paste0(name, "_final", 1:10)
}
imputation.1(usa18, "usa18")
imputation.1(usa22, "usa22")
imputation.1(poland18, "poland18")
imputation.1(poland22, "poland22")
imputation.1(spain18, "spain18")
imputation.1(spain22, "spain22")

# 12. Final Datasets for Modeling
usa18.list <- mget(paste0("usa18_final", 1:10))
usa22.list <- mget(paste0("usa22_final", 1:10))
poland18.list <- mget(paste0("poland18_final", 1:10))
poland22.list <- mget(paste0("poland22_final", 1:10))
spain18.list <- mget(paste0("spain18_final", 1:10))
spain22.list <- mget(paste0("spain22_final", 1:10))

# 13. Survey Design
repw <- paste0("W_FSTURWT", 1:80)
predictors <- c("ST004D01T", "IMMIG", "FCFMLRTY", "MISCED", "FISCED",
                "FLCONFIN", "FLCONICT", "HOMEPOS", "FLFAMILY",
                "FLSCHOOL", "BMMJ1", "BFMJ2", "SCHESCS")
analysis <- function(list.of.dfs, predictors) {
  fits <- lapply(seq_along(list.of.dfs), function(k) {
    dfk <- list.of.dfs[[k]]
    pv <- paste0("PV", k, "FLIT")
    rw <- as.matrix(dfk[, repw]); storage.mode(rw) <- "double"
    des <- svrepdesign(weights=~W_FSTUWT, repweights=rw,
                       type="Fay", rho=0.5, combined.weights=TRUE, data=dfk)
    fml <- as.formula(paste(pv, "~", paste(predictors, collapse=" + ")))
    svyglm(fml, design=des)
  })
  pooled <- MIcombine(fits)
  est <- coef(pooled)
  se <- sqrt(diag(pooled$variance))
  t <- est/se
  p <- 2*pnorm(-abs(t))
  fmtp <- function(x) ifelse(x<.001,"<0.001",sprintf("%.3f",x))
  coef_table <- data.frame(term=names(est),
                           estimate=round(est,3),
                           std.error=round(se,3),
                           t=round(t,2),
                           p.value=fmtp(p),
                           row.names=NULL)
  r2_vals <- sapply(fits, function(m) {
    performance::r2(m, verbose = FALSE)$R2
  })
  r2_summary <- data.frame(
    r2_mean = mean(r2_vals, na.rm = TRUE),
    r2_min = min(r2_vals, na.rm = TRUE),
    r2_max = max(r2_vals, na.rm = TRUE)
  )
  list(
    coef_table = coef_table,
    r2_summary = r2_summary,
    r2_by_pv = r2_vals
  )
}

# 14. Running Analysis
usa18.res <- analysis(usa18.list, predictors)
usa22.res <- analysis(usa22.list, predictors)
pol18.res <- analysis(poland18.list, predictors)
pol22.res <- analysis(poland22.list, predictors)
sp18.res <- analysis(spain18.list, predictors)
sp22.res <- analysis(spain22.list, predictors)

# 15. Results
tag.coef <- function(x, country, year) {
  dplyr::mutate(x$coef_table, country = country, year = year)
}
all.coefs <- bind_rows(
  tag.coef(usa18.res, "USA", "2018"),
  tag.coef(usa22.res, "USA", "2022"),
  tag.coef(pol18.res, "Poland", "2018"),
  tag.coef(pol22.res, "Poland", "2022"),
  tag.coef(sp18.res, "Spain", "2018"),
  tag.coef(sp22.res, "Spain", "2022")
  )
View(all.coefs)
tag.r2 <- function(x, country, year) {
  mutate(x$r2_summary, country = country, year = year)
}
all.r2 <- bind_rows(
  tag.r2(usa18.res, "USA", "2018"),
  tag.r2(usa22.res, "USA", "2022"),
  tag.r2(pol18.res, "Poland", "2018"),
  tag.r2(pol22.res, "Poland", "2022"),
  tag.r2(sp18.res, "Spain", "2018"),
  tag.r2(sp22.res, "Spain", "2022")
  )
View(all.r2)