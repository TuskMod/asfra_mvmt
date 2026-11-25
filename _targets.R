
# _targets.R

## replaces regen_contus.R adapted from Will's work with the feral swine movement estimates by watershed for that paper
# Targets setup --------------------
# setwd(this.path::this.dir())

#load libraries for targets script
library(targets)
# library(tarchetypes)
# library(data.table)
# library(geotargets)
# library(terra)
library(crew)
library(crew.cluster)

# This hardcodes the absolute path in _targets.yaml, so to make this more
# portable, we rewrite it every time this pipeline is run (and we don't track
# _targets.yaml with git)
# i.e. _targets.yaml is an optional file that sets defaults for tar_make() via
# tar_config_get(), so with cluster hpc whatever computing these change the
# default values to those that would be helpful for that...

tar_config_set(
#   store = here::here("_targets"),
#   store = file.path(this.path::this.dir(),"_targets"),
  store = file.path("_targets"),
#   script = here::here("_targets.R")
#   script = file.path(this.path::this.dir(),"_targets.R")
  script = file.path("_targets.R")
)

control_tall <- crew::crew_controller_local(
    name = 'tall_crew'
    , workers=1
)

control_duo <- crew::crew_controller_local(
    name = 'duo_crew'
    , workers=2
)

control_wide <- crew::crew_controller_local(
    name = 'wide_crew'
    , workers=4
)
# slurmy_try <- crew.cluster::crew_controller_slurm(
#                                 name='slurmy',
#                                 workers=2,
# #                                 host=nanonext::ip_addr()['enp2s0f4u1u2c2'],
#                                 options_cluster = crew_options_slurm(
#                                         partition='scicomp-compute',
#                                         command_submit = as.character(Sys.which("sbatch")),
#                                         script_lines=c('#SBATCH --account=eric.sodja',
#                                                        '#SBATCH --nodes=2',
# #                                                            '#SBATCH --partition=scicomp-compute'
#                                                        'conda activate contus_run',
#                                                        'module load anaconda3',
#                                                        'module load openssl',
#                                                        'module load R',
#                                                          'export RENV_CONFIG_PAK_ENABLED=TRUE'
# #                                                        'module load gcc12/12.2.0'
#                                                                         ),
#                                         cpus_per_task=4,
#                                         memory_gigabytes_per_cpu=4,
#                                         log_error='./log/%A_%j.err',
#                                         log_output='./log/%A_%j.out',
#                                         verbose=TRUE,
#                                         n_tasks=100,
#                                         script_directory='./tryscript/'
#                                     )
#                                 )
#Load packages
tar_option_set(packages = c('sf','terra','data.table','gbm', 'daymetr','exactextractr','raster'),
                ,error = 'stop' # for troubleshooting
#                ,error = 'null' # for production runs -- stops the errored cases and flags them for re-running later, but lets other things continue
               ,deployment='worker'
               ,garbage_collection=TRUE
               ,workspace_on_error=TRUE
               , memory='transient'
#                , controller = crew_controller_group(control_tall, control_wide, slurmy_try)
               , controller = crew_controller_group(control_tall, control_duo, control_wide)
#                , controller = crew_controller_group(slurmy_try)
               , resources= tar_resources(crew=tar_resources_crew(controller = 'tall_crew'))
#                , resources= tar_resources(crew=tar_resources_crew(controller = 'duo_crew'))
#                , resources= tar_resources(crew=tar_resources_crew(controller = 'wide_crew'))
#                , controller = slurmy_try
#                , resources= tar_resources(crew=tar_resources_crew(controller = 'slurmy'))
)

# Source functions in pipeline (could also be handled by tar_source(), in theory, but I can't get that to work...)
# lapply(list.files(file.path("scripts"), full.names = TRUE, recursive = TRUE), source)
tar_source('./scripts/')


# Pipeline ---------------------------------------------------------

list(
    # read in contiguous US borders
    tar_target(us.poly.path, './data/usmapplot_best.shp', format='file')
    , tar_target(us.poly, st_transform(st_cast(st_as_sf(st_read(dsn = us.poly.path, layer='usmapplot_best')), "MULTIPOLYGON"), crs='epsg:5070'))
    # get rid of state borders
    , tar_target(us.agg, st_union(us.poly))
    # shift to extract land cover data (faster to transform than changing watershed shapefiles before subsetting)
    , tar_target(usagg.int, st_transform(us.agg, 'epsg:4269'))

    # get huc12 watersheds for the whole contiguous US
    , tar_target(wash.path, './data/Input/Watershed_Boundary_HUC12_5627217451750735700.gpkg', format='file')
    , tar_target(wash0, st_intersection(st_read(wash.path), usagg.int))
    , tar_target(wash, st_transform(wash0, 'epsg:5070')[,c('tnmid','huc12')])
    , tar_target(tmpwash.dir, './data/tmpwash/')
    , tar_target(wash.sv, st_write(wash, paste0(tmpwash.dir, 'tmpwash.shp'), driver='ESRI Shapefile', append=FALSE))

    , tar_target(lcd.path, '../NND_Lands/input/Annual_NLCD_LndCov_2021_CU_C1V1/Annual_NLCD_LndCov_2021_CU_C1V1.tif', format='file') # land cover data at 30m resolution
    , tar_target(lcd, raster(project(rast(lcd.path), 'epsg:5070')))


    # tree cover
    , tar_target(tc.path, '../Pipeline_SSF_Weekly/2_Data/Input/tc_5070.tif', format='file')
    , tar_target(tc, raster(tc.path))

    # roads
    , tar_target(rd1.path, '../Pipeline_SSF_Weekly/2_Data/Input/final_roads1.tif', format='file')
    , tar_target(rd1, raster(project(rast(rd1.path), 'epsg:5070')))
    , tar_target(rd2.path, '../Pipeline_SSF_Weekly/2_Data/Input/final_roads2.tif', format='file')
    , tar_target(rd2, raster(project(rast(rd2.path), 'epsg:5070')))
    , tar_target(rd3.path, '../Pipeline_SSF_Weekly/2_Data/Input/final_roads3.tif', format='file')
    , tar_target(rd3, raster(project(rast(rd3.path), 'epsg:5070')))

    # ruggedness
    , tar_target(rgd.path, '../Pipeline_SSF_Weekly/2_Data/Input/rgd_5070.tif', format='file')
    , tar_target(rgd, raster(project(rast(rgd.path), 'epsg:5070')))

    # drought by quarter
    , tar_target(drtshps.list,  list.files('./data/2021_USDM_M/', full.names=TRUE, pattern='.shp$'))
    , tar_target(wk.index, 1:52)
    , tar_target(drtshps, read.drts(wk.index, drtshps.list), pattern=map(wk.index))

    # masting species
    , tar_target(mast.path, '../Pipeline_SSF_Weekly/2_Data/Input/mast_5070.tif', format='file')
    , tar_target(mast, raster(mast.path))

    ## extracting data and summerizing by watersheds
    # counts up the proportion of watersheds covered by a given type of land cover (i.e. dummy variables for model fits)
    , tar_target(tmplcd.dir, './data/lcd_tiles/')#, format='file')
    , tar_target(lcd.tiles, make.lcd.tiles(lcd, tmplcd.dir))
    , tar_target(lcd.count, lcdcount(lcd.tiles, tmpwash.dir), pattern=map(lcd.tiles), iteration='list')
    , tar_target(lcd.tab, make.lcd.tab(lcd.count))

    , tar_target(washtc, bind.raster(wash, tc, 'tc'))

    # roads
    , tar_target(washrd1, bind.raster(wash, rd1, 'rd1'))
    , tar_target(washrd2, bind.raster(wash, rd2, 'rd2'))
    , tar_target(washrd3, bind.raster(wash, rd3, 'rd3'))

    # masting species
    , tar_target(washmast, bind.raster(wash, mast, 'mast'))

    # ruggedness
    , tar_target(washrgd, bind.raster(wash, rgd, 'rgd'))

    # drought
    , tar_target(washdrt, bind.vector(paste0(tmpwash.dir, 'tmpwash.shp'), drtshps, 'drt', wash.sv), pattern=map(drtshps))
    , tar_target(washdrt2, unique(washdrt[,names(.SD) := lapply(.SD, max, na.rm=TRUE), by=.(tnmid, huc12)]))
    , tar_target(washdrt.mv, washdrt2[, drt_m := rowMeans(.SD, na.rm=TRUE), .SDcols=patterns('drt[0-9]')][, drt_var := apply(.SD, 1, 'var', na.rm=TRUE), .SDcols=patterns('drt[0-9]')])

    # climate data
    , tar_target(wash.centers, data.table(crds(centroids(vect(paste0(tmpwash.dir, 'tmpwash.shp')), inside=TRUE), df=TRUE)))
    , tar_target(wash.centers2, cbind(wash.centers, relate(vect(wash.centers), vect(tmpwash.dir), 'within', pairs=TRUE, na.rm=FALSE)))
    , tar_target(wash.centers3, setnames(wash.centers2, c('id.x','id.y'), c('id.cent','id.wash')))
    , tar_target(wash.centers4, as.data.table(terra::project(vect(wash.centers3, crs='epsg:5070'), 'epsg:4326'), geom='xy')[,.(site=id.wash, lat=y, log=x)])
    , tar_target(daymets, get.daymets(wash.centers4), pattern=map(wash.centers4), iteration='vector')
    , tar_target(daymets_5070, st_transform(st_as_sf(daymets, coords=c('lon','lat'), crs=4326), 'epsg:5070'))
    , tar_target(daymets_huc, data.table(terra::merge(daymets_5070, terra::extract(terra::vect(paste0(tmpwash.dir, 'tmpwash.shp')), terra::vect(daymets_5070)), by.x='ID', by.y='id.y')))

    # connect all the data together
    , tar_target(wash.mrg, Reduce(function(...) merge(..., all=TRUE, by=c('tnmid', 'huc12')), list(daymets_huc, washdrt.mv, washrgd, washmast, washrd1, washrd2, washrd3, washtc, lcd.tab)))


    ## generating predictions
    , tar_target(daily_displacement_mu_model, read.model('sl_mean', home='./', k='5', save_str='weeklyMay572026'))
    , tar_target(daily_displacement_disp_model, read.model('sl_disp', home='./', k='5', save_str='weeklyMay572026'))
#     , tar_target(net_displacement_mu_model, read.model('displ_mean', home='./', k='5', save_str='weeklyMay572026'))
#     , tar_target(net_displacement_disp_model, read.model('displ_disp', home='./', k='5', save_str='weeklyMay572026'))
    , tar_target(wash.nms, fix.names(wash.mrg))
    , tar_target(washdat.preds, getpreds(wash.nms, daily_displacement_mu_model, daily_displacement_disp_model))

#     , tar_target(wash.sv2, saveRDS(st_as_sf(washdat.preds), 'predwash.rds'))
    , tar_target(wash.sv2, saveRDS(st_as_sf(terra::merge(vect(paste0(tmpwash.dir, 'tmpwash.shp')), washdat.preds, on='huc12')), 'predwash.rds'))

    ## testing predictions (i.e. testing against original outputs from pig range)

    , tar_target(oldpreds, readRDS('../Pipeline_R3/watershed_weekly.rds'))
#     , tar_target(oldpreds, readRDS('../Pipeline_R3/watershed_minimum_weekly.rds'))
    , tar_target(olddat, getolddat(oldpreds))
    , tar_target(pig.range, '../Pipeline_SSF_Weekly/2_Data/Input/merged_conus.shp', format='file')
    , tar_target(newdat, getnewdat(washdat.preds, pig.range))
    , tar_target(combo, olddat[newdat, on=.(huc12=huc12_new)])
    , tar_target(lndvar, c('lc','tc','rd','mast','rgd','prcp','tmax','tmin','drt','dayl', 'weekly_displacement_shape', 'weekly_displacement_rate'))
    # if they are coming out the same, should follow roughly a 1:1 relationship on the same scale on these plots
    # some things will be different because of the different ways I did data extraction from rasters and vectors (area-weighted zonal statistics vs. point extractions)
    , tar_target(compare.plots, plot.newold(combo, newdat, olddat, lndvar), pattern=map(lndvar))

) # end targets list

