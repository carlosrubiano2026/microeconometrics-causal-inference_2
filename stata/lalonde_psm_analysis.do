/********************************************************************
Question 2 — LaLonde / Dehejia-Wahba exercise
Propensity Score Matching and OLS comparisons

Data: dw.dta
Author: Carlos Arturo Rubiano Passos
********************************************************************/
cls
clear all
set more off

/********************************************************************
0. USER SETTINGS
********************************************************************/

global data_path "/Users/carlosrubiano/Documents/DOCS_CARLOS/economía/MSc economics /2nd Term/Econometric Methods 2/PS5/dw.dta"

use "$data_path", clear

/********************************************************************
1. BASIC INSPECTION
********************************************************************/

describe
summarize

tab treat
tab exp
tab cps
tab psid
tab treat exp
tab treat cps
tab treat psid

/********************************************************************
2. DEFINE VARIABLES AND SAMPLES
********************************************************************/

global y re78
global x_basic age ed black hisp married nodeg
global x_earn re74 re75

capture drop age2_gen re74_2 re75_2 u74 u75 re74_black re75_black

gen age2_gen   = age^2
gen re74_2     = re74^2
gen re75_2     = re75^2
gen u74        = re74 == 0
gen u75        = re75 == 0
gen re74_black = re74 * black
gen re75_black = re75 * black

global x_flex age age2_gen ed black hisp married nodeg re74 re75 re74_2 re75_2
global pscore_spec age age2_gen ed black hisp married nodeg re74 re75 re74_2 re75_2 u74 u75 re74_black re75_black

capture drop sample_exp sample_psid sample_cps

gen sample_exp  = exp == 1
gen sample_psid = (treat == 1 & exp == 1) | (psid == 1 & treat == 0)
gen sample_cps  = (treat == 1 & exp == 1) | (cps == 1 & treat == 0)

label var sample_exp  "Experimental NSW sample"
label var sample_psid "NSW treated + PSID controls"
label var sample_cps  "NSW treated + CPS controls"

/********************************************************************
3. PART A — MEANS BY SUBGROUP
********************************************************************/

preserve

gen nb = 1

collapse ///
    (mean) age ed black hisp married nodeg re74 re75 re78 ///
    (sum) nb, ///
    by(treat exp cps psid)

list, sepby(treat exp cps psid)

restore

/********************************************************************
4. PART B — OLS ESTIMATES
********************************************************************/

cap which esttab
if _rc ssc install estout, replace

eststo clear

reg $y treat if sample_exp == 1, robust
eststo NSW_B1

reg $y treat $x_basic if sample_exp == 1, robust
eststo NSW_B2

reg $y treat $x_basic $x_earn if sample_exp == 1, robust
eststo NSW_B3

reg $y treat $x_flex if sample_exp == 1, robust
eststo NSW_B4

reg $y treat if sample_psid == 1, robust
eststo PSID_B1

reg $y treat $x_basic if sample_psid == 1, robust
eststo PSID_B2

reg $y treat $x_basic $x_earn if sample_psid == 1, robust
eststo PSID_B3

reg $y treat $x_flex if sample_psid == 1, robust
eststo PSID_B4

reg $y treat if sample_cps == 1, robust
eststo CPS_B1

reg $y treat $x_basic if sample_cps == 1, robust
eststo CPS_B2

reg $y treat $x_basic $x_earn if sample_cps == 1, robust
eststo CPS_B3

reg $y treat $x_flex if sample_cps == 1, robust
eststo CPS_B4

esttab NSW_B1 NSW_B2 NSW_B3 NSW_B4 PSID_B1 PSID_B2 PSID_B3 PSID_B4 CPS_B1 CPS_B2 CPS_B3 CPS_B4, ///
    keep(treat) ///
    se ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("OLS treatment effect estimates") ///
    mtitles("NSW B1" "NSW B2" "NSW B3" "NSW B4" ///
            "PSID B1" "PSID B2" "PSID B3" "PSID B4" ///
            "CPS B1" "CPS B2" "CPS B3" "CPS B4")

/********************************************************************
5. INSTALL MATCHING PACKAGES
********************************************************************/

cap which psmatch2
if _rc ssc install psmatch2, replace

cap which pscore
if _rc ssc install pscore, replace

/********************************************************************
6. PSID SAMPLE — PROPENSITY SCORE MATCHING
********************************************************************/

preserve

keep if sample_psid == 1
keep if !missing(re78, treat, age, ed, black, hisp, married, nodeg, re74, re75)

capture drop pscore_psid

logit treat $pscore_spec
predict pscore_psid, pr

summarize pscore_psid if treat == 1
summarize pscore_psid if treat == 0

/********************************************************************
7. PROPENSITY SCORE DENSITIES — PSID
********************************************************************/

twoway ///
    (kdensity pscore_psid if treat == 1) ///
    (kdensity pscore_psid if treat == 0), ///
    legend(label(1 "NSW treated") label(2 "PSID controls")) ///
    title("Propensity Score Common Support: NSW Treated vs PSID Controls") ///
    xtitle("Estimated propensity score") ///
    ytitle("Density")

/********************************************************************
8. NEAREST-NEIGHBOR MATCHING — PSID
********************************************************************/

psmatch2 treat, ///
    outcome(re78) ///
    pscore(pscore_psid) ///
    neighbor(1) ///
    common

pstest $pscore_spec, both graph

/********************************************************************
9. ALTERNATIVE PROPENSITY SCORE SPECIFICATION — PSID
********************************************************************/

capture drop pscore_alt

logit treat age age2_gen ed black hisp married nodeg re74 re75 u74 u75
predict pscore_alt, pr

psmatch2 treat, ///
    outcome(re78) ///
    pscore(pscore_alt) ///
    neighbor(1) ///
    common

pstest age age2_gen ed black hisp married nodeg re74 re75 u74 u75, both graph

/********************************************************************
10. RADIUS MATCHING — PSID
********************************************************************/

psmatch2 treat, ///
    outcome(re78) ///
    pscore(pscore_psid) ///
    radius ///
    caliper(0.01) ///
    common

pstest $pscore_spec, both graph

/********************************************************************
11. KERNEL MATCHING — PSID
********************************************************************/

psmatch2 treat, ///
    outcome(re78) ///
    pscore(pscore_psid) ///
    kernel ///
    common

pstest $pscore_spec, both graph

/********************************************************************
12. MODERN STATA ROBUSTNESS — teffects psmatch
********************************************************************/

capture noisily teffects psmatch (re78) (treat $pscore_spec, logit), ///
    atet ///
    nn(1) ///
    vce(robust)

restore

/********************************************************************
13. CPS ROBUSTNESS SAMPLE
********************************************************************/

preserve

keep if sample_cps == 1
keep if !missing(re78, treat, age, ed, black, hisp, married, nodeg, re74, re75)

capture drop pscore_cps

logit treat $pscore_spec
predict pscore_cps, pr

twoway ///
    (kdensity pscore_cps if treat == 1) ///
    (kdensity pscore_cps if treat == 0), ///
    legend(label(1 "NSW treated") label(2 "CPS controls")) ///
    title("Propensity Score Common Support: NSW Treated vs CPS Controls") ///
    xtitle("Estimated propensity score") ///
    ytitle("Density")

/********************************************************************
14. NEAREST-NEIGHBOR MATCHING — CPS
********************************************************************/

psmatch2 treat, ///
    outcome(re78) ///
    pscore(pscore_cps) ///
    neighbor(1) ///
    common

pstest $pscore_spec, both graph

/********************************************************************
15. KERNEL MATCHING — CPS
********************************************************************/

psmatch2 treat, ///
    outcome(re78) ///
    pscore(pscore_cps) ///
    kernel ///
    common

pstest $pscore_spec, both graph

restore

/********************************************************************
16. INTERPRETATION NOTES

a) CPS/PSID controls are observational comparison groups and are very
   different from NSW treated units before adjustment.

b) OLS estimates in the experimental sample provide the benchmark.
   OLS estimates using PSID/CPS controls can be strongly biased.

c) Propensity score matching constructs comparison groups similar to
   treated units in observed covariates.

d) The ATT estimates the effect of training for NSW participants.

e) Balance is crucial: after matching, treated and control units should
   have similar observable characteristics.

f) Propensity score densities show common support. Limited overlap means
   estimates rely on extrapolation or weak comparisons.

g) Radius and kernel matching use more information than nearest-neighbor
   matching and can reduce variance, but may include poorer matches.

h) The key conclusion is whether matching recovers the experimental NSW
   benchmark better than naive OLS with CPS/PSID controls.
********************************************************************/
