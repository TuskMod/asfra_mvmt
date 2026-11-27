
make.lcd.tab <- function(lcd.tab){

    lcd.tab <- rbindlist(lcd.tab[unlist(lapply(lcd.tab, is.data.table))], fill=TRUE)
    # if watersheds are on either side of a tile boundary, add up the cell counts from both sides and get one line per watershed
    lcd.tab[,names(.SD) := lapply(.SD, sum, na.rm=TRUE), .SDcols=patterns('count'), by=.(tnmid, huc12)]
    lcd.tab <- unique(lcd.tab)

    # total cells per watershed
#     lcd.tab[,names(.SD) := round(.SD), .SDcols=patterns('^count')]
    lcd.tab[,cnt_sum := rowSums(.SD), .SDcols=patterns('^count')]
    lcd.tab[,gsub('count','mean',names(.SD)) := .SD/cnt_sum, .SDcols=patterns('^count')]
    lcd.tab2 <- dcast(melt(lcd.tab, measure.vars=measure(meas, class, sep='.')), tnmid + huc12 + class ~ meas, value.var=c('value'))
    lcd.tab2[,var := mean*(1-mean)]

    lcd.tab3 <- dcast(lcd.tab2, tnmid + huc12~ class, value.var=c('mean','var'))
    setnames(lcd.tab3, gsub('mean','lc_mn',names(lcd.tab3)))
    setnames(lcd.tab3, gsub('var','lc_var',names(lcd.tab3)))


    return(lcd.tab3)
}
