declare @fystart int
declare @fystop int

set @fystart = 2012
set @fystop = 2014;

if object_id('tempdb..##calendar_dim_sub') is not null
	drop table ##calendar_dim_sub

select distinct 
	id_calendar_dim
	,state_fiscal_yyyy
	,CALENDAR_DATE
into ##calendar_dim_sub
from ca_ods.dbo.calendar_dim 
where 
	state_fiscal_yyyy between @fystart and @fystop;


if object_id('tempdb..##placement_prep17') is not null
	drop table ##placement_prep17

select distinct 
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
	,convert(int, convert(varchar, dateadd(dd, 365.25*17.5, birthdate), 112)) bday17_int
	,rp.id_removal_episode_fact as exit_cntr
	,epf.id_prsn_child as plan_cntr
	,epf.first_plan_act 
	,rp.episode_los
	,iif(nd.id_prsn is not null,1,0) fl_nondcfs_custody
into ##placement_prep17
from ca_ods.base.rptPlacement_Events rp
	left join (select 
					min(id_calendar_dim_plan_date) first_plan_act
					,id_prsn_child 
				from 
					ca_ods.dbo.EDUCATION_PLAN_FACT epf
						join ca_ods.dbo.people_dim pd 
							on pd.id_prsn = epf.id_prsn_child 
						--where 
						--	iif(isnull(fl_applications, 0) + 
						--			isnull(fl_assistance, 0) + 
						--			isnull(fl_college_tour, 0) +
						--			isnull(fl_other, 0) +
						--			isnull(fl_post_planning,0) >= 1
						--		,1
						--		,0
						--		) = 1 
							and id_calendar_dim_plan_date < convert(int, convert(varchar, dateadd(yy, 18, pd.DT_BIRTH), 112)) 
						group by 
							id_prsn_child) epf
		on rp.child = epf.id_prsn_child 
	left join dbo.vw_nondcfs_combine_adjacent_segments nd on nd.id_prsn=rp.child
			and nd.cust_begin<=rp.begin_date
			and rp.end_date<=nd.cust_end

create table base.exits_planning
(fiscal_yr int,
exits int,
exits_with_plans int,
planning_rate numeric);

insert into base.exits_planning

select 
	STATE_FISCAL_YYYY fiscal_yr 
	,count(exit_cntr) exits 
	,count(plan_cntr) exits_with_plans
	,iif(count(exit_cntr) = 0, null, count(plan_cntr)*1.0/count(exit_cntr)) planning_rate 
from ##calendar_dim_sub cd
	left join ##placement_prep17 rp
		on cd.id_calendar_dim = rp.discharg_frc_18_int
			and cd.id_calendar_dim >= rp.bday17_int
			and episode_los > 7
			and fl_nondcfs_custody = 0
group by 
	STATE_FISCAL_YYYY 
order by 
	STATE_FISCAL_YYYY 
