
bind.raster <- function(wash, rst, rst.nm){
    # gets raster values by watershed extraction (exact_extract is supposed to be faster than terra::extract)
    washout <- data.table(exactextractr::exact_extract(rst, wash, fun=c('mean', 'variance'), progress=TRUE, append_cols=names(wash)))
    setnames(washout, c('mean','variance'), paste0(rst.nm, c('_mean','_variance')))
    return(washout)
}

bind.vector <- function(tmpwash.dir, vec, vec.nm, wash.sv){
    # for obtaining average drought index from weekly drought shapefiles
    washout <- terra::zonal(vect(vec), vect(tmpwash.dir), fun='mean', na.rm=TRUE, as.polygons=TRUE, weighted=TRUE)
    drtnm <- paste0(vec.nm, vec$week[1])
    names(washout)[names(washout) == 'DM'] <- drtnm
    washout2 <- data.table(values(washout))[,.SD, .SDcols=c('tnmid','huc12', drtnm)]
    washout2 <- washout2[!is.na(washout2[,.SD,.SDcols=drtnm])[,1],]
    return(washout2)
}
