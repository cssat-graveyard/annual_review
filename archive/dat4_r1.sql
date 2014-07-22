with prep as 
(
select 
	child id_prsn_child
	,rp.removal_dt
	,case 
		when iif(rp.[18bday] < rp.discharge_dt, rp.[18bday], rp.discharge_dt) = '9999-12-31'
		then datefromparts(2013, 06, 30)
		else iif(rp.[18bday] < rp.discharge_dt, rp.[18bday], rp.discharge_dt)
	end discharge_dt
	,case 
		when iif(rp.[18bday] < rp.discharge_dt, rp.[18bday], rp.discharge_dt) = '9999-12-31'
		then rp.episode_los
		else datediff(dd,rp.removal_dt,iif(rp.[18bday] < rp.discharge_dt,rp.[18bday],rp.discharge_dt))
	end + 1 real_los
	,cd1.state_fiscal_yyyy fiscal_yr
	,toe.discharge_type discharge_type
from ca_ods.base.rptPlacement rp
	left join dbo.ref_lookup_cd_discharge_type_exits toe 
		on toe.cd_discharge_type=rp.cd_discharge_type
	join ca_ods.dbo.calendar_dim cd1
		on dateadd(yy, 1, rp.removal_dt) = cd1.calendar_date 
where 
	cd1.year_yyyy > 2000
		and dateadd(yy, 1, rp.removal_dt) < rp.[18bday]
), q1 as
(
select 
	'q1' column_lbl
	,*
	,iif(real_los > 365, 365, real_los) los
	,case 
		when discharge_dt <> '9999-12-31'
			and real_los < 365
			and discharge_type = 'Reunification'
		then 1
		else 0
	end reu
	,case 
		when discharge_dt <> '9999-12-31'
			and real_los < 365
			and discharge_type = 'Adoption'
		then 1
		else 0
	end adt
	,case 
		when discharge_dt <> '9999-12-31'
			and real_los < 365
			and discharge_type = 'Guardianship'
		then 1
		else 0
	end gdn
from prep 
), q2 as 
(
	select 
	'q2' column_lbl
	,id_prsn_child
	,removal_dt
	,discharge_dt
	,real_los
	,fiscal_yr
	,discharge_type
	,case
		when real_los between 366 and 730
		then 730 - real_los
		else 365
	end + 1 los
	,case 
		when discharge_dt <> '9999-12-31'
			and real_los between 366 and 730
			and discharge_type = 'Reunification'
		then 1
		else 0
	end reu
	,case 
		when discharge_dt <> '9999-12-31'
			and real_los between 366 and 730
			and discharge_type = 'Adoption'
		then 1
		else 0
	end adt
	,case 
		when discharge_dt <> '9999-12-31'
			and real_los between 366 and 730
			and discharge_type = 'Guardianship'
		then 1
		else 0
	end gdn
from prep 
	where real_los between 366 and 730
), q3 as  
(
select 	
	'q3' column_lbl
	,id_prsn_child
	,removal_dt
	,discharge_dt
	,real_los
	,fiscal_yr
	,discharge_type
	,case
		when real_los between 730 and 1095
		then 1095 - real_los
		else 365
	end + 1 los
	,case 
		when discharge_dt <> '9999-12-31'
			and real_los between 731 and 1095
			and discharge_type = 'Reunification'
		then 1
		else 0
	end reu
	,case 
		when discharge_dt <> '9999-12-31'
			and discharge_type = 'Adoption'
			and real_los between 731 and 1095
		then 1
		else 0
	end adt
	,case 
		when discharge_dt <> '9999-12-31'
			and real_los between 731 and 1095
			and discharge_type = 'Guardianship'
		then 1
		else 0
	end gdn
from q1 
	where real_los > 731
), total_tbl as
(
select * 
from q3
union 
select *
from q2
union 
select * 
from q1
)
select * from total_tbl 

order by los 



