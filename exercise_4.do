* Name: Xiaoyan Jiang

cd /nas/longleaf/home/xiaoyanj/Nov20/
import delim nlsy79-prepared.csv, clear

* string -> numeric
replace region="." if region=="NA"
destring region, replace
replace urban="." if urban=="NA"
destring urban, replace
replace wage="." if wage=="NA"
destring wage, replace
replace educ="." if educ=="NA"
destring educ, replace

* employment
gen emp = cond(wage,1,0,.)

*************************** Question 1 **************************
* focus on individuals for which there is information around the move.
preserve
drop if region==.
bysort i (year): gen lag_region = region[_n-1]
gen move_regions = (lag_region!=region) & (year!=1979)  // lag=. if year==1979
su move_regions if move_regions==1   // max = number of moves
collapse (mean) wage emp educ, by (region)
list
restore
* 8587 moved across regions 

* similar procedure for urban
preserve
drop if urban==.
bysort i (year): gen lag_urban = urban[_n-1]
gen move_urban = (lag_urban!=urban) & (year!=1979)
su move_urban if move_urban==1
collapse (mean) wage emp educ, by (urban)
list
restore
* 16437 moves between urban and non urban



************************* Question 2 *******************************
* three tempfiles
tempfile full region_moves urban_moves
save `full'

* region movers and create lagged/leading wage
preserve
drop if region==.
bysort i (year): gen lag_region = region[_n-1]
gen move_regions = (lag_region!=region) & (year!=1979)

by i: egen region_mover = max(move_regions)   // identify movers
keep if region_mover == 1   // select movers

bysort i (year): gen wage_l2 = wage[_n-2]
bysort i (year): gen wage_l1 = wage[_n-1]
bysort i (year): gen wage_f1 = wage[_n+1]
bysort i (year): gen wage_f2 = wage[_n+2]

save `region_moves'
restore

* same for urban/non-urban
preserve
drop if urban==.
bysort i (year): gen lag_urban = urban[_n-1]
gen move_urban = (lag_urban!=urban) & (year!=1979)

by i: egen urban_mover = max(move_urban)
keep if urban_mover == 1

bysort i (year): gen wage_l2 = wage[_n-2]
bysort i (year): gen wage_l1 = wage[_n-1]
bysort i (year): gen wage_f1 = wage[_n+1]
bysort i (year): gen wage_f2 = wage[_n+2]

save `urban_moves'
restore

********** Regions **********
use `region_moves', clear

*** overall
preserve
* select the observations where the respondent moved
keep if move_regions==1
* collapse to get the means; rename and reshape to create time series
collapse (mean) wage wage_l2 wage_l1 wage_f1 wage_f2
rename wage_l2 wage_1
rename wage_l1 wage_2
rename wage wage_3
rename wage_f1 wage_4
rename wage_f2 wage_5
gen fake_id = 1
reshape long wage_, i(fake_id) j(time)
* graph
replace wage_ = wage_/1000
label variable wage_ "Wage (in thousands)"
label variable time "Time"
scatter wage_ time, c(l) xlab(1 "-2" 2 "-1" 3 "0" 4 "1" 5 "2") xline(3) yla(, ang(h)) title("A window around the move across regions for wages (Overall)",size(small)) 
graph export region_overall.png, as(png) replace
restore

*** different directions of moving
* a number indicating the direction, e.g., 12 = moving from 1 to 2
gen move_regions_dir = lag_region*10 + region if move_regions!=.

* 12 cases, same procedure for each case 
foreach i in 12 13 14 21 23 24 31 32 34 41 42 43 {
	preserve
	keep if move_regions_dir==`i'
	collapse (mean) wage wage_l2 wage_l1 wage_f1 wage_f2
	rename wage_l2 wage_1
	rename wage_l1 wage_2
	rename wage wage_3
	rename wage_f1 wage_4
	rename wage_f2 wage_5
	gen fake_id = 1
	reshape long wage_, i(fake_id) j(time)
	replace wage_ = wage_/1000
	label variable wage_ "Wage (in thousands)"
	label variable time "Time"
	scatter wage_ time, c(l) xlab(1 "-2" 2 "-1" 3 "0" 4 "1" 5 "2", labsize(small)) xline(3) yla(5(5)20, ang(h) labsize(small)) title("`i'", size(medium)) msize(vsmall) xtitle(,size(small)) ytitle(,size(small)) saving(`i', replace)
	restore
}

