declare @fystart int
declare @fystop int
declare @last_obs datetime
set @fystart = 2000
set @fystop = 2013;

select
	child id_prsn_child
	,case 
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
	end t
	,case
		when rp.discharge_dt <> '9999-12-31'
			and rp.[18bday] > rp.discharge_dt
			and toe.discharge_type in ('Reunification'
										,'Adoption'
										,'Guardianship')
		then 1
		else 0
	end p	
	,cd1.state_fiscal_yyyy fiscal_yr
from ca_ods.base.rptPlacement rp
	left join dbo.ref_lookup_cd_discharge_type_exits toe 
		on toe.cd_discharge_type=rp.cd_discharge_type
	join ca_ods.dbo.calendar_dim cd1
		on rp.removal_dt = cd1.calendar_date 
where 
	cd1.state_fiscal_yyyy between @fystart and @fystop
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