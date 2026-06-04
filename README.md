**PISA Financial Literacy Predictors (2018–2022)**

R code for analyzing predictors of adolescent financial literacy across the United States, Poland, and Spain using PISA 2018 and 2022 cycles.

**Overview**

This project analyzes which family, school, and socioeconomic factors predict financial literacy among 15-year-olds across three countries, comparing pre- and post-pandemic patterns. Based on MS thesis work at Purdue University (December 2025).


**Methods**

- Multiple regression with 10 plausible values combined via Rubin's rules
- Fay's BRR replicate weights (80 replicates)
- Multiple imputation for missing predictors (m = 10) using `mice`
- Country-stratified analysis (USA, Poland, Spain)

**Data**

PISA 2018 and 2022 financial literacy datasets are publicly available from OECD:
https://www.oecd.org/pisa/data/

Required files (place in `data/` folder):

- `CY07\_MSU\_FLT\_QQQ.SAV` (PISA 2018)

- `CY08MSP\_FLT\_QQQ.SAV` (PISA 2022)

**Usage**

1. Download the two `.SAV` files from OECD and place them in a `data/` folder.

2. Open `R/analysis.R` in RStudio.

3. Run once: uncomment and run the `install.packages()` line at the top.

4. Run the full script.

**Citation**

If you use this code, please cite:

Gorgulu, R. (2025). \*Money Matters: How Predictors of Adolescent Financial Literacy Have Changed Over Time Across Countries\* \[Master's thesis, Purdue University].

**License**
MIT License — see `LICENSE` file.

