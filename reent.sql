declare @fystart int= 2000;
declare @fystop int= 2014;



if object_id('tempdb..#placements') is not null
	drop table #placements

select 
			rp.removal_dt
			,rp.birthdate
			-- age yr at removal
			,isnull(dbo.fnc_datediff_yrs(rp.birthdate, rp.removal_dt),-99)  age_yrs_removal
			--age_yrs_exit
			,isnull(iif(rp.discharge_dt <= cutoff_date,iif( rp.[18bday] <= rp.discharge_dt
							,dbo.fnc_datediff_yrs(rp.birthdate,rp.[18bday])
							,dbo.fnc_datediff_yrs(rp.birthdate,rp.discharge_dt)),-99),-99) age_yrs_exit
			-- race
			,isnull(pd.cd_race_census,7) cd_race_census
			--ethnicity
			,isnull(pd.census_Hispanic_Latino_Origin_cd,5) census_Hispanic_Latino_Origin_cd
			--county_cd
			,isnull(rp.derived_county,-99) [county_cd]
			-- federal discharge date force
			,iif( -- lessor date of 18th birthday is greater than cutoff_date use cutoff else use lessor date 18 bday or discharge date
					IIF(rp.[18bday]<rp.discharge_dt,rp.[18bday],rp.discharge_dt) > cutoff_date
						, cutoff_date
						,IIF(rp.[18bday]<rp.discharge_dt,rp.[18bday],rp.discharge_dt) ) discharg_frc_18
			,rp.id_removal_episode_fact 
			,rp.id_placement_fact
			,rp.plcmnt_seq
			,rp.begin_date plc_begin
			,IIF(rp.end_date> -- discharg_frc_18
							iif(IIF(rp.[18bday]<rp.discharge_dt,rp.[18bday],rp.discharge_dt)  > cutoff_date
								, cutoff_date
								,IIF(rp.[18bday]<rp.discharge_dt,rp.[18bday],rp.discharge_dt) ) 
						--   choose discharg_frc_18
						,iif(IIF(rp.[18bday]<rp.discharge_dt,rp.[18bday],rp.discharge_dt)  > cutoff_date
								, cutoff_date
								,IIF(rp.[18bday]<rp.discharge_dt,rp.[18bday],rp.discharge_dt) ) 
						,rp.end_date)  plc_end
			,iif(rp.plcmnt_seq >= 11
				,11
				,rp.plcmnt_seq) ord 
			,rp.child
			,isnull(rpx.berk_tx_plcm_setng, 'Other') current_setng
			--,lead(isnull(rpx.berk_tx_plcm_setng, 'Other'), 1,0) 
			--	over (partition by child order by begin_date) next_setng
			,tx_end_rsn
			,lag(tx_end_rsn) over (partition by sfy,rp.id_removal_episode_fact order by begin_date,end_date) prior_end_rsn
			,cast(iif(datediff(dd,rp.removal_dt,(IIF(rp.[18bday]<rp.discharge_dt and rp.[18bday]<= cutoff_date
									, rp.[18bday]
									,iif(cutoff_date<=rp.discharge_dt,cutoff_date,rp.discharge_dt))))<8,1,0) as smallint) flag_7day
			,cast(0 as smallint) flag_trh
			,(select max(calendar_date) from CALENDAR_DIM where month(calendar_date)=month(rp.removal_dt)
					and CALENDAR_DATE between cd.fy_start_date and cd.fy_stop_date and day(calendar_date)<=day(rp.removal_dt))	 anniv_removal_dt
			,sfy
			,cd.fy_start_date
			,cd.fy_stop_date
			,iif(nd.id_prsn is not null,1,0) fl_nondcfs_custody
		,cast(null as int)  as care_day_cnt_prior_anniv
		,cast(null as int)  as care_day_cnt_post_anniv
		,cast(null as int) as prior_year_service
		,cast(null as int) as post_year_service
		,rp_ep.cd_discharge_type
		,rp_ep.days_to_reentry
		,case
			when rp.[18bday] < cutoff_date then 'Age of Majority'
			when next_reentry_date is null then 'Still In Permanency'
			else 'Re-Entry'
		end tx_perm_outcome 
		,case
			when rp.[18bday] < cutoff_date then 2
			when next_reentry_date is null then 0
			else 1
		end cd_perm_outcome 
		,case
			when rp.[18bday] < cutoff_date then rp.[18bday]
			when next_reentry_date is null then cutoff_date
			else next_reentry_date
		end reentry_frc_18 
into #placements
from (select  distinct state_fiscal_yyyy sfy
							,min(ID_CALENDAR_DIM)  over (partition by state_fiscal_yyyy order by ID_CALENDAR_DIM) fy_start_date_int
							,max(ID_CALENDAR_DIM)  over (partition by state_fiscal_yyyy order by ID_CALENDAR_DIM asc RANGE between current row and UNBOUNDED FOLLOWING) fy_stop_date_int
							,min(calendar_date)  over (partition by state_fiscal_yyyy order by calendar_date)  fy_start_date
							,max(calendar_date)  over (partition by state_fiscal_yyyy order by calendar_date asc RANGE between current row and UNBOUNDED FOLLOWING)   fy_stop_date 
						from ca_ods.dbo.calendar_dim 
						where state_fiscal_yyyy between @fystart and @fystop
				) cd
join ref_last_dw_transfer dw on dw.cutoff_date=dw.cutoff_date
join base.rptPlacement_Events rp 
		on removal_dt <= cd.fy_stop_date
--		 discharge_dt >=fy_start_date
		and (iif( -- lessor date of 18th birthday is greater than cutoff_date use cutoff else use lessor date 18 bday or discharge date
			IIF([18bday]<rp.discharge_dt,[18bday],rp.discharge_dt) > cutoff_date
				, cutoff_date
				,IIF([18bday]<rp.discharge_dt,[18bday],rp.discharge_dt) )) >=fy_start_date	
			and rp.begin_date <= cd.fy_stop_date
			--  end_date >=cd.fy_start_date
			and (IIF(rp.end_date> -- discharg_frc_18
					iif(IIF([18bday]<rp.discharge_dt,[18bday],rp.discharge_dt)  > cutoff_date
						, cutoff_date
						,IIF([18bday]<rp.discharge_dt,[18bday],rp.discharge_dt) ) 
				--   choose discharg_frc_18
				,iif(IIF([18bday]<rp.discharge_dt,[18bday],rp.discharge_dt)  > cutoff_date
						, cutoff_date
						,IIF([18bday]<rp.discharge_dt,[18bday],rp.discharge_dt) ) 
				,rp.end_date) ) >= cd.fy_start_date
			
join base.rptPlacement rp_ep
	on rp_ep.id_removal_episode_fact = rp.id_removal_episode_fact
left join dbo.ref_plcm_setting_xwalk rpx
		on rp.cd_plcm_setng = rpx.cd_plcm_setng
left join PEOPLE_DIM pd on pd.ID_PRSN=rp.child and pd.IS_CURRENT=1
left join dbo.vw_nondcfs_combine_adjacent_segments nd on nd.id_prsn=rp.child
		and nd.cust_begin<=rp.begin_date
		and rp.end_date<=nd.cust_end
where rp.cd_epsd_type <> 5   and dbo.fnc_datediff_yrs(pd.dt_birth,begin_date)<18
-- and placement begin date less than cutoff_date
and rp.removal_dt <= 
				iif( -- lessor of 18th birthday , discharge date,cutoff_date
						IIF(rp.[18bday]<rp.discharge_dt,rp.[18bday],rp.discharge_dt) > cutoff_date
							, cutoff_date
							, IIF(rp.[18bday]<rp.discharge_dt,rp.[18bday],rp.discharge_dt)) 
order by rp.child, begin_date ,sfy



update #placements
set flag_trh=1
--  select * 
 from #placements 
 where NOT(tx_end_rsn = 'Changed Caregiver'  and charindex('Trial Return Home',prior_end_rsn)>0)
				and charindex('Trial Return Home',prior_end_rsn)>0

--select * from #placements where anniv_removal_dt is null
--these are last placements before a discharge where the discharge occurs prior to the removal anniversary date within the fiscal year
update #placements
set anniv_removal_dt = null
		,care_day_cnt_prior_anniv=datediff(dd,iif(fy_start_date>=plc_begin
		,fy_start_date,plc_begin)
		,iif(fy_stop_date <=IIF(discharg_frc_18>plc_end,plc_end,discharg_frc_18) ,fy_stop_date,IIF(discharg_frc_18>plc_end,plc_end,discharg_frc_18)))
		,prior_year_service=dbo.fnc_datediff_yrs(removal_dt,discharg_frc_18)
where   anniv_removal_dt not between removal_dt and discharg_frc_18 

delete  #placements where anniv_removal_dt is null and care_day_cnt_prior_anniv =0 ;

-- update the placements containing the anniversary dates.
update #placements 
set care_day_cnt_prior_anniv=datediff(dd,iif(fy_start_date>=plc_begin,fy_start_date,plc_begin),anniv_removal_dt)
		,prior_year_service=dbo.fnc_datediff_yrs(removal_dt,iif(removal_dt<>anniv_removal_dt,dateadd(dd,-1,anniv_removal_dt),removal_dt))
		,care_day_cnt_post_anniv=datediff(dd,anniv_removal_dt,iif(plc_end>=fy_stop_date,fy_stop_date,plc_end))
		,post_year_service=dbo.fnc_datediff_yrs(removal_dt,anniv_removal_dt)
where anniv_removal_dt is not null and anniv_removal_dt between plc_begin and plc_end

--update the placements without the anniversary dates
update P 
set care_day_cnt_prior_anniv=datediff(dd,iif(fy_start_date>=plc_begin	,fy_start_date,plc_begin),iif(plc_end>=fy_stop_date,fy_stop_date,plc_end))
		,prior_year_service=dbo.fnc_datediff_yrs(removal_dt, iif(plc_begin<fy_start_date,fy_start_date,plc_begin)) 
from #placements P
where anniv_removal_dt is not null and anniv_removal_dt NOT between plc_begin and plc_end





create table base.episode_reentries
(id_prsn_child int,
lop int,
stat int,
discharge_type varchar(20), 
state_fiscal_yyyy int,
non_dcfs_placements int);


insert into base.episode_reentries
select 
	plc.child id_prsn_child 
	,datediff(dd, discharg_frc_18, reentry_frc_18) + 1 lop
	,plc.cd_perm_outcome stat
	,plc.tx_perm_outcome discharge_type 
	,cd.state_fiscal_yyyy 
	,sum(fl_nondcfs_custody) non_dcfs_placements
from #placements plc
	join ca_ods.dbo.calendar_dim cd
		on cd.calendar_date = plc.discharg_frc_18
where state_fiscal_yyyy between 2000 and 2014 
	and state_fiscal_yyyy <= 2014
		and plc.flag_7day = 0
		and cd_discharge_type in (1, 4)
		and datediff(dd, discharg_frc_18, reentry_frc_18) >= 0 
group by 
	plc.child  
	,datediff(dd, discharg_frc_18, reentry_frc_18) 
	,plc.cd_perm_outcome 
	,plc.tx_perm_outcome  
	,cd.state_fiscal_yyyy 
having sum(fl_nondcfs_custody) = 0



