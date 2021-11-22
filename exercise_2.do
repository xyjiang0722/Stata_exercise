* Name: Xiaoyan Jiang
* START TIME: 2:11 PM, 11/08
cd "C:\Users\j\Desktop\Application\tasks\task2"
import delim newspapers.txt, delimiters(tab) clear

di _N   // 10773 observations, so there should be 10773 obs in the final dataset

* check the number of newspapers
preserve
gen order = _n
sort membernumber order
by membernumber: gen count = _n == 1
sort order
replace count = sum(count)
su count
restore
* 1047 newspapers


* Part 1: construct the master dataset

* pick out the headquarters
sort membernumber
by membernumber: egen max_circ = max(dailycirc)
drop if dailycirc != max_circ
di _N  // 1047 rows, i.e., no newspaper has two headquarters

keep membernumber stcntyfp cnty state   // membernumber as the merge ID
rename stcntyfp stcntyfp_1
label variable stcntyfp_1 "County 1’s ID number"
rename cnty cnty_1
label variable cnty_1 "County 1’s name"
rename state state_1
label variable state_1 "County 1’s state postal code"

save headquarters.dta, replace


* Part 2: construct the using dataset
import delim newspapers.txt, delimiters(tab) clear

keep membernumber stcntyfp cnty state dailycirc
sort membernumber

rename stcntyfp stcntyfp_2
label variable stcntyfp_2 "County 2’s ID number"
rename cnty cnty_2
label variable cnty_2 "County 2’s name"
rename state state_2
label variable state_2 "County 2’s state postal code"
label variable dailycirc "Total circulation of newspapers from county 1 in county 2"

save all.dta, replace


* Part 3: merge
use headquarters.dta, clear

merge 1:m membernumber using all.dta   // matched: 10733
drop membernumber _merge
save final.dta, replace

* END
* END TIME: 2:53 PM, 11/08









