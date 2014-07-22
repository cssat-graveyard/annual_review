declare @fystart int
declare @fystop int

set @fystart = 2010
set @fystop = 2013;

select
  count(inf.id_intake_fact) I_R1
  ,sum(iif(inf.fl_ooh_after_this_referral=1, 1, 0)) P
  ,sum(iif(inf.fl_ooh_after_this_referral=1, 1, 0))*1.0/
	count(inf.id_intake_fact) PR
  ,cd.month
  ,cd.state_fiscal_yyyy fiscal_yr 
from ca_ods.dbo.calendar_dim cd
	left join dbCoreAdministrativeTables.dbo.tbl_intakes inf 
		on cd.id_calendar_dim between 
			convert(int, convert(varchar, inf.inv_ass_stop, 112)) 
			and convert(int, convert(varchar, inf.inv_ass_stop, 112))
where 
	cd.state_fiscal_yyyy between @fystart and @fystop
		and cd_access_type in (1, 4)
		and (inf.intake_rank = 1 or fl_ooh_prior_this_referral = 0)
group by 
  cd.month
  ,cd.state_fiscal_yyyy
order by 
	month
