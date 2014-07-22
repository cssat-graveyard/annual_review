declare @fystart int
declare @fystop int

set @fystart = 2010
set @fystop = 2013;

select 
    count(*) pop_enter
    ,month 
from 
    ca_ods.base.tbl_intakes ti
    left join ca_ods.dbo.calendar_dim cd
        on ti.inv_ass_start = calendar_date 
where 
	cd_access_type in (1, 4)
	and (intake_rank = 1 or fl_founded_prior_any_legal = 0)
	and fl_founded_any_legal = 1
    and inv_ass_start 
		between datefromparts(@fystart-1, 07, 01) 
			and datefromparts(@fystart, 06, 30)
group by 
    month 
order by 
    month
