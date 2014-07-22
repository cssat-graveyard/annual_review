declare @fystart int
declare @fystop int

set @fystart = 2010
set @fystop = 2013;

select
	count(*) I_P
	,P_C
	,count(*)*100000.00/P_C IR_P
	,month
from ca_ods.dbo.calendar_dim cd
	join ca_ods.base.rptPlacement rp
	  on rp.removal_dt = cd.calendar_date
	join (select
				measurement_year
				,sum(pop_cnt) P_C
			from ca_ods.dbo.ref_lookup_census_population
			where cd_race < 8
			group by 
				measurement_year) pop
		on pop.measurement_year = year(cd.month)  
where state_fiscal_yyyy between @fystart and @fystop 
group by 
	month
	,P_C
order by 
	month