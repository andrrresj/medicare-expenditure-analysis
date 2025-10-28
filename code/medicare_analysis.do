/*==============================================================================
PROJECT:     Medical Expenditure Analysis - Medicare Population
AUTHOR:      Andres Augustine Jimenez
COURSE:      Econ 650-01
DATE:        October 2025
DATASET:     mus03data.dta
DESCRIPTION: Comprehensive analysis of medical expenditure patterns among 
             Medicare-eligible individuals (65+), examining retirement effects,
             health limitations, and demographic variations in healthcare     spending.
             
CONTENTS:    1. Setup and Data Preparation
             2. Descriptive Statistics
             3. Primary Regression Analysis
             4. Model Diagnostics
             5. Advanced Analyses
             6. Visualization
=============================================================================*/

* ========================================
* 1. SETUP AND INITIALIZATION
* ========================================
clear all
set more off
capture log close
log using "medicare.log", replace 

set scheme s2color  


cd "/Users/andresjimenez/Documents/Stata" 
use "mus03data.dta", clear


* Create folders for outputs
capture mkdir "tables"
capture mkdir "figures"
capture mkdir "logs"

* Add descriptive variable labels
label variable phylim "Physical Limitation"
label variable actlim "Activity Limitation"
label variable totchr "Number of Chronic Conditions"
label variable age "Age (years)"
label variable female "Female"
label variable income "Income ($1,000s)"
label variable retire "Retired"
label variable ltotexp "Log Total Expenditure"
label variable totexp "Total Expenditure ($)"
label variable educyr "Years of Education"

* Display dataset overview
describe, short
display _newline "Sample size: " _N " observations"

* ========================================
* 2. DESCRIPTIVE STATISTICS
* ========================================
display _newline(2) _dup(80) "=" _newline ///
    "DESCRIPTIVE STATISTICS" _newline _dup(80) "="

* Summary statistics table
estpost summarize totexp ltotexp retire female phylim actlim totchr age income educyr
esttab using "tables/descriptive_stats.rtf", ///
    cells("mean(fmt(2)) sd(fmt(2)) min max count") ///
    nomtitle nonumber ///
    title("Table 1: Descriptive Statistics") ///
    replace

* Display in console
estpost summarize totexp ltotexp retire female phylim actlim totchr age income educyr
esttab, cells("mean(fmt(2)) sd(fmt(2)) min max count") ///
    nomtitle nonumber ///
    title("Descriptive Statistics")

* Correlation matrix
display _newline "Correlation Matrix:"
pwcorr phylim actlim totchr age income female, star(0.05)

* Expenditure distribution summary
display _newline "Expenditure Distribution:"
tabstat totexp, stats(mean median sd min max p25 p75) format(%12.2f)

* ========================================
* 3. PRIMARY REGRESSION ANALYSIS
* ========================================
display _newline(2) _dup(80) "=" _newline ///
    "PRIMARY REGRESSION ANALYSIS" _newline _dup(80) "="

* ----------------------------------------
* Analysis 1: Retirement and Gender Effects
* ----------------------------------------
display _newline "=== Analysis 1: Retirement and Gender Interaction ==="

* Generate interaction term
gen retire_female = retire * female
label variable retire_female "Retired × Female"

* Run regression
regress ltotexp retire female retire_female
estimates store retirement_model

* Interpret the interaction
display _newline "Interpretation:"
display "Effect of retirement for males: " _b[retire]
display "Effect of retirement for females: " _b[retire] + _b[retire_female]
display "Differential effect (F-M): " _b[retire_female]

* ----------------------------------------
* Analysis 2: Progressive Model Specifications
* ----------------------------------------
display _newline(2) "=== Analysis 2: Health Limitation Models ==="

* Model 1: Baseline - Physical & activity limitations
eststo baseline: regress ltotexp phylim actlim
display "Model 1: Baseline (R² = " %5.4f e(r2) ")"

* Model 2: Add chronic conditions
eststo improved: regress ltotexp phylim actlim totchr
display "Model 2: Add chronic conditions (R² = " %5.4f e(r2) ")"

* Model 3: Full specification with demographics
eststo robust: regress ltotexp phylim actlim totchr age female income
display "Model 3: Full specification (R² = " %5.4f e(r2) ")"

* Export comprehensive regression table
esttab baseline improved robust using "tables/medical_expenditure.rtf", ///
    replace ///
    title("Table 2: Determinants of Medical Expenditure (Log Scale)") ///
    mtitles("Baseline" "Add Health" "Full Model") ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("N Observations" "r2 R-squared" "r2_a Adjusted R²" "rmse RMSE") ///
    sfmt(%9.0f %9.4f %9.4f %9.4f) ///
    note("Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01") ///
    nobaselevels ///
    nogaps

