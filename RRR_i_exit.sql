declare @fystart int
declare @fystop int
set @fystart = 2010
set @fystop = 2013;
with max_dt_18 as
(select 
    ti.id_intake_fact 
    ,isnull(max(dateadd(yy, 18, thc.dt_birth))
            ,dateadd(yy
                ,18
                ,ti.inv_ass_start)) mx_dt_18
from ca_ods.base.tbl_intakes ti
    left join ca_ods.base.tbl_household_children thc
        on ti.id_intake_fact = thc.id_intake_fact
            and ti.id_case = thc.id_case
where 
    cd_access_type in (1,4)
    and intake_rank = 1
group by
    ti.id_intake_fact
    ,ti.inv_ass_start
having isnull(max(dateadd(yy, 18, thc.dt_birth))
            ,dateadd(yy
            ,18
            ,ti.inv_ass_start)) <= 
				datefromparts(@fystop, 06, 30))
select
    count(distinct id_intake_fact) pop_exit
    ,month
from ca_ods.dbo.calendar_dim cd 
    left join max_dt_18 m18
        on mx_dt_18 
        between dateadd(mm, -1, month) and month  
where month 
	between datefromparts(@fystart-1, 07, 01) 
		and datefromparts(@fystop, 06, 30)
group by
    month
order by 
    month