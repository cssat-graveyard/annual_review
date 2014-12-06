select 
  [CEDARS File B].[Research ID] as id
  ,[CEDARS File B].[School Year] as year
  ,min([CEDARS File I].[Start Date]) as min_fc_start_date
  ,[Calculated Age at School Year Begin] a
  ,[CEDARS File B].[Grade Level] g
into [Population Table]
from [CEDARS File B]
join [CEDARS File I]
  on [CEDARS File B].[Research ID] = [CEDARS File I].[Research ID] 
    and [CEDARS File B].[School Year] = [CEDARS File I].[School Year] 
where 
  [Free/Reduced-Price Meal Eligibility Status] = 
    [8–Free via foster child income status]
group by 
  [CEDARS File B].[Research ID]
  ,[CEDARS File B].[School Year] 
  ,[Calculated Age at School Year Begin]
  ,[CEDARS File B].[Grade Level]


select 
  count(id) anyNp
  ,sum(if(month(min_fc_start_date)=9, 1, 0)) startNp
  ,year
  ,a
  ,g
from [Population Table]
group by 
  year
  ,a
  ,g