select  
	cd.d
	,cd.c
	,mc.e
	,mc.e*1000.0/cd.c M_d
	,mcf.e*1000.0/cd.c M_f_d
	,mck.e*1000.0/cd.c M_k_d
	,mcg.e*1000.0/cd.c M_g_d
	,cd.fiscal_yr
from 
	##care_day_count cd
	left join ##mobility_count mc
		on cd.fiscal_yr = mc.fiscal_yr
			and cd.d = mc.d
	join ##mobility_count_toFoster mcf
		on mc.fiscal_yr = mcf.fiscal_yr
			and mc.d = mcf.d
	join ##mobility_count_toKin mck
		on mc.fiscal_yr = mck.fiscal_yr
			and mc.d = mck.d
	join ##mobility_count_toGroup mcg
		on mc.fiscal_yr = mcg.fiscal_yr
			and mc.d = mcg.d
order by 
	fiscal_yr
	,d