* combine the graphs
gr combine 12.gph 13.gph 14.gph 21.gph 23.gph 24.gph 31.gph 32.gph 34.gph 41.gph 42.gph 43.gph, rows(4) sch(s1mono) graphregion(fcolor(white)) xsize(4) ycommon xcommon title("A window around the move across regions for wages" , size(small)) note("Note: The number ij in the title refers to the move from region i to region j.", size(vsmall))

graph export regions.png, as(png) replace


********** Urban **********
use `urban_moves', clear

*** overall
preserve
keep if move_urban==1
collapse (mean) wage wage_l2 wage_l1 wage_f1 wage_f2
rename wage_l2 wage_1
rename wage_l1 wage_2
rename wage wage_3
rename wage_f1 wage_4
rename wage_f2 wage_5
gen fake_id = 1
reshape long wage_, i(fake_id) j(time)
replace wage_ = wage_/1000
label variable wage_ "Wage (in thousands)"
label variable time "Time"
scatter wage_ time, c(l) xlab(1 "-2" 2 "-1" 3 "0" 4 "1" 5 "2") xline(3) yla(, ang(h)) title("A window around the move between urban and non-urban for wages (Overall)",size(small)) 
graph export urban_overall.png, as(png) replace
restore

*** different directions, e.g., 01 = from 0 to 1
gen move_urban_dir = lag_urban*10 + urban if move_urban!=.
gen str2 dir = string(move_urban_dir,"%02.0f")  // leading zero

foreach i in "01" "02" "10" "12"{
	preserve
	keep if dir=="`i'"
	collapse (mean) wage wage_l2 wage_l1 wage_f1 wage_f2
	rename wage_l2 wage_1
	rename wage_l1 wage_2
	rename wage wage_3
	rename wage_f1 wage_4
	rename wage_f2 wage_5
	gen fake_id = 1
	reshape long wage_, i(fake_id) j(time)
	replace wage_ = wage_/1000
	label variable wage_ "Wage (in thousands)"
	label variable time "Time"
	scatter wage_ time, c(l) xlab(1 "-2" 2 "-1" 3 "0" 4 "1" 5 "2", labsize(small)) xline(3) yla(15(5)30, ang(h) labsize(small)) title("`i'", size(medium)) msize(vsmall) xtitle(,size(small)) ytitle(,size(small)) saving(`i', replace)
	restore
}

gr combine 01.gph 02.gph 10.gph 12.gph, rows(3) sch(s1mono) graphregion(fcolor(white)) xsize(4) ycommon xcommon title("A window around the move between urban and non-urban for wages" , size(small)) note("Note: The number ij in the title refers to the move from urban i to urban j." "The cases of moving from urban 2 to other areas are left out due to limited sample size.", size(vsmall))

graph export urban.png, as(png) replace



****************************** Question 3 ********************************
use `full', clear

drop if region==. 

bysort i (year): gen lag_region = region[_n-1]
gen move = (lag_region!=region) & (year!=1979)   // binary indicator for moving


*** 7-year interval ***
forvalues i = 1982(1)1987 {
	preserve
	keep if year>=`i'-3 & year<=`i'+3   // 7-year interval
	by i: egen num_moves = total(move)
	drop if num_moves>=2   // drop those who moved more than once
	gen move_`i' = (move==1 & year==`i')   // move_year indicator
	by i: egen treat = max(move_`i') if year >= `i'  
	replace treat = 0 if treat==.   // treatment variable (=1 after moving)
	tab year treat
	
	* DiD model
	gen did = year*treat
	label variable did "Diff-in-Diff"
	qui reg wage year i.treat did i.birth i.educ i.gender, r
	outreg2 using table1.doc, ctitle("`i'") se label bdec(2) sdec(2) keep(did) nocons nor2 append
	restore
}

* break it here for the format of the table
forvalues i = 1988(1)1994 {
	preserve
	keep if year>=`i'-3 & year<=`i'+3
	by i: egen num_moves = total(move)
	drop if num_moves>=2
	gen move_`i' = (move==1 & year==`i')
	by i: egen treat = max(move_`i') if year >= `i'
	replace treat = 0 if treat==.
	tab year treat

	gen did = year*treat
	label variable did "Diff-in-Diff"
	qui reg wage year i.treat did i.birth i.educ i.gender, r
	outreg2 using table2.doc, ctitle("`i'") se label bdec(2) sdec(2) keep(did) nocons nor2 append
	restore
}

forvalues i = 1996(2)2008 {
	preserve
	keep if year>=`i'-3 & year<=`i'+3
	by i: egen num_moves = total(move)
	drop if num_moves>=2
	gen move_`i' = (move==1 & year==`i')
	by i: egen treat = max(move_`i') if year >= `i'
	replace treat = 0 if treat==.
	tab year treat

	gen did = year*treat
	label variable did "Diff-in-Diff"
	qui reg wage year i.treat did i.birth i.educ i.gender, r
	outreg2 using table3.doc, ctitle("`i'") se label bdec(2) sdec(2) keep(did) nocons nor2 append
	restore
}


*** 11-year interval ***
forvalues i = 1984(1)1994 {
	preserve
	keep if year>=`i'-5 & year<=`i'+5   // 11-year interval
	by i: egen num_moves = total(move)
	drop if num_moves>=2   // drop those who moved more than once
	gen move_`i' = (move==1 & year==`i')   // move_year indicator
	by i: egen treat = max(move_`i') if year >= `i'  
	replace treat = 0 if treat==.   // treatment variable (=1 after moving)
	tab year treat
	
	* DiD model
	gen did = year*treat
	label variable did "Diff-in-Diff"
	qui reg wage year i.treat did i.birth i.educ i.gender, r
	outreg2 using table4.doc, ctitle("`i'") se label bdec(2) sdec(2) keep(did) nocons nor2 append
	restore
}

forvalues i = 1996(2)2006 {
	preserve
	keep if year>=`i'-5 & year<=`i'+5
	by i: egen num_moves = total(move)
	drop if num_moves>=2
	gen move_`i' = (move==1 & year==`i')
	by i: egen treat = max(move_`i') if year >= `i'
	replace treat = 0 if treat==.
	tab year treat

	gen did = year*treat
	label variable did "Diff-in-Diff"
	qui reg wage year i.treat did i.birth i.educ i.gender, r
	outreg2 using table5.doc, ctitle("`i'") se label bdec(2) sdec(2) keep(did) nocons nor2 append
	restore
}


*** 5-year interval ***
forvalues i = 1981(1)1987 {
	preserve
	keep if year>=`i'-2 & year<=`i'+2   // 5-year interval
	by i: egen num_moves = total(move)
	drop if num_moves>=2   // drop those who moved more than once
	gen move_`i' = (move==1 & year==`i')   // move_year indicator
	by i: egen treat = max(move_`i') if year >= `i'  
	replace treat = 0 if treat==.   // treatment variable (=1 after moving)
	tab year treat
	
	* DiD model
	gen did = year*treat
	label variable did "Diff-in-Diff"
	qui reg wage year i.treat did i.birth i.educ i.gender, r
	outreg2 using table6.doc, ctitle("`i'") se label bdec(2) sdec(2) keep(did) nocons nor2 append
	restore
}

* break it here for the format of the table
forvalues i = 1988(1)1994 {
	preserve
	keep if year>=`i'-2 & year<=`i'+2
	by i: egen num_moves = total(move)
	drop if num_moves>=2
	gen move_`i' = (move==1 & year==`i')
	by i: egen treat = max(move_`i') if year >= `i'
	replace treat = 0 if treat==.
	tab year treat

	gen did = year*treat
	label variable did "Diff-in-Diff"
	qui reg wage year i.treat did i.birth i.educ i.gender, r
	outreg2 using table7.doc, ctitle("`i'") se label bdec(2) sdec(2) keep(did) nocons nor2 append
	restore
}

forvalues i = 1996(2)2010 {
	preserve
	keep if year>=`i'-2 & year<=`i'+2
	by i: egen num_moves = total(move)
	drop if num_moves>=2
	gen move_`i' = (move==1 & year==`i')
	by i: egen treat = max(move_`i') if year >= `i'
	replace treat = 0 if treat==.
	tab year treat

	gen did = year*treat
	label variable did "Diff-in-Diff"
	qui reg wage year i.treat did i.birth i.educ i.gender, r
	outreg2 using table8.doc, ctitle("`i'") se label bdec(2) sdec(2) keep(did) nocons nor2 append
	restore
}

save final_data, replace
* END


