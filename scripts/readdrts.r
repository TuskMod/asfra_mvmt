

read.drts <- function(x, drtlist){
    inshp <- vect(drtlist[x])
    inshp$week <- x
    drtsout <- terra::project(inshp, 'epsg:5070')
    return(st_as_sf(drtsout))
}


