* Empirical Project 2

* Question 2
use cps_1970
gen year=1970
save cps_1970a, replace
clear

use cps_1975
gen year=1975
save cps_1975a, replace
clear

use cps_1980
gen year=1980
save cps_1980a, replace
clear

use cps_1985
gen year=1985
save cps_1985a, replace
clear

use cps_1990
gen year=1990
save cps_1990a, replace
clear

use cps_1995
gen year=1995
save cps_1995a, replace
clear

use cps_2000
gen year=2000
save cps_2000a, replace
clear

use cps_2005
gen year=2005
save cps_2005a, replace
clear

use cps_2010
gen year=2010
save cps_2010a, replace
clear

use cps_2015
gen year=2015
save cps_2015a, replace
clear

* Question 3
use cps_1970a 
append using cps_1975a cps_1980a cps_1985a cps_1990a cps_1995a cps_2000a cps_2005a cps_2010a cps_2015a

save project2, replace
clear

* Question 4
use project2

ssc install reghdfe 
ssc install ranktest
ssc install ftools

* indicator for black respondents
gen black = 1 if race == "Black"
replace black = 0 if black == .

* indicator for other race respondents
gen other_race = 1 if (race == "Other Race")
replace other_race = 0 if other_race == .
tab race other_race 

* indicator for female respondents
gen female = (sex == 2)

* indicator for married, spouse present respondents
gen m_present = (marst == 1)

* age squared
gen age_sq = age^2

* indicator: high school degree only
gen only_hs = (educ == "H.S. Degree" )

* indicator for some college
gen scol = (educ == "Some College")

* indicator for BA degree
gen col_ba = (educ == "BA Degree")

*indicator for BA or more
gen ba_plus = (educ == "BA Degree" | educ == "MA or Higher")

*indicator for MA or higher
gen col_ma = (educ == "MA or Higher")

* restrict to under age of 65
drop if age >= 65



* Question 5 
gen cpi = .
replace cpi = 38.8 if year == 1970
replace cpi = 53.8 if year == 1975
replace cpi = 82.4 if year == 1980
replace cpi = 107.6 if year == 1985
replace cpi = 130.7 if year == 1990
replace cpi = 152.4 if year == 1995
replace cpi = 172.2 if year == 2000
replace cpi = 195.3 if year == 2005
replace cpi = 218.1 if year == 2010
replace cpi = 237.0 if year == 2015

* cpi base year using 2015 
gen cpi_base = 237.0
gen realwage = wage * (cpi_base / cpi)

label var realwage "Wage adjusted to 2015 dollars"

* Question 6
*table 
summarize realwage black other_race female m_present age_sq only_hs scol col_ba ba_plus col_ma

*male column
summarize realwage black other_race female m_present age_sq only_hs scol col_ba ba_plus col_ma if female == 0 

*female column
summarize realwage black other_race female m_present age_sq only_hs scol col_ba ba_plus col_ma if female == 1

*export ???? see if we need to use outreg 2 or can copy table into excel
outreg2 using q6table.doc, replace sum(log) ///
keep (realwage black other_race female m_present age_sq only_hs scol col_ba ba_plus col_ma) ///
ctitle ("All""Male""Female") dec(3)

* Question 7
local controls black other_race m_present female age age_sq

*log of real wages
gen ln_realwage = ln(realwage)
label var ln_realwage "Log of real wage in 2015"

*regression
reghdfe ln_realwage only_hs scol ba_plus `controls', absorb(year) vce(robust)

* for table
*all
reghdfe ln_realwage only_hs scol ba_plus `controls', absorb(year) vce(robust)
est store all

*male
reghdfe ln_realwage only_hs scol ba_plus `controls' fe if female == 0 , absorb(year) vce(robust)
est store male

*female
reghdfe ln_realwage only_hs scol ba_plus `controls' fe if female == 1, absorb(year) vce(robust)
est store female

outreg2 [all male female] using q7table.doc, replace ///
    ctitle("All" "Male" "Female") ///
    label dec(3) ///


* Question 8 
gen trend = .
replace trend = 0 if year == 1970
replace trend = 1 if year == 1975
replace trend = 2 if year == 1980
replace trend = 3 if year == 1985
replace trend = 4 if year == 1990
replace trend = 5 if year == 1995
replace trend = 6 if year == 2000
replace trend = 7 if year == 2005
replace trend = 8 if year == 2010
replace trend = 9 if year == 2015

label var trend "Linear time trend"

gen ba_plus_trend = ba_plus * trend
label var ba_plus_trend "BA or higher * trend"

* regression
reghdfe ln_realwage ba_plus ba_plus_trend `controls', absorb(year) vce(robust)
est store all

* male
reghdfe ln_realwage ba_plus ba_plus_trend `controls' if female== 0, absorb(year) vce(robust)
est store male

* female
reghdfe ln_realwage ba_plus ba_plus_trend `controls' if female== 1, absorb(year) vce(robust)
est store female

outreg2 [all male female] using q8table.doc, replace ///
    ctitle("All" "Male" "Female") ///
    label dec(3) ///

* Question 9
reghdfe ln_realwage ba_plus ba_plus_trend `controls' fe, absorb(year)

gen return=_b[ba_plus]+_b[ba_plus_trend]*trend

preserve
keep year return
sort year
qui by year: gen obs=_n
drop if obs>1
drop obs

twoway (scatter return year), ytitle(Return to a College Degree) xtitle(Year) xlabel(1970(5)2015)
graph export returns.tif, replace

restore

* Question 10
gen hs_trend = only_hs * trend
gen scol_trend = scol * trend
gen ba_trend = col_ba * trend
gen ma_trend = col_ma * trend 

* for all
reghdfe ln_realwage only_hs scol col_ba col_ma ///
        hs_trend scol_trend ba_trend ma_trend ///
        `controls' fe, absorb(year)
est store all

*for male
reghdfe ln_realwage only_hs scol col_ba col_ma ///
        hs_trend scol_trend ba_trend ma_trend ///
        `controls' fe if female == 0, absorb(year)
est store male

*for female
reghdfe ln_realwage only_hs scol col_ba col_ma ///
        hs_trend scol_trend ba_trend ma_trend ///
        `controls' fe if female == 1, absorb(year)
est store female

*table
outreg2 [all male female] using q10table.doc, replace ///
    ctitle("All" "Male" "Female") ///
    label dec(3) ///
    keep(only_hs scol col_ba col_ma hs_trend scol_trend ba_trend ma_trend)
	

*Question 11
gen hs_return = _b[only_hs] + _b[hs_trend]*trend
gen scol_return = _b[scol] + _b[scol_trend]*trend
gen ba_return = _b[col_ba] + _b[ba_trend]*trend
gen ma_return = _b[col_ma] + _b[ma_trend]*trend

preserve
keep year hs_return scol_return ba_return ma_return
bysort year: keep if _n == 1

*table 
keep if year == 1970 | year == 2015

gen hs_return_pct   = (exp(hs_return)   - 1) * 100
gen scol_return_pct = (exp(scol_return) - 1) * 100
gen ba_return_pct   = (exp(ba_return)   - 1) * 100
gen ma_return_pct   = (exp(ma_return)   - 1) * 100

summarize hs_return_pct if year == 1970, meanonly
scalar hs1970 = r(mean)
summarize hs_return_pct if year == 2015, meanonly
scalar hs2015 = r(mean)

summarize scol_return_pct if year == 1970, meanonly
scalar scol1970 = r(mean)
summarize scol_return_pct if year == 2015, meanonly
scalar scol2015 = r(mean)

summarize ba_return_pct if year == 1970, meanonly
scalar ba1970 = r(mean)
summarize ba_return_pct if year == 2015, meanonly
scalar ba2015 = r(mean)

summarize ma_return_pct if year == 1970, meanonly
scalar ma1970 = r(mean)
summarize ma_return_pct if year == 2015, meanonly
scalar ma2015 = r(mean)


matrix R = J(4,3,.)
matrix rownames R = "High School" "Some College" "BA Degree" "MA or More"
matrix colnames R = "Return_1970(%)" "Return_2015(%)" "Change(%)"

matrix R[1,1] = hs1970
matrix R[1,2] = hs2015
matrix R[1,3] = hs2015 - hs1970
matrix R[2,1] = scol1970
matrix R[2,2] = scol2015
matrix R[2,3] = scol2015 - scol1970
matrix R[3,1] = ba1970
matrix R[3,2] = ba2015
matrix R[3,3] = ba2015 - ba1970
matrix R[4,1] = ma1970
matrix R[4,2] = ma2015
matrix R[4,3] = ma2015 - ma1970


clear
svmat R

rename R1 Return_1970
rename R2 Return_2015
rename R3 Change

gen Education = ""
replace Education = "High School"   in 1
replace Education = "Some College"  in 2
replace Education = "BA Degree"     in 3
replace Education = "MA or More"    in 4
order Education Return_1970 Return_2015 Change

outreg2 using q11table.doc, replace ///
    title("Returns to Education (Percent): 1970 vs 2015") ///
    keep(Education Return_1970 Return_2015 Change) ///
    dec(2) label

export excel using "q11table.xlsx", firstrow(variables) replace




