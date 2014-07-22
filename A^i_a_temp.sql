declare @fystart int
declare @fystop int

set @fystart = 2009
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
	awol.begin_date begin_date_awol
	,convert(int, convert(varchar, awol.begin_date, 112)) begin_date_awol_int 
	,awol.end_date end_date_awol
	,convert(int, convert(varchar, awol.end_date, 112)) end_date_awol_int 
	,rp.removal_dt
	,rp.birthdate
	,convert(int, convert(varchar, rp.removal_dt, 112)) removal_dt_int
	,convert
	(
	int
	,convert(int
		,convert(
		varchar
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
		)
		) discharg_frc_18_int
	,rp.id_removal_episode_fact as care_days_cntr
	,awol.id_placement_fact as awol_days_cntr
	,awol.i
	,convert(int, convert(varchar, dateadd(yy, 9, birthdate), 112)) bday9_int
	,convert(int, convert(varchar, dateadd(yy, 11, birthdate), 112)) bday11_int
	,convert(int, convert(varchar, dateadd(yy, 12, birthdate), 112)) bday12_int
	,convert(int, convert(varchar, dateadd(yy, 14, birthdate), 112)) bday14_int
	,convert(int, convert(varchar, dateadd(yy, 15, birthdate), 112)) bday15_int
	,convert(int, convert(varchar, dateadd(yy, 17, birthdate), 112)) bday17_int
into ##placement_prep
from ca_ods.base.rptPlacement rp 
	left join (select
				rank() over 
					(partition by child order by begin_date) i
				,id_placement_fact 
				,child
				,begin_date
				,end_date 
			from ca_ods.base.rptPlacement_Events
			where tx_srvc in ('On The Run', 'OR: On the Run')) awol
		on awol.child = rp.child 

if object_id('tempdb..##care_days9to11') is not null
	drop table ##care_days9to11

select
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy fiscal_yr 
  ,count(rp1.care_days_cntr) care_days_9to11 
into ##care_days9to11 
from ##calendar_dim_sub cd
	left join ##placement_prep rp1 
		on cd.id_calendar_dim between removal_dt_int and discharg_frc_18_int
where 
	cd.state_fiscal_yyyy between @fystart and @fystop
		and id_calendar_dim between rp1.bday9_int and rp1.bday11_int
group by 
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy


if object_id('tempdb..##care_days12to14') is not null
	drop table ##care_days12to14

select
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy fiscal_yr 
  ,count(rp1.care_days_cntr) care_days_12to14 
into ##care_days12to14
from ##calendar_dim_sub cd
	left join ##placement_prep rp1 
		on cd.id_calendar_dim between removal_dt_int and discharg_frc_18_int
where 
	cd.state_fiscal_yyyy between @fystart and @fystop
		and id_calendar_dim between rp1.bday9_int and rp1.bday11_int
group by 
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy


if object_id('tempdb..##care_days15to17') is not null
	drop table ##care_days15to17

select
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy fiscal_yr 
  ,count(rp1.care_days_cntr) care_days_15to17 
into ##care_days15to17
from ##calendar_dim_sub cd
	left join ##placement_prep rp1 
		on cd.id_calendar_dim between removal_dt_int and discharg_frc_18_int
where 
	cd.state_fiscal_yyyy between @fystart and @fystop
		and id_calendar_dim between rp1.bday9_int and rp1.bday11_int
group by 
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy


if object_id('tempdb..##awoldays9to11') is not null
	drop table ##awoldays9to11

select
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy fiscal_yr 
  ,rp2.i
  ,count(rp2.awol_days_cntr) awol_days9to11
into ##awoldays9to11
from ##calendar_dim_sub cd
	left join ##placement_prep rp2
		on cd.id_calendar_dim between rp2.begin_date_awol_int and rp2.end_date_awol_int
where 
	cd.state_fiscal_yyyy between @fystart and @fystop
		and id_calendar_dim between rp2.bday9_int and rp2.bday11_int
group by 
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy
  ,i

if object_id('tempdb..##awoldays12to14') is not null
	drop table ##awoldays12to14

select
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy fiscal_yr 
  ,rp2.i
  ,count(rp2.awol_days_cntr) awol_days12to14 
into ##awoldays12to14
from ##calendar_dim_sub cd
	left join ##placement_prep rp2
		on cd.id_calendar_dim between rp2.begin_date_awol_int and rp2.end_date_awol_int
where 
	cd.state_fiscal_yyyy between @fystart and @fystop
		and id_calendar_dim between rp2.bday12_int and rp2.bday14_int
group by 
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy
  ,i

if object_id('tempdb..##awoldays15to17') is not null
	drop table ##awoldays15to17

select
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy fiscal_yr 
  ,rp2.i
  ,count(rp2.awol_days_cntr) awol_days15to17 
into ##awoldays15to17
from ##calendar_dim_sub cd
	left join ##placement_prep rp2
		on cd.id_calendar_dim between rp2.begin_date_awol_int and rp2.end_date_awol_int
where 
	cd.state_fiscal_yyyy between @fystart and @fystop
		and id_calendar_dim between rp2.bday15_int and rp2.bday17_int
group by 
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy
  ,i