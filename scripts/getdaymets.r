
get.daymets <- function(coords){
    dat <- try(download_daymet(site = coords[[1]], lat=coords[[2]], lon=coords[[3]], silent=TRUE, start=2021, end=2021, simplify=FALSE), silent=TRUE)
    if (typeof(dat) =='list'){
        dmout <- data.table(ID=dat[[1]],
                            lat=dat[[3]],
                            lon=dat[[4]])
        dat <- data.table(dat[[7]])
        #     dmout <- cbind(dmout, dat[, mean(.SD), .SDcols=c('dayl..s.', 'prcp..mm.day.', 'tmax..deg.c.', 'tmin..deg.c.')])
        dmout <- cbind(dmout, dat[, lapply(.SD, mean), .SDcols=c(3,4,7,8)], dat[, lapply(.SD, var), .SDcols=c(3,4,7,8)])
    } else {
        dmout <- data.table(t(c(coords[[1]], coords[[2]], coords[[3]], rep(NA, 8))))

    }
    setnames(dmout, c('ID','lat','lon','mean_dayl','mean_prcp','mean_tmax','mean_tmin','var_dayl','var_prcp','var_tmax','var_tmin'))
    return(dmout)
}
