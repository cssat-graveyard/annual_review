declare @fystart int
declare @fystop int

set @fystart = 2010
set @fystop = 2013;

select
	count(*) I_R
	,P_H
	,count(*)*1000.0/P_H IR_R
	,month calendar_month 
from ca_ods.dbo.calendar_dim cd
	join ca_ods.base.tbl_intakes  ti
		on ti.inv_ass_start = cd.calendar_date
	join (select
				measurement_year
				,sum(pop_cnt) P_H
			from ca_ods.dbo.ref_lookup_census_population_poc2
			where cd_race < 8
			group by 
				measurement_year) pop
		on pop.measurement_year = year(cd.calendar_date) 
where state_fiscal_yyyy between @fystart and @fystop 
		and cd_access_type in (1, 4)
		and intake_rank = 1
group by 
	month
	,P_H