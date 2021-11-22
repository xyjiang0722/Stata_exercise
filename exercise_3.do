clear all
cd /nas/longleaf/home/xiaoyanj/swb

******************
*** Question 1 ***
******************
import delim ratings.csv, clear

* (a).

* use preserve and restore to avoid changing the dataset
preserve

* generate order numbers for each observation
gen order = _n
* sort first by worker and then by order
sort worker order
* generate count = 1 for every first observation in the group
by worker: gen count = _n == 1
* sort by order and then sum the count
sort order
replace count = sum(count)
* the maximum of count is the number of unique observations
su count

restore

* the same procedure for aspect
preserve

gen order = _n
sort aspect order
by aspect: gen count = _n == 1
sort order
replace count = sum(count)
su count

restore

* (b).

* sort by worker, then aspect, and then time (so the most recent observation will be the second if there's duplication)
sort worker aspect time
* generate dup = 0 if the total number of observations within each group is 1, else dup = the time of occurence
qui by worker aspect: gen dup = cond(_N==1, 0, _n)

tab dup

* drop the old observation
drop if dup == 1

* report the average time
su time
scalar mean_time = r(mean)
display %15.0g mean_time

drop dup

* (c).

sort worker

* collaspe the data by worker
collapse (mean) rating, by(worker)

su rating, detail

save mean_ratings.dta 

******************
*** Question 2 ***
******************
import delim demographics.csv, clear

* (a).

* total numder of observations = _N
di _N

* (b).

sort worker
merge 1:1 worker using "mean_ratings.dta"

* Same procedure as Question 1 (a)
preserve
gen order = _n
sort worker order
by worker: gen count = _n == 1
sort order
replace count = sum(count)
su count
restore

di _N

* (c).
reg rating income

* (d).

gen age_2 = age^2
encode education, gen(nedu)
encode race, gen(nrace)

reg rating income age age_2 i.male i.nedu i.nrace

testparm age age_2 i.male i.nedu i.nrace

******************
*** Question 3 ***
******************

* Any individual/average rating data in the plot should be for aspects related to health, so redo 1
import delim ratings.csv, clear

* drop duplicated observations
sort worker aspect time
qui by worker aspect: gen dup = cond(_N==1, 0, _n)
drop if dup == 1
drop dup

* I use the following aspects as proxies for health (both physical and mental)
* I choose 2 aspects for physical health and 2 aspects for mental health to avoid one overwhelming the other 
keep if aspect == "your health" | aspect == "your mental health" | aspect == "your physical fitness" | aspect == "how happy you feel"

* collaspe and then save
sort worker
collapse (mean) rating, by(worker)
save mean_health_ratings.dta

* merge datasets
import delim demographics.csv, clear
sort worker
merge 1:1 worker using "mean_health_ratings.dta"


sort income
sum income, detail
sum age, detail

* create 20 income categories by quantile
xtile quart = income, nq(20)

* see what income range each quantile corresponds to 
forvalues i = 1/20 {
  di `i'
  su income if quart==`i'
} 

* replace the quantiles by income
gen inc_category = quart
qui replace inc_category = 10 if inc_category==1
qui replace inc_category = 30 if inc_category==3
qui replace inc_category = 50 if inc_category==8
qui replace inc_category = 70 if inc_category==13
qui replace inc_category = 90 if inc_category==16
qui replace inc_category = 108 if inc_category==18
qui replace inc_category = 125 if inc_category==19
qui replace inc_category = 167 if inc_category==20
tab inc_category

* create 4 age categories
gen age_category = 0
forvalues i = 1/`=_N' {
    qui replace age_category = 1 if age<30 in `i'
    qui replace age_category = 2 if age>=30 & age<=39 in `i'
    qui replace age_category = 3 if age>=40 & age<=54 in `i'
    qui replace age_category = 4 if age>=55 in `i'
}
tab age_category

collapse (mean) rating, by (inc_category age_category) 

twoway (scatter rating inc_category if age_category==1, c(l) lp(1) lc(blue) m(o) msize(small)) ///
(scatter rating inc_category if age_category==2, c(l) lp(_) lc(green) m(d) msize(small)) ///
(scatter rating inc_category if age_category==3, c(l) lp(-) lc(red) m(s) msize(small)) ///
(scatter rating inc_category if age_category==4, c(l) lp(-.) lc(brown) m(t) msize(small)), ///
xtitle("Income (thousands)", size(medium)) ytitle("Subjective Ratings of Health") ///
graphregion(fcolor(white)) legend(region(lcolor(white)) order(1 "Age: 19-29" 2 "Age: 30-39" 3 "Age: 40-54" 4 "Age: 55-75")) ///
saving("health ratings.gph", replace)

* END

