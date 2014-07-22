declare @fystart int
declare @fystop int

set @fystart = 2010
set @fystop = 2013;

with ranked_subsequent_findings as
(
select * 
    ,rank() over 
    (partition by id_case order by intake_rank desc) rank
from ca_ods.base.tbl_intakes ti
where
	cd_access_type in (1, 4)
	and fl_founded_prior_any_legal = 1
	and fl_founded_any_legal = 1
    and inv_ass_start 
		between datefromparts(@fystart-1, 07, 01) 
			and datefromparts(@fystop, 06, 30)
)
select 
    count(*) pop_enter
    ,month 
from ranked_subsequent_findings ti
    left join ca_ods.dbo.calendar_dim cd
        on ti.inv_ass_start = calendar_date 
where 
	rank = 1
group by 
    month 
order by 
    month
