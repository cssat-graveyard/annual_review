select
	sum(care_days) c
	,sum(substantiated_allegations) FCI_F
	,sum(substantiated_allegations)*100000.0/sum(care_days) FCFR
	,cd.fiscal_yr
from ##care_days cd
	join ##substantiations s
		on cd.id_calendar_dim = s.id_calendar_dim
group by 
	cd.fiscal_yr
order by 
	cd.fiscal_yr