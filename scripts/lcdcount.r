

make.lcd.tiles <- function(lcd, dir){
    # creates subset tiles of land cover data at full resolution and saves in data file
    # using na.rm=FALSE and overwrite=FALSE together speeds things up, as empty tiles are saved and skipped instead of checked for raster coverage
    lcd.tiles <- terra::makeTiles(rast(lcd), 5000, filename=paste0(dir, 'lcd_.tif'), na.rm=FALSE, value='files', overwrite=FALSE)

    return(lcd.tiles)
}

lcdcount <- function(lcd, tmpwash.dir){
    lcd <- rast(lcd)
    if (all(values(is.na(lcd))) == FALSE){
        tmpwash <- st_as_sf(terra::intersect(vect(paste0(tmpwash.dir, 'tmpwash.shp')), terra::ext(lcd)))
        if (nrow(tmpwash) > 0){
            segtile <- segregate(lcd, other=NA) # errors if lcd is blank
            seg.table <- data.table(exact_extract(segtile, tmpwash, fun='count', progress=FALSE, append_cols=names(tmpwash)))
            return(seg.table)
        }
    } else {
        return(NA)
    }
}

