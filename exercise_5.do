use Noto_data_task.dta, clear

* examining the data
desc
list year clphsg_all eu_lnclg

* 1.
gen t = year-1962

* detrended wage series: redisuals from the regression of relative wage 
reg clphsg_all t
predict wage_resid, resid
label variable wage_resid "Detrended Wage Differential"

* detrended supply: redisuals from the regression of supply
reg eu_lnclg t
predict sup_resid, resid
label variable sup_resid "Detrended Relative Supply"

* Plot figure 4 panel A
scatter wage_resid sup_resid year, c(1 1) lpattern(1 _) msymbol(oh dh) yline(0) ///
title("A. Detrended College-High School Wage Differential and Relative Supply, 1963-2008", size(small)) ///
xtitle("") xlabel(1963(6)2008) ytitle("Log Points") ylabel(-.15(.05).15) ///
legend(region(lstyle(none))) legend(size(small)) ///
saving("detrended wage supply.png", replace)

*1963-87 Regressions and Predictions ;
reg clphsg_all t eu_lnclg if year <= 1987
predict gap_pred
label variable gap_pred "Katz-Murphy Predicted Wage Gap: 1963-1987 Trend"
label variable clphsg_all "Observed CLG/HS Gap"

* Plot figure 4 panel B
scatter clphsg_all gap_pred year, c(l l) lpattern(1 _) msymbol (oh dh) ///
ti("B. Katz-Murphy Prediction Model for the College-High School Wage Gap", size(small)) ///
xtitle("") xlabel(1963(6)2008) xline(1987 1992) ytitle("Log Wage Gap") ylabel(.35(.1).75) ///
legend(region(lstyle(none))) legend(size(vsmall)) ///
saving("km wage gap.png", replace)



* 2.
gen t_sq= t^2 /100
gen t_cu= t^3 /1000
gen t_post92 = max(year-1992,0)

label variable t "Time"
label variable t_sq "Time2/100"
label variable t_cu "Time3/1000"
label variable t_post92 "Time post-1992"
label variable eu_lnclg "CLG/HS relative supply"

* regress and post results
reg clphsg_all eu_lnclg t if year<=1987
* append statistics for the elasticity of substitution
scalar e_sub = 1/e(b)[1,1]
scalar p_value = r(table)[4,1]
outreg2 eu_lnclg t using table2.doc, ctitle("1963-1987") se label bdec(3) sdec(3) pdec(3) noaster adds("Elasticity of substitution", e_sub, "se", _se[eu_lnclg], "p value", p_value) replace

reg clphsg_all eu_lnclg t
scalar e_sub = 1/e(b)[1,1]
scalar p_value = r(table)[4,1]
outreg2 eu_lnclg t using table2.doc, ctitle(" ") se label bdec(3) sdec(3) pdec(3) noaster adds("Elasticity of substitution", e_sub, "se", _se[eu_lnclg], "p value", p_value) append

reg clphsg_all eu_lnclg t t_post92
scalar e_sub = 1/e(b)[1,1]
scalar p_value = r(table)[4,1]
outreg2 eu_lnclg t using table2.doc, ctitle(" ") se label bdec(3) sdec(3) pdec(3) noaster adds("Elasticity of substitution", e_sub, "se", _se[eu_lnclg], "p value", p_value) append

reg clphsg_all eu_lnclg t t_sq
scalar e_sub = 1/e(b)[1,1]
scalar p_value = r(table)[4,1]
outreg2 eu_lnclg t using table2.doc, ctitle(" ") se label bdec(3) sdec(3) pdec(3) noaster adds("Elasticity of substitution", e_sub, "se", _se[eu_lnclg], "p value", p_value) append

reg clphsg_all eu_lnclg t t_sq t_cu
scalar e_sub = 1/e(b)[1,1]
scalar p_value = r(table)[4,1]
outreg2 eu_lnclg t using table2.doc, ctitle("1963-2008") se label bdec(3) sdec(3) pdec(3) noaster adds("Elasticity of substitution", e_sub, "se", _se[eu_lnclg], "p value", p_value) append


* 3.
* loop through the breaks (1964 - 2007)
forvalues break = 1964/2007 {
	* generate post_break variables and run regression
	qui gen t_post_`break' = max(year -`break', 0)
	qui reg clphsg_all eu_lnclg t t_post_`break'
	* create a matrix that records the break year and corresponding r-squared
	matrix break_r2 = (`break', e(r2))
	if `break'==1964 matrix r_sq = break_r2
	else matrix r_sq = (r_sq \ break_r2)
	* drop the break variable and then loop again
	drop t_post_`break'
}
matrix list r_sq

* use mata to find the maximum r-squared
mata
r_sq = st_matrix("r_sq")
select((1::rows(r_sq)), (r_sq[,2] :== colmax(r_sq[,2])))
end
