declare @fystart int
declare @fystop int

set @fystart = 2000
set @fystop = 2013;

with care_days as
(
select
  cd.calendar_date
  ,cd.state_fiscal_yyyy fiscal_yr 
  ,count(rp.id_removal_episode_fact) as care_days
from ca_ods.dbo.calendar_dim cd
	left join ca_ods.base.rptPlacement rp 
		on cd.calendar_date between rp.removal_dt and rp.discharge_dt
where 
	cd.state_fiscal_yyyy between @fystart and @fystop
group by 
  cd.calendar_date
  ,cd.state_fiscal_yyyy
), exits2 as
(
select
  count(rp.discharge_dt) exits
  ,cd.state_fiscal_yyyy fiscal_yr
from ca_ods.base.rptPlacement rp 
	join ca_ods.dbo.calendar_dim cd
		on rp.discharge_dt = cd.calendar_date 
where 
	cd.state_fiscal_yyyy between @fystart and @fystop
group by 
	cd.state_fiscal_yyyy
), exits1 as
(
select
  count(rp.discharge_dt) exits
  ,cd.state_fiscal_yyyy fiscal_yr
  ,toe.discharge_type
from ca_ods.base.rptPlacement rp 
	join ca_ods.dbo.calendar_dim cd
		on rp.discharge_dt = cd.calendar_date 
	left join dbo.ref_lookup_cd_discharge_type_exits toe 
		on toe.cd_discharge_type=rp.cd_discharge_type
where 
	cd.state_fiscal_yyyy between @fystart and @fystop
group by 
	cd.state_fiscal_yyyy
	,toe.discharge_type
), weight_calc as 
(
select distinct 
	ex1.discharge_type
	,ex1.exits
	,ex2.exits exits_all 
	,ex1.fiscal_yr
	,sum(cd.care_days) care_days 
	,(sum(cd.care_days)*1.0/ex2.exits) D_R
	,(ex1.exits*1.0/ex2.exits) decomp

from exits1 ex1
	join care_days cd
		on ex1.fiscal_yr = cd.fiscal_yr
	join exits2 ex2
		 on ex2.fiscal_yr = cd.fiscal_yr
group by 
	ex1.exits
	,ex1.fiscal_yr
	,ex2.exits
	,discharge_type
)

select * from weight_calc
order by fiscal_yr, discharge_type