# Predictors of Adolescent Financial Literacy: PISA 2018 vs. 2022

R code for analyzing which student, family and school factors predict 15-year-olds' financial literacy in the **United States, Poland and Spain**, and whether those relations changed between the pre-pandemic (2018) and post-pandemic (2022) PISA cycles.

Based on my M.S. thesis at Purdue University (December 2025).

## Key findings

- **Consistent positive predictors** in almost every country and cycle:
  - Familiarity with financial concepts
  - Confidence with digital financial tools
  - Home possessions
  - School socioeconomic composition
- **School-based financial education was negatively associated** with financial literacy in every model. Exposure alone is a weak indicator of effective financial socialization.
- General financial confidence and family financial involvement were negatively associated in several models.
- **Few predictors changed between 2018 and 2022.** The clearest shift is the growing association of school socioeconomic composition in Poland.
- Models explain about 25–27% of the variance in financial literacy.

This repository fits a separate model for each country and cycle. The formal tests of change between cycles (pooled models with cycle × predictor interactions) are reported in the accompanying manuscript.

![Coefficients by country and cycle](plots/coefficients_by_country.png)

<!-- After running R/analysis.R, paste the "Variance explained" table from output/results_table.md here. -->

## Methods

| Challenge | How it is handled |
|---|---|
| Outcome measured with error | 10 plausible values; one model per PV, pooled with **Rubin's rules** (`mitools::MIcombine`) |
| Complex survey sample | Final student weights plus **Fay's BRR** variance estimation with 80 replicate weights (ρ = 0.5) (`survey::svrepdesign`) |
| Missing predictors | **Multiple imputation** with `mice` (m = 10; PMM for continuous predictors, logistic or polytomous regression for categorical ones); imputation *k* is paired with PV *k* |
| Changed coding across cycles | 2022 parental education (ISCED 2011) harmonized to the 2018 scale |
| School context | School socioeconomic composition = weighted school mean of student ESCS |
| Model assumptions | Residual plots, VIF and Breusch–Pagan test per country × cycle (`output/diagnostics.csv`) |

An option `IMPUTE_WITH_OUTCOME` (default `FALSE`, as in the thesis) runs a sensitivity analysis in which the outcome is included in the imputation model.

## Repository structure

```
R/analysis.R      full pipeline: import → cleaning → descriptives → imputation → models → tables/plots
data/             PISA .SAV files go here (not tracked)
output/           CSV results and results_table.md (created by the script)
plots/            coefficient plot and diagnostic plots (created by the script)
```

## Reproducing

1. Download the PISA 2018 and 2022 financial literacy student files (SPSS) from https://www.oecd.org/pisa/data/ and place them in `data/`:
   - `CY07_MSU_FLT_QQQ.SAV` (2018)
   - `CY08MSP_FLT_QQQ.SAV` (2022)
2. Install the packages:
   ```r
   install.packages(c("tidyverse", "haven", "mice", "survey", "mitools", "car", "lmtest"))
   ```
3. From the repository root, run:
   ```
   Rscript R/analysis.R
   ```

## Citation

Gorgulu, R. (2025). *Money matters: How predictors of adolescent financial literacy have changed over time across countries* [Master's thesis, Purdue University].

## License

MIT, see `LICENSE`.
