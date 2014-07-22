declare @fystart int

set @fystart = 2010;

with hh_w_ch as
(
select 
	ti.id_intake_fact 
	,isnull(max(dateadd(yy, 18, thc.dt_birth))
			,dateadd(yy
				,18
				,ti.inv_ass_start)) mx_dt_18
	,isnull(min(thc.dt_birth)
			,ti.inv_ass_start) mn_dt_br
from ca_ods.base.tbl_intakes ti
	left join ca_ods.base.tbl_household_children thc
		on ti.id_intake_fact = thc.id_intake_fact
			and ti.id_case = thc.id_case
where
	cd_access_type in (1, 4)
		and intake_rank = 1
group by
	ti.id_intake_fact
	,ti.inv_ass_start
)
select
	count(distinct id_intake_fact) pop_start
from hh_w_ch 
where isnull(mx_dt_18,'3999-01-01') >= 
		datefromparts(@fystart-1, 07, 01)
	and mn_dt_br < datefromparts(@fystart-1, 07, 01)