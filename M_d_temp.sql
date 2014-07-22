declare @fystart int
declare @fystop int

set @fystart = 2010
set @fystop = 2013;

if object_id('tempdb..##calendar_dim_sub') is not null
	drop table ##calendar_dim_sub

select distinct 
	id_calendar_dim
	,state_fiscal_yyyy
	,calendar_date 
into ##calendar_dim_sub
from ca_ods.dbo.calendar_dim 
where 
	state_fiscal_yyyy between @fystart and @fystop;


if object_id('tempdb..##placement_prep') is not null
	drop table ##placement_prep

select 
	rp.removal_dt
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
	,convert(int, convert(varchar, dateadd(yy, 17, rp.birthdate), 112)) bday17_int
	,rp.id_removal_episode_fact as care_day_cntr
	,rp.id_placement_fact as placement_cntr
	,rp.plcmnt_seq
	,convert(int, convert(varchar, rp.begin_date, 112)) plc_begin_int
	,convert(int, convert(varchar, rp.end_date, 112)) plc_end_int
	,iif(rp.plcmnt_seq >= 11
		,11
		,rp.plcmnt_seq) ord 
	,child
	,begin_date 
	,isnull(rpx.berk_tx_plcm_setng, 'Other') current_setng
	,lead(isnull(rpx.berk_tx_plcm_setng, 'Other'), 1,0) 
		over (partition by child order by begin_date) next_setng
into ##placement_prep
from ca_ods.base.rptPlacement_Events rp
	left join dbo.ref_plcm_setting_xwalk rpx
		on rp.cd_plcm_setng = rpx.cd_plcm_setng
where rp.cd_epsd_type <> 5
order by child, begin_date 


if object_id('tempdb..##care_day_count') is not null
	drop table ##care_day_count
	
select 
	state_fiscal_yyyy fiscal_yr
	,count(rp.care_day_cntr) c 
	,iif(dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date) >= 10
		,10
		,dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date)) d
into ##care_day_count
from ##calendar_dim_sub cd
	left join ##placement_prep rp
		on cd.id_calendar_dim between rp.removal_dt_int and rp.discharg_frc_18_int
			and cd.id_calendar_dim between rp.plc_begin_int and rp.plc_end_int
group by 
	state_fiscal_yyyy
	,iif(dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date) >= 10
		,10
		,dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date))
order by 
	fiscal_yr
	,d 

if object_id('tempdb..##mobility_count') is not null
	drop table ##mobility_count
	
select 
	state_fiscal_yyyy fiscal_yr
	,count(distinct rp.care_day_cntr) e
	,iif(dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date) >= 10
		,10
		,dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date)) d
into ##mobility_count
from ##calendar_dim_sub cd
	left join ##placement_prep rp
		on cd.id_calendar_dim = rp.plc_begin_int
			and rp.plcmnt_seq > 1
group by 
	state_fiscal_yyyy
	,iif(dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date) >= 10
		,10
		,dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date))
order by 
	fiscal_yr
	,d 

if object_id('tempdb..##mobility_count_toKin') is not null
	drop table ##mobility_count_toKin
	
select 
	state_fiscal_yyyy fiscal_yr
	,count(distinct rp.care_day_cntr) e
	,iif(dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date) >= 10
		,10
		,dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date)) d
into ##mobility_count_toKin
from ##calendar_dim_sub cd
	left join ##placement_prep rp
		on cd.id_calendar_dim = rp.plc_begin_int
			and rp.plcmnt_seq > 1
			and rp.next_setng = 'Kin'
group by 
	state_fiscal_yyyy
	,iif(dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date) >= 10
		,10
		,dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date))
order by 
	fiscal_yr
	,d 

if object_id('tempdb..##mobility_count_toFoster') is not null
	drop table ##mobility_count_toFoster
	
select 
	state_fiscal_yyyy fiscal_yr
	,count(distinct rp.care_day_cntr) e
	,iif(dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date) >= 10
		,10
		,dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date)) d
into ##mobility_count_toFoster
from ##calendar_dim_sub cd
	left join ##placement_prep rp
		on cd.id_calendar_dim = rp.plc_begin_int
			and rp.plcmnt_seq > 1
			and rp.next_setng = 'Foster'
group by 
	state_fiscal_yyyy
	,iif(dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date) >= 10
		,10
		,dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date))
order by 
	fiscal_yr
	,d 

if object_id('tempdb..##mobility_count_toGroup') is not null
	drop table ##mobility_count_toGroup
	
select 
	state_fiscal_yyyy fiscal_yr
	,count(distinct rp.care_day_cntr) e
	,iif(dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date) >= 10
		,10
		,dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date)) d
into ##mobility_count_toGroup
from ##calendar_dim_sub cd
	left join ##placement_prep rp
		on cd.id_calendar_dim = rp.plc_begin_int
			and rp.plcmnt_seq > 1
			and rp.next_setng = 'Group'
group by 
	state_fiscal_yyyy
	,iif(dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date) >= 10
		,10
		,dbo.fnc_datediff_yrs(rp.removal_dt, cd.calendar_date))
order by 
	fiscal_yr
	,d 