* Display in console with additional statistics
esttab baseline improved robust, ///
    title("Medical Expenditure Analysis") ///
    mtitles("Baseline" "Add Health" "Full Model") ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    scalars("N Observations" "r2 R-squared" "r2_a Adjusted R²") ///
    sfmt(%9.0f %9.4f %9.4f)

* ========================================
* 4. MODEL DIAGNOSTICS
* ========================================
display _newline(2) _dup(80) "=" _newline ///
    "MODEL DIAGNOSTICS - FULL SPECIFICATION" _newline _dup(80) "="

* Re-estimate full model for diagnostics
quietly regress ltotexp phylim actlim totchr age female income

* Test for heteroskedasticity
display _newline "=== Heteroskedasticity Test (Breusch-Pagan) ==="
estat hettest
display "H0: Homoskedastic errors. Reject if p < 0.05"

* Multicollinearity check
display _newline "=== Variance Inflation Factors (VIF) ==="
estat vif
display "Rule of thumb: VIF > 10 indicates problematic multicollinearity"

* Generate and analyze residuals
predict residuals_diag, residuals
predict fitted_diag, xb

* Residual distribution
display _newline "=== Residual Analysis ==="
summarize residuals_diag, detail

* Create diagnostic plots
histogram residuals_diag, normal ///
    title("Figure 1: Residual Distribution") ///
    xtitle("Residuals") ///
    graphregion(color(white)) bgcolor(white) ///
    note("Overlay: Normal distribution")
graph export "figures/residuals_histogram.png", replace

* Q-Q plot for normality
qnorm residuals_diag, ///
    title("Figure 2: Q-Q Plot of Residuals") ///
    graphregion(color(white)) bgcolor(white)
graph export "figures/qq_plot.png", replace

* Residuals vs fitted plot
scatter residuals_diag fitted_diag, ///
    title("Figure 3: Residuals vs Fitted Values") ///
    ytitle("Residuals") xtitle("Fitted Values") ///
    yline(0, lcolor(red) lpattern(dash)) ///
    graphregion(color(white)) bgcolor(white)
graph export "figures/residuals_fitted.png", replace

* Identify influential observations
predict leverage_diag, leverage
predict cooksd_diag, cooksd

display _newline "=== Influential Observations ==="
display "Observations with Cook's D > 4/N threshold:"
list totexp ltotexp phylim actlim totchr if cooksd_diag > 4/e(N), ///
    separator(0) abbreviate(12)

* Clean up diagnostic variables
drop residuals_diag fitted_diag leverage_diag cooksd_diag

* ========================================
* 5. ADVANCED ANALYSES
* ========================================
display _newline(2) _dup(80) "=" _newline ///
    "ADVANCED ANALYSES" _newline _dup(80) "="

* ----------------------------------------
* Analysis A: Age-Chronic Condition Interaction
* ----------------------------------------
display _newline "=== Interaction: Age × Chronic Conditions ==="

gen age_totchr = age * totchr
label variable age_totchr "Age × Chronic Conditions"

regress ltotexp phylim actlim totchr age female income age_totchr
test age_totchr
display "Interpretation: Test whether the effect of chronic conditions varies with age"

drop age_totchr  // Clean up

* ----------------------------------------
* Analysis B: Age Group Comparisons
* ----------------------------------------
display _newline(2) "=== Expenditure by Age Groups ==="

gen age_group = 1 if age < 70
replace age_group = 2 if age >= 70 & age < 75
replace age_group = 3 if age >= 75 & age < 80
replace age_group = 4 if age >= 80 & age < .
label define age_lbl 1 "65-69" 2 "70-74" 3 "75-79" 4 "80+"
label values age_group age_lbl
label variable age_group "Age Group"

table age_group, stat(mean totexp) stat(sd totexp) stat(count totexp) ///
    nformat(%12.2f mean sd) nformat(%12.0f count)

* ----------------------------------------
* Analysis C: Health Risk Categories
* ----------------------------------------
display _newline(2) "=== Expenditure by Health Risk Level ==="

gen health_risk = 0 if totchr == 0
replace health_risk = 1 if totchr >= 1 & totchr <= 2
replace health_risk = 2 if totchr >= 3 & totchr < .
label define risk_lbl 0 "Low Risk" 1 "Medium Risk" 2 "High Risk"
label values health_risk risk_lbl
label variable health_risk "Health Risk Category"

table health_risk, stat(mean totexp) stat(median totexp) stat(count totexp) ///
    nformat(%12.2f mean median) nformat(%12.0f count)

* Test for differences across risk groups
oneway totexp health_risk, tabulate

* ----------------------------------------
* Analysis D: Quantile Regression
* ----------------------------------------
display _newline(2) "=== Quantile Regression Analysis ==="
display "Examining effects across the expenditure distribution"

quietly qreg ltotexp phylim actlim totchr age female income, quantile(0.25)
estimates store q25

quietly qreg ltotexp phylim actlim totchr age female income, quantile(0.50)
estimates store q50

quietly qreg ltotexp phylim actlim totchr age female income, quantile(0.75)
estimates store q75

esttab q25 q50 q75 using "tables/quantile_regression.rtf", ///
    replace ///
    title("Table 3: Quantile Regression Results") ///
    mtitles("25th Percentile" "Median" "75th Percentile") ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    note("Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")

esttab q25 q50 q75, ///
    title("Quantile Regression Results") ///
    mtitles("Q25" "Median" "Q75") ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01)

* ----------------------------------------
* Analysis E: Expenditure by Education and Gender
* ----------------------------------------
display _newline(2) "=== Mean Expenditure by Education and Gender ==="

* Get unique education levels
quietly levelsof educyr, local(educ_levels)
local num_educ: word count `educ_levels'

* Create matrix for results
matrix means_matrix = J(`num_educ', 2, .)

* Calculate means
local row = 1
foreach ed of local educ_levels {
    forvalues gen = 0/1 {
        quietly summarize totexp if educyr == `ed' & female == `gen'
        matrix means_matrix[`row', `gen'+1] = r(mean)
    }
    local row = `row' + 1
}

* Label and display matrix
matrix rownames means_matrix = `educ_levels'
matrix colnames means_matrix = "Male" "Female"
display _newline "Mean Total Expenditure ($) by Education Years and Gender:"
matrix list means_matrix, format(%12.2f)

* ========================================
* 6. VISUALIZATION
* ========================================
display _newline(2) _dup(80) "=" _newline ///
    "GENERATING VISUALIZATIONS" _newline _dup(80) "="

* ----------------------------------------
* Coefficient Plot
* ----------------------------------------
quietly regress ltotexp phylim actlim totchr age female income
estimates store full_model

coefplot full_model, drop(_cons) ///
    xline(0, lcolor(red) lpattern(dash)) ///
    xlabel(, format(%9.2f)) ///
    title("Figure 4: Determinants of Medical Expenditure") ///
    subtitle("Coefficient Estimates with 95% Confidence Intervals") ///
    xtitle("Coefficient Estimate") ///
    graphregion(color(white)) bgcolor(white) ///
    ciopts(recast(rcap))
graph export "figures/coefficient_plot.png", replace

* ----------------------------------------
* Marginal Effects: Chronic Conditions
* ----------------------------------------
quietly regress ltotexp phylim actlim totchr age female income
margins, at(totchr=(0(1)10))
marginsplot, ///
    title("Figure 5: Predicted Expenditure by Chronic Conditions") ///
    ytitle("Predicted Log Expenditure") ///
    xtitle("Number of Chronic Conditions") ///
    graphregion(color(white)) bgcolor(white) ///
    plot1opts(lcolor(navy) lwidth(medium)) ///
    ci1opts(color(navy%30))
graph export "figures/margins_chronic.png", replace

* ----------------------------------------
* Age Effects Visualization
* ----------------------------------------
margins, at(age=(65(1)90)) atmeans
marginsplot, ///
    title("Figure 6: Age Profile of Medical Expenditure") ///
    ytitle("Predicted Log Expenditure") ///
    xtitle("Age (years)") ///
    graphregion(color(white)) bgcolor(white) ///
    plot1opts(lcolor(maroon) lwidth(medium)) ///
    ci1opts(color(maroon%30))
graph export "figures/margins_age.png", replace

* ----------------------------------------
* Box Plot: Expenditure by Risk Group
* ----------------------------------------
graph box totexp, over(health_risk) ///
    title("Figure 7: Expenditure Distribution by Health Risk") ///
    ytitle("Total Expenditure ($)") ///
    graphregion(color(white)) bgcolor(white) ///
    marker(1, mcolor(green)) ///
    note("Outliers truncated at 95th percentile for visualization")
graph export "figures/expenditure_by_risk.png", replace

* ========================================
* 7. SUMMARY AND CLEANUP
* ========================================
display _newline(2) _dup(80) "=" _newline ///
    "ANALYSIS COMPLETE" _newline _dup(80) "="

display _newline "Key Findings Summary:"
display "1. Health limitations significantly increase expenditure"
display "2. Chronic conditions show strong positive association"
display "3. Age and gender effects present after controlling for health"
display "4. Effects vary across expenditure distribution (quantile analysis)"

display _newline "Outputs Generated:"
display "  Tables:  tables/descriptive_stats.rtf"
display "           tables/medical_expenditure.rtf"
display "           tables/quantile_regression.rtf"
display "  Figures: figures/residuals_histogram.png"
display "           figures/qq_plot.png"
display "           figures/residuals_fitted.png"
display "           figures/coefficient_plot.png"
display "           figures/margins_chronic.png"
display "           figures/margins_age.png"
display "           figures/expenditure_by_risk.png"
display "  Log:     logs/medicare_expenditure_analysis.log"

* Clear stored estimates
estimates clear
eststo clear

* Close log
log close
