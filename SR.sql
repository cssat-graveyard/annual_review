declare @fystart int
declare @fystop int

set @fystart = 2000
set @fystop = 2014;

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
	srf.id_calendar_dim_begin
	,srf.id_calendar_dim_end
	--,srf.id_prsn_child 
	,id_case_child 
	--,id_prsn_sibling sib_count
	,count(distinct id_prsn_sibling) sib_gp_size 
	,sum(fl_together) sibs_together
into ##sib_plc_prep
from ca_ods.dbo.sibling_relationship_fact srf
where
	srf.fl_sibling_in_placement = 1
group by 
	--srf.id_placement_fact
	srf.id_calendar_dim_begin
	,srf.id_calendar_dim_end 
	,id_case_child 
having count(distinct id_prsn_sibling) > 1

if object_id('tempdb..##sib_care_days') is not null
	drop table ##sib_care_days
select
  cd.id_calendar_dim
  ,cd.state_fiscal_yyyy fiscal_yr 
  ,srf.sib_gp_size
  ,count(*) care_days
  ,count(*)*iif(sibs_together >= 1, 1, 0) care_days_tghr
into ##sib_care_days 
from ##calendar_dim_sub cd
	left join ##sib_plc_prep srf 
	on id_calendar_dim_begin <= id_calendar_dim 
		and (id_calendar_dim_end > id_calendar_dim or id_calendar_dim_end = 0)
where 
	cd.state_fiscal_yyyy between @fystart and @fystop
group by 
  cd.id_calendar_dim
  ,srf.sibs_together
  ,cd.state_fiscal_yyyy
  ,sib_gp_size

create table base.sibling_care_days_placed_tghr
(fiscal_yr int,
care_days int,
care_days_tghr int,
rate numeric);

insert into base.sibling_care_days_placed_tghr
select 
	fiscal_yr
	,sum(care_days) care_days
	,sum(care_days_tghr) care_days_tghr 
	,sum(care_days_tghr)*1.0/sum(care_days) rate
from ##sib_care_days
group by
	fiscal_yr 
order by fiscal_yr
