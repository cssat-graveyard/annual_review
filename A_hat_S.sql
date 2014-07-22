declare @startyear int
declare @stopyear int
set @startyear = 2000
set @stopyear = 2013;

select
	id_prsn_child
	,isnull(
	datediff(dd,lf.legally_free_date,federal_discharge_date_force_18)
	,datediff(dd, lf.legally_free_date, datefromparts(@stopyear, 06, 30))
	) + 1 t
	,case
		when federal_discharge_date_force_18 is not null 
			and Federal_Discharge_Reason_Force = 'Adoption'
		then 1
		else 0
	end a
	,cd1.state_fiscal_yyyy fiscal_yr
from vw_legally_free lf
	join ca_ods.dbo.calendar_dim cd1
		on lf.legally_free_date = cd1.calendar_date 
where 
	cd1.state_fiscal_yyyy between @startyear and @stopyear