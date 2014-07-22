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


if object_id('tempdb..##sib_plc_prep') is not null
	drop table ##sib_plc_prep

select distinct 
	srf.id_placement_fact
	,srf.id_calendar_dim_begin
	,srf.id_calendar_dim_end
	,srf.id_prsn_child 
	,count(distinct id_prsn_sibling) sib_count
	,sum(fl_together) sibs_together
into ##sib_plc_prep
from sibling_relationship_fact srf
where
	srf.fl_sibling_in_placement = 1
group by 
	srf.id_placement_fact
	,srf.id_calendar_dim_begin
	,srf.id_calendar_dim_end 
	,srf.id_prsn_child 


if object_id('tempdb..##sib_care_days') is not null
	drop table ##sib_care_days
select
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy fiscal_yr 
  ,srf.sib_count
  ,count(*) care_days
  ,sum(srf.sib_count) total_sibs
  ,sum(srf.sibs_together) total_sibs_together
into ##sib_care_days 
from ##calendar_dim_sub cd
	left join ##sib_plc_prep srf 
	on id_calendar_dim_begin <= id_calendar_dim 
		and (id_calendar_dim_end > id_calendar_dim or id_calendar_dim_end = 0)
where 
	cd.state_fiscal_yyyy between @fystart and @fystop
group by 
  cd.id_calendar_dim
  ,srf.sib_count
  ,cd.state_fiscal_yyyy

select
	fiscal_yr
	--,iif(sib_count + 1 >= 4, 4, sib_count + 1) s
	,sum(care_days) sib_cd
	,((sum(total_sibs_together)*1.0/sum(total_sibs)))*sum(care_days) sib_cd_together 
	,(((sum(total_sibs_together)*1.0/sum(total_sibs)))*sum(care_days))/sum(care_days) SR
from ##sib_care_days
group by 
fiscal_yr 
--,iif(sib_count + 1 >= 4, 4, sib_count + 1)
order by 
fiscal_yr
--,iif(sib_count + 1 >= 4, 4, sib_count + 1)
