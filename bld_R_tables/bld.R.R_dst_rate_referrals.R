library(RODBC)

library(knitr)

library(ggplot2)

con <- odbcConnect("POC")

dat <- sqlQuery(con, "select 
                rf.* 
                from
                ca_ods.prtl.rate_referrals rf
                join ca_ods.dbo.calendar_dim cd
                on cd.calendar_date = start_date
                where 
                state_fiscal_yyyy >= 2010")


dat <- dat[dat$start_date >= as.POSIXct('2009-06-30') & 
             dat$start_date < as.POSIXct('2014-07-01'),]

dat$trend <- NA

for (i in 0:39){
  for (j in 0:1){
    
    dat_ts <- ts(dat[dat$entry_point == j & dat$county_cd == i,8]
                 ,start=c(2009,7)
                 ,frequency=12)
    
    dst <- as.data.frame(stl(dat_ts, "per")$time.series)
    
    dat[dat$entry_point == j & dat$county_cd == i,]$trend <- dst$trend 
    
  }
}

dat$start_date <- strptime(dat$start_date, format="%Y-%m-%d")

sqlQuery(con, "drop table R.R_dst_rate_referrals")

sqlSave(con
        ,dat = dat[,c("start_date"
                      ,"county_cd"
                      ,"entry_point"
                      ,"referral_rate"
                      ,"trend")]
        ,tablename = "R.R_dst_rate_referrals"
        ,rownames = F)
