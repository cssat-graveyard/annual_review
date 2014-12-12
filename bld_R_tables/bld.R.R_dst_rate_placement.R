library(RODBC)

library(knitr)

library(ggplot2)

con <- odbcConnect("POC")

dat <- sqlQuery(con, "select 
                r.* 
                from
                ca_ods.prtl.rate_placement r
                join ca_ods.dbo.calendar_dim cd
                on cd.calendar_date = cohort_date
                where 
                state_fiscal_yyyy >= 2010")


dat <- dat[dat$cohort_date >= as.POSIXct('2009-06-30') & 
             dat$cohort_date < as.POSIXct('2014-07-01'),]

dat$trend <- NA

for (i in 0){
  for (j in 0:1){
    
    dat_ts <- ts(dat[dat$entry_point == j & dat$county_cd == i,8]
                 ,start=c(2009,7)
                 ,frequency=12)
    
    dst <- as.data.frame(stl(dat_ts, "per")$time.series)
    
    dat[dat$entry_point == j & dat$county_cd == i,]$trend <- dst$trend 
    
  }
}

dat$cohort_date <- strptime(dat$cohort_date, format="%Y-%m-%d")

sqlQuery(con, "drop table R.R_dst_rate_placement")

sqlSave(con
        ,dat = dat[,c("cohort_date"
                      ,"county_cd"
                      ,"entry_point"
                      ,"rate_placement"
                      ,"trend")]
        ,tablename = "R.R_dst_rate_placement"
        ,rownames = F)
