declare @startyear int
declare @stopyear int
set @startyear = 2000
set @stopyear = 2013;

select
	child id_prsn_child
	,case 
		when rp.removal_dt between datefromparts(yrs.year_yyyy-1,07,01) 
								and datefromparts(yrs.year_yyyy,06,30)
		then datediff(dd, removal_dt, datefromparts(yrs.year_yyyy, 06, 30))
		when rp.discharge_dt <= datefromparts(yrs.year_yyyy, 06, 30)
		then datediff(dd, datefromparts(yrs.year_yyyy-1,07,01), rp.discharge_dt)
		when rp.discharge_dt between datefromparts(yrs.year_yyyy, 06, 30) 
								and '9999-12-31'
		then 364
	end + 1 los 
	,case
		when rp.discharge_dt <> '9999-12-31'
			and toe.discharge_type = 'Reunification'
			and cd2.state_fiscal_yyyy = yrs.year_yyyy
		then 1
		else 0
	end reu
	,case
		when rp.discharge_dt <> '9999-12-31'
			and toe.discharge_type = 'Adoption'
			and cd2.state_fiscal_yyyy = yrs.year_yyyy
		then 1
		else 0
	end adt
	,case
		when rp.discharge_dt <> '9999-12-31'
			and toe.discharge_type = 'Guardianship'
			and cd2.state_fiscal_yyyy = yrs.year_yyyy
		then 1
		else 0
	end gdn
	,case
		when rp.discharge_dt <> '9999-12-31'
			and toe.discharge_type not in ('Reunification'
											,'Adoption'
											,'Guardianship')
			and cd2.state_fiscal_yyyy = yrs.year_yyyy
		then 1
		else 0
	end oth
	,cd1.state_fiscal_yyyy entry_yr
	,yrs.year_yyyy fiscal_yr
from ca_ods.base.rptPlacement rp
	left join dbo.ref_lookup_cd_discharge_type_exits toe 
		on toe.cd_discharge_type=rp.cd_discharge_type
	join ca_ods.dbo.calendar_dim cd1
		on rp.removal_dt = cd1.calendar_date 
	join ca_ods.dbo.calendar_dim cd2
		on rp.discharge_dt = cd2.calendar_date 
	,(select 
			distinct year_yyyy 
		from 
			ca_ods.dbo.calendar_dim yr
		where 
			year_yyyy between @startyear and @stopyear) yrs 
where
	case 
		when rp.[18bday] < rp.discharge_dt
		then rp.[18bday]
		else rp.discharge_dt
	end >= datefromparts(yrs.year_yyyy-1, 07, 01)
	and rp.removal_dt < rp.[18bday]
	and rp.removal_dt between datefromparts(yrs.year_yyyy-18,07,01) 
								and datefromparts(yrs.year_yyyy,06,30)


