USE [dbCoreAdministrativeTables]
GO

/****** Object:  View [dbo].[vw_legally_free]    Script Date: 6/3/2014 11:01:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



--if OBJECT_ID('tempDB..##legfree') is not null drop table ##legfree

create view [dbo].[vw_legally_free]
as 
select  tce.id_removal_episode_fact
		,q.id_prsn_child
		,q.pk_gndr
		,q.eps_total
		,q.cd_race_census
		,q.child_age_removal_begin
		,q.child_age_removal_end
		,q.census_hispanic_latino_origin_cd
		,q.state_custody_start_date
		,q.state_discharge_date
		,q.legally_free_date
		,q.federal_discharge_date
		,q.federal_discharge_date_force_18
		,q.count_of_results
		,q.federal_discharge_reason_code
		,q.state_discharge_reason_code
		,q.tx_jurisdiction
		,case when (case when q.Federal_Discharge_Reason_Force is not null and q.discharge_flag= 0 then null else q.Federal_Discharge_Reason_Force end)
				 in ('Death of Child', 'Transfer to Another Agency', 'Missing or Unknown') then 'Other' 
				 else (case when q.Federal_Discharge_Reason_Force is not null and q.discharge_flag= 0 then null else q.Federal_Discharge_Reason_Force end) 
		  end  as Federal_Discharge_Reason_Force
		,q.federal_discharge_reason
		,q.custody_to_term
		,q.cnt_plcm
		,q.term_to_perm
		,case when (case when (case when q.Federal_Discharge_Reason_Force is not null and q.discharge_flag= 0 then null else q.Federal_Discharge_Reason_Force end)
				 in ('Death of Child', 'Transfer to Another Agency', 'Missing or Unknown') then 'Other' 
				 else (case when q.Federal_Discharge_Reason_Force is not null and q.discharge_flag= 0 then null else q.Federal_Discharge_Reason_Force end) 
		  end)= 'Other' then 0 else q.discharge_flag end as discharge_flag
-- into ##legfree
from (
		select		tce.id_prsn_child
					--,isnull((select pk_gndr from ref_lookup_gender where tce.cd_gndr=ref_lookup_gender.cd_gndr),3) as pk_gndr
					,isnull((select pk_gndr from ref_lookup_gender where tce.cd_gndr=ref_lookup_gender.cd_gndr),3) as pk_gndr
					,tce.eps_total
					,tce.cd_race_census as cd_race_census
					,tce.child_age_removal_begin 
					,tce.child_age_removal_end 
					,tce.census_hispanic_latino_origin_cd
					--,tce.cd_race_census
					,state_custody_start_date
					,state_discharge_date
					,max(dbo.IntDate_to_CalDate(lf.id_calendar_dim_effective)) as legally_free_date
					, federal_discharge_date
					,Federal_Discharge_Date_Force_18
					,count (distinct lf.id_legal_fact) as count_of_results
					,tce.federal_discharge_reason_code
					,tce.state_discharge_reason_code
					,tce.state_discharge_reason
					,ljd.tx_jurisdiction
					,case
						when Federal_Discharge_Date_Force_18 is not null and Federal_Discharge_Date is null
						then 'Emancipation'
						else Federal_Discharge_Reason
					end as Federal_Discharge_Reason_Force
					,tce.federal_discharge_reason
					,datediff(dd, State_Custody_Start_Date, max(dbo.IntDate_to_CalDate(ID_CALENDAR_DIM_EFFECTIVE))) as custody_to_term
					,row_number() over  (partition by 
											id_prsn_child 
									order by id_prsn_child
											,datediff(dd, State_Custody_Start_Date, max(dbo.IntDate_to_CalDate(ID_CALENDAR_DIM_EFFECTIVE))) asc) as row_num
					,tce.cnt_plcm
					,case
								when Federal_Discharge_Date_Force_18 is null 
								then datediff(dd, max(dbo.IntDate_to_CalDate(lf.id_calendar_dim_effective)) , (select cutoff_date from dbo.ref_last_dw_transfer)) + 1
								else (datediff(dd, max(dbo.IntDate_to_CalDate(lf.id_calendar_dim_effective)) , Federal_Discharge_Date_Force_18) + 1)
							end as term_to_perm
					,case 
						when Federal_Discharge_Date_Force_18 is null and federal_discharge_date is null
						then 0
						else 1
					end as discharge_flag
		from tbl_child_episodes tce
		join  ca.legal_fact lf 
			on tce.id_prsn_child=lf.id_prsn 
				and  dbo.IntDate_to_CalDate(lf.id_calendar_dim_effective) >   tce.state_custody_start_date 
				and dbo.IntDate_to_CalDate(ID_CALENDAR_DIM_EFFECTIVE) > '1998-01-29'
		join ca.legal_result_dim lrd on lrd.id_legal_result_dim=lf.id_legal_result_dim 
		and lrd.cd_result in  (47,48,56,57,58,59,60)
		left join ca.legal_jurisdiction_dim ljd on ljd.id_legal_jurisdiction_dim=lf.id_legal_jurisdiction_dim

		group by tce.id_prsn_child
			,state_custody_start_date
			, state_discharge_date
			,Federal_Discharge_Date_Force_18
			,federal_discharge_reason_code
			,federal_discharge_reason
			, state_discharge_reason_code
			, state_discharge_reason
			,federal_discharge_date
			,tce.cnt_plcm
			,ljd.tx_jurisdiction
			,tce.eps_total
			,tce.cd_race_census 
			,tce.child_age_removal_begin 
			,tce.child_age_removal_end 
			,tce.census_hispanic_latino_origin_cd
			,tce.cd_gndr
		 ) q 
join dbo.tbl_child_episodes	 tce on tce.id_prsn_child=q.id_prsn_child
	and tce.state_custody_start_date=q.state_custody_start_date
	and isnull(tce.federal_discharge_date,'12/31/3999') = isnull(q.federal_discharge_date,'12/31/3999')
where q.row_num=1 --and id_prsn_child=4021   
		 and q.term_to_perm >=0
 and (NOT(q.federal_discharge_reason_code =1) or q.federal_discharge_reason_code is null)










GO


