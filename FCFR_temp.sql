declare @fystart int
declare @fystop int

set @fystart = 2000
set @fystop = 2013;

if object_id('tempdb..##calendar_dim_sub') is not null
	drop table ##calendar_dim_sub

select distinct 
	id_calendar_dim
	,state_fiscal_yyyy
into ##calendar_dim_sub
from ca_ods.dbo.calendar_dim 
where 
	state_fiscal_yyyy between @fystart and @fystop;

if object_id('tempdb..##placement_prep') is not null
	drop table ##placement_prep

select distinct 
	dbo.IntDate_to_CalDate(af.id_calendar_dim_incident) 
		as incident_date
	,af.id_calendar_dim_incident
	,rp.removal_dt
	,convert(int, convert(varchar, rp.removal_dt, 112)) 
		as removal_dt_int
	,convert
	(
	int
	,convert
		(varchar
			,case 
				when iif(rp.[18bday] < rp.discharge_dt
					,rp.[18bday]
					,rp.discharge_dt) = '9999-12-31'
				then datefromparts(@fystop, 06, 30)
				else iif(rp.[18bday] < rp.discharge_dt
					,rp.[18bday]
					,rp.discharge_dt)
			end
			,112
		)
	) discharg_frc_18_int
	,rp.id_removal_episode_fact as care_days_cntr
	,af.id_abuse_fact as substantiated_allegation_cntr
into ##placement_prep
from ca_ods.base.rptPlacement rp 
left join ca_ods.dbo.abuse_fact af
	on af.id_prsn_vctm = rp.child 
	and datediff(dd, removal_dt
				,dbo.IntDate_to_CalDate(af.id_calendar_dim_incident)) > 7
	and case 
			when iif(rp.[18bday] < rp.discharge_dt
					,rp.[18bday], rp.discharge_dt) = '9999-12-31'
			then datediff(dd, rp.removal_dt
						,datefromparts(@fystop, 06, 30))
			else datediff(dd,rp.removal_dt
						,iif(rp.[18bday] < rp.discharge_dt
						,rp.[18bday]
						,rp.discharge_dt))
		end + 1 > 7 

if object_id('tempdb..##care_days') is not null
	drop table ##care_days

select
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy fiscal_yr 
  ,count(rp1.care_days_cntr) care_days
into ##care_days 
from ##calendar_dim_sub cd
	left join ##placement_prep rp1 
		on cd.id_calendar_dim between removal_dt_int 
					and discharg_frc_18_int
where 
	cd.state_fiscal_yyyy between @fystart and @fystop
group by 
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy

if object_id('tempdb..##substantiations') is not null
	drop table ##substantiations

select
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy fiscal_yr 
  ,count(rp2.substantiated_allegation_cntr) 
	as substantiated_allegations
into ##substantiations
from ##calendar_dim_sub cd
	left join ##placement_prep rp2
		on cd.id_calendar_dim = rp2.id_calendar_dim_incident
where 
	cd.state_fiscal_yyyy between @fystart and @fystop
group by 
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy