clear all
set more off 
global datadir "D:/GDrive/Lain Lain/Annisa/" 

* Creating a Log File
log using log_reg_ina.smcl, replace

*Importing the data
import excel "$datadir/data_fp.xls", sheet("data") firstrow
save "$datadir/data_fp.dta", replace

* Calling the Dataset
use "$datadir/data_fp.dta", clear

*Setting for a time series
tsset periode, monthly

* Generating some Variables - 1st equation
gen lnM2=ln(m2)
gen lnEM=ln(em)
gen lnCC=ln(cc)
gen lnDC=ln(dc)
gen BIrate=birate
gen lnEXCrate=ln(excrate)
gen INF=inf

* Generating some Variables - 2nd equation
generate M2Growth=m2_g

* Generating some Variables - 3rd equation
generate NGDPGrowth=ngdp_g

* Generating some Variables - 4th equation
generate NGDPoM2=ngdp/m2

* Global
global depvar1 lnM2
global depvar2 M2Growth
global depvar3 M2Growth
global depvar4 NGDPoM2
global indvar1 lnEM lnCC lnDC BIrate lnEXCrate INF
global indvar2 $indvar1
global indvar3 $indvar1 NGDPGrowth
global indvar4 lnEM lnCC lnDC

* Drop Missing Variables
drop if excrate_g == .

* A. Ordinary Least Square (OLS)
quietly reg $depvar1 $indvar1
estimates store Model1

quietly reg $depvar2 $indvar2
estimates store Model2

quietly reg $depvar3 $indvar3
estimates store Model3

quietly reg $depvar4 $indvar4
estimates store Model4

estout Model1 Model2 Model3 Model4, cells(b(star fmt(7)) t(par fmt(7))) stats(r2 r2_a p N)

* B. Descriptive Statistics
sum ngdp rgdp m1 m2 em dc cc inf birate excrate

* C. Classical Assumption Test

* C.1. Normality Test
** If the p-value is lower than the Chi(2) value then the null hypothesis cannot be rejected. Therefore residuals are normality distributed
** Comment: The Data is Normally Distributed
predict resid, residuals
jb resid

* C.2. Autocorrelation
** If the Durbin–Watson d statistic is far from the centre of its distribution (E(d) = 2.0). Assuming that dependent variable is strictly exogenous, we can reject the null of no first-order serial correlation.
** Comment: No Serial Correlation
estat dwatson

* C.3. Multicollinearity
** If VIF is greater than 10 roughly indicates significant multicollinearity
** Comment: No multicollinearity
estat vif

* C.4. Heteroskedasticity
** The Null Hypothesis (H0) is the regression have a Constant variance or Homokedastic. Thus, if the p-value below 5%, it means we reject the The Null Hypothesis.
** Comment: We have problem with heteroskedasticity 
*** Solution: We have to re-run regression in model 4 with vce (robust) option
estat hettest

quietly reg $depvar4 $indvar4, vce(robust)
estimates store Model4Robust

estout Model1 Model2 Model3 Model4 Model4Robust, cells(b(star fmt(7)) t(par fmt(7))) stats(r2 r2_a p N)
esttab Model1 Model2 Model3 Model4 Model4Robust using "$datadir/regoutput.csv", replace

* Closing the Log File
log close
translator query smcl2pdf
translator set smcl2pdf fontsize 8 
translate log_reg_ina.smcl log_reg_ina.pdf

