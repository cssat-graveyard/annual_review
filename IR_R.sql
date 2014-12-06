declare @fystart int
declare @fystop int

set @fystart = 2007
set @fystop = 2013;

select
	count(*) I_R
	,P_H
	,state_fiscal_yyyy 
from calendar_dim cd
	join base.tbl_intakes intk
		on convert(date, intk.rfrd_date) = cd.calendar_date 
	join (select
				measurement_year
				,sum(pop_cnt) P_H
			from ca_ods.dbo.ref_lookup_census_population_poc2
			where cd_race < 8
			group by 
				measurement_year) pop
		on pop.measurement_year = state_fiscal_yyyy
where state_fiscal_yyyy between @fystart and @fystop 
group by 
	state_fiscal_yyyy
	,P_H
order by 
	state_fiscal_yyyy