declare @fystart int
declare @fystop int
set @fystart = 2000
set @fystop = 2013;

select
	child id_prsn_child
	,case 
		when rp.[18bday] < next_reentry_date
		then datediff(dd, rp.discharge_dt, rp.[18bday]) + 1
		else datediff(dd, rp.discharge_dt, isnull(rp.next_reentry_date, datefromparts(@fystop, 06, 30))) + 1
	end t
	,case 
		when rp.next_reentry_date is null and rp.[18bday] < datefromparts(@fystop, 06, 30)
		then 0
		else iif(rp.next_reentry_date is not null, 1, 0) 
	end r
	,cd1.state_fiscal_yyyy fiscal_yr
from ca_ods.base.rptPlacement rp
	left join dbo.ref_lookup_cd_discharge_type_exits toe 
		on toe.cd_discharge_type=rp.cd_discharge_type
	join ca_ods.dbo.calendar_dim cd1
		on convert(int
				,convert(
					varchar
						,case 
							when rp.discharge_dt = '9999-12-31' 
							then datefromparts(@fystop, 06, 30)
							when rp.[18bday] < rp.discharge_dt
							then rp.[18bday]
							else rp.discharge_dt
						end 
						,112
						)
					) = cd1.id_calendar_dim 
where 
	cd1.state_fiscal_yyyy between @fystart and @fystop
		and rp.discharge_dt <> '9999-12-31'
		and case 
				when rp.[18bday] < next_reentry_date
				then datediff(dd, rp.discharge_dt, rp.[18bday]) + 1
				else datediff(dd, rp.discharge_dt, isnull(rp.next_reentry_date, datefromparts(@fystop, 06, 30)))
			end >= 0  
		and case
		when rp.discharge_dt <> '9999-12-31'
					and rp.[18bday] > rp.discharge_dt
					and toe.discharge_type in ('Reunification'
												,'Adoption'
												,'Guardianship')
				then 1
				else 0
			end = 1
		and case 
				when rp.discharge_dt = '9999-12-31' 
				then datediff(dd
								,rp.removal_dt
								,datefromparts(@fystop, 06, 30))
				when rp.[18bday] < rp.discharge_dt
				then datediff(dd
								,rp.removal_dt
								, rp.[18bday])
				else datediff(dd
							 ,rp.removal_dt
							 ,rp.discharge_dt)
			end + 1 > 7 
order by t
