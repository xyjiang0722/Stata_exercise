* Name: Xiaoyan Jiang
* START TIME: 1:13 PM, 11/11
cd "C:\Users\j\Desktop\Application\tasks\task1"
import delim visits.csv, clear

* reshape the data 
reshape long visit_ counts_ hcounts_, i(countycode date) j(name) string
rename (visit_ counts_ hcounts_) (visit counts hcounts)
drop if name=="bradley" | name=="buchanan"

describe

* label
label variable counts "Number of Articles"
label variable hcounts "Number of Articles (Headline)"
label define whether_visit 0 "No" 1 "Yes"
label values visit whether_visit
tab name
tab visit
su counts
su hcounts

* string date -> numeric date
gen date2 = date(date, "MDY")
format date2 %td

* generate id for each candidate at each county -> create a panel
egen id = group(countycode name)
su id   // max=364, 4 candidates * 91 counties

* set panel
xtset id date2   // delta: 1 day
xtdes
xtsum

* lagged visit
gen lag_visit = l1.visit   // 364 missing values generated, correct
label variable lag_visit "Whether visited the day before"
label values lag_visit whether_visit
drop if date2==td(01jan2000)

*************** Graphs ***************
* graph box counts hcounts, over(lag_visit) marker(1, msize(vsmall)) title("Whether the candidate visited the day before", size(medium)) legend(size(small)) note("") saving(box1, replace)
// not helpful, too many outside values

stripplot counts, over(lag_visit) box(blcolor(sandb) barwidth(0.5)) boffset(0.3) cumul cumprob centre vertical ceiling mc(navy%50) msize(tiny) mlw(thin) scheme(s1color) yla(, ang(h)) saving(stripplot_counts, replace)

stripplot hcounts, over(lag_visit) box(blcolor(sandb) barwidth(0.5)) boffset(0.3) cumul cumprob centre vertical ceiling mc(navy%50) msize(tiny) mlw(thin) scheme(s1color) yla(, ang(h)) saving(stripplot_hcounts, replace)

twoway (histogram counts, den w(4) by(lag_visit, note("") title("Distribution of the Number of Articles") subtitle("Whether the candidate visited the day before", size(small))) lcolor(gs10) fcolor(gs10) yla(, ang(h))) (histogram hcounts, den w(4) by(lag_visit) fcolor(none) lcolor(red)), legend(label(1 "Number of Articles") label(2 "Number of Articles (Headline)") size(small)) saving(hist, replace)
* kernel density not helpful, given a lot of zeros

* vioplot counts hcounts, over(lag_visit)   // not very useful, too many zeros


*************** Estimation ***************

/// 1. Simple Linear models ///

* baseline: no fixed effects
reg counts i.lag_visit, r

* Add fixed effects
reghdfe counts i.lag_visit, absorb(name) vce(robust)
est store lm2
reghdfe counts i.lag_visit, absorb(name state) vce(robust)
est store lm3
reghdfe counts i.lag_visit, absorb(name countycode) vce(robust)
est store lm4
reghdfe counts i.lag_visit, absorb(name countycode date) vce(robust)
est store lm5

est stat lm1 lm2 lm3 lm4 lm5
* lm5 best model based on AIC and BIC

est drop lm1 lm2 lm3 lm4 lm5

* add interaction terms
encode name, gen(n_name)
reghdfe counts i.lag_visit##i.n_name, absorb(countycode date) vce(robust)
testparm i.lag_visit#i.n_name   // significant


/// 2. Poisson Model ///
* baseline:
poisson counts i.lag_visit, r

poisson counts i.lag_visit##i.n_name i.countycode i.date2, r nocons
testparm i.n_name  // candidate fixed effects significant
testparm i.countycode  // county fixed effects significant
testparm i.date2  // date fixed effects significant
testparm i.lag_visit#i.n_name   // interaction terms significant (5% level)
est store pmod

* For a poisson model, use all the fixed effects and the interaction between visit and name


/// 3. xtreg with fe ///
* baseline:
xtreg counts i.lag_visit, fe vce(robust)

xtreg counts i.lag_visit##i.n_name i.date2, fe vce(robust)
testparm i.date2   // significant
testparm i.lag_visit#i.n_name   // significant
est store xtmod

* For a xtreg with fixed effects model, use date fixed effects and the interaction between visit and name


/// 4. xtpoisson with fe ///
* Baseline:
xtpoisson counts i.lag_visit, fe vce(robust)

xtpoisson counts i.lag_visit##i.n_name i.date2, fe vce(robust)
testparm i.date2   // significant
testparm i.lag_visit#i.n_name   // insignificant

* interaction for different parties
xtpoisson counts i.lag_visit##i.n_name i.date2 if name=="bush" | name=="cheney", fe vce(robust)
testparm i.lag_visit#i.n_name   // insignificant

xtpoisson counts i.lag_visit##i.n_name i.date2 if name=="gore" | name=="lieberman", fe vce(robust)
testparm i.lag_visit#i.n_name   // insignificant

xtpoisson counts i.lag_visit i.date2, fe vce(robust)
est store xtpmod

* For a xt poisson model, use date fixed effects and no interactions


/// 5. Zero-inflated Model ///
* Baseline:
zip counts i.lag_visit, inflate(i.lag_visit) r

zip counts i.lag_visit##i.n_name i.countycode i.date2, inflate(i.lag_visit) r nocons
testparm i.n_name  // significant
testparm i.countycode  // significant
testparm i.date2  // significant
testparm i.lag_visit#i.n_name  // interaction terms significant
est store zip

* For a zero-inflated poisson model, use all the fixed effects and the interaction between visit and name


/// 6. Model Comparison ///
* the basic linear model doesn't fit, not consider it

est stat pmod xtmod xtpmod zip
* choose the zip model based on AIC and BIC
* lrtest doesn't work: observations differ

est drop pmod xtmod xtpmod zip

* see whether parties have an effect
zip counts i.lag_visit##i.n_name i.countycode i.date2 if name=="bush" | name=="cheney", inflate(i.lag_visit) r nocons
testparm i.lag_visit#i.n_name   // insignificant

zip counts i.lag_visit##i.n_name i.countycode i.date2 if name=="gore" | name=="lieberman", inflate(i.lag_visit) r nocons
testparm i.lag_visit#i.n_name   // insignificant
* parties don't matter


/// 7. Final Model for counts ///
zip counts i.lag_visit##i.n_name i.countycode i.date2, inflate(i.lag_visit) r nocons
* lag_visit insignificant
* only Yes#cheney is significant

margins 1.lag_visit#2.n_name, noestimcheck   // margin=0.201


/// 8. Model for hcounts ///
* From the histogram, counts and hcounts have similar distributions, and hcounts have more zeros, so use zip for hcounts.

* same procedure
zip hcounts i.lag_visit, inflate(i.lag_visit) r

zip hcounts i.lag_visit##i.n_name i.countycode i.date2, inflate(i.lag_visit) r nocons
testparm i.n_name  // significant
testparm i.countycode  // significant
testparm i.date2  // significant
testparm i.lag_visit#i.n_name  // interaction terms significant

* lag_visit insignificant
* Yes#cheney and Yes#lieberman are significant

margins 1.lag_visit#2.n_name, noestimcheck   // margin=0, p value=0.98
margins 1.lag_visit#4.n_name, noestimcheck   // margin=0, p value=0.95
* very weak marginal effects, can be ignored

* no need to outreg, since the variable is simple


* END
* END TIME: 8:26 PM, 11/11, with breaks 3:00 PM - 4:30 PM, 6:00 PM - 7:00 PM
