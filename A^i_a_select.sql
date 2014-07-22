select
	cd.fiscal_yr
	,iif(a3.i >= 4, 4, a3.i) i
	,sum(a3.awol_days15to17) awol_ttl_15to17
	,sum(a3.awol_days15to17)*1000.0/sum(care_days_15to17) 'A_i_15to17'
	,sum(a2.awol_days12to14) awol_ttl_12to14
	,sum(a2.awol_days12to14)*1000.0/sum(care_days_12to14) 'A_i_12to14'
	,sum(a1.awol_days9to11) awol_ttl_9to11
	,sum(a1.awol_days9to11)*1000.0/sum(care_days_9to11) 'A_i_9to11'
from ##care_days15to17 cd
	left join ##awoldays15to17 a3
		on cd.id_calendar_dim = a3.id_calendar_dim
	left join ##care_days12to14 cd2
		on cd2.id_calendar_dim = cd.id_calendar_dim
	left join ##awoldays12to14 a2
		on a3.id_calendar_dim = a2.id_calendar_dim
			and a3.i = a2.i
	left join ##care_days9to11 cd3
		on cd3.id_calendar_dim = cd.id_calendar_dim
	left join ##awoldays9to11 a1
		on a3.id_calendar_dim = a1.id_calendar_dim
			and a3.i = a1.i
group by 
	cd.fiscal_yr
	,iif(a3.i >= 4, 4, a3.i)
order by 
	cd.fiscal_yr,iif(a3.i >= 4, 4, a3.i)

