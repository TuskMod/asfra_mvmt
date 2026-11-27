

getShape <- function(mean, dispersion){
    return(1/dispersion)
}
getRate <- function(mean, dispersion){
    return(1/(mean/(1/dispersion)))
}


fix.names <- function(wash){
    # make the names match what the models are expecting
    setnames(wash, names(wash[,.SD, .SDcols=patterns('lc_mn')]), gsub('lc_mn','mean_lc',names(wash[,.SD, .SDcols=patterns('lc_mn')])))
    setnames(wash, names(wash[,.SD, .SDcols=patterns('lc_var')]), gsub('lc_var','var_lc',names(wash[,.SD, .SDcols=patterns('lc_var')])))
    setnames(wash, c('drt_m', 'drt_var',
                  'rgd_mean', 'rgd_variance',
                  'mast_mean','mast_variance',
                  'rd1_mean', 'rd1_variance',
                  'rd2_mean','rd2_variance',
                  'rd3_mean','rd3_variance',
                  'tc_mean','tc_variance'),
                c('mean_drt','var_drt',
                  'mean_rgd', 'var_rgd',
                  'mean_mast','var_mast',
                  'mean_rd1', 'var_rd1',
                  'mean_rd2','var_rd2',
                  'mean_rd3','var_rd3',
                  'mean_tc','var_tc'))

    return(wash)
}



getpreds <- function(wash, mumod, dispmod){

    load(file=file.path('./',"models",paste0('GBM_parameters', '_random_','weeklyMay572026','_kfold_', '5', '.rds'), fsep = .Platform$file.sep))

    wash[, sl := predict.gbm(mumod, .SD, model_params['daily displacement mean',]['n_trees'][[1]], type='response')]
    wash[, sigma_sl := predict.gbm(dispmod, .SD, model_params['daily displacement disp',]['n_trees'][[1]], type='response')]
#     washdat[, disp := predict.gbm(net_displacement_mu_model, .SD, model_params['net displacement mean',]['n_trees'][[1]], type='response')]
#     washdat[, sigma_disp := predict.gbm(net_displacement_disp_model, .SD, model_params['net displacement disp',]['n_trees'][[1]], type='response')]

    wash[, weekly_displacement_shape := getShape(sl, sigma_sl)]
    wash[, weekly_displacement_rate := getRate(sl, sigma_sl)]

    return(wash)
}



getolddat <- function(oldies){
    # averages of old predictions to compare to new predictions (just to get a ballpark to make sure new ones are in the right range)
    olddt <- data.table(oldies)
    olddt[, mean_prcp := rowMeans(.SD), .SDcols=patterns('prcp_mn_q[1-4]')]
    olddt[, var_prcp := rowMeans(.SD), .SDcols=patterns('prcp_var_q[1-4]')]
    olddt[, mean_tmax := rowMeans(.SD), .SDcols=patterns('tmax_mn_q[1-4]')]
    olddt[, var_tmax := rowMeans(.SD), .SDcols=patterns('tmax_var_q[1-4]')]
    olddt[, mean_tmin := rowMeans(.SD), .SDcols=patterns('tmin_mn_q[1-4]')]
    olddt[, var_tmin := rowMeans(.SD), .SDcols=patterns('tmin_var_q[1-4]')]
    olddt[, mean_drt := rowMeans(.SD), .SDcols=patterns('drt_q[1-4]_mn')]
    olddt[, var_drt := rowMeans(.SD), .SDcols=patterns('drt_q[1-4]_var')]
    olddt[, mean_dayl := rowMeans(.SD), .SDcols=patterns('dayl_mn_q[1-4]')]
    olddt[, var_dayl := rowMeans(.SD), .SDcols=patterns('dayl_var_q[1-4]')]
    olddt <- olddt[,.SD, .SDcols=-patterns('q[1-4]')]
    return(olddt)
}

getnewdat <- function(newpreds, pig.range.dir){
    # crop the new predictions to the range of the old predictions so they are comparable to validate the new predictions
    wash.out <- terra::vect(st_as_sf(newpreds))
    pigd <- project(aggregate(vect(pig.range.dir), dissolve=TRUE), 'epsg:5070')

    newpig <- terra::intersect(wash.out, pigd)

    newdt <- data.table(values(newpig))
    newdt <- newdt[,.SD,.SDcols=-patterns('drt[0-9]')]
    newdt[is.na(mean_drt), mean_drt := 0]
    newdt[is.na(var_drt), var_drt := 0]

    setnames(newdt, names(newdt), paste0(names(newdt), '_new'))
    return(newdt)

}



plot.newold <- function(combo, newdt, olddt, lndvar){
    #plotting new vs. old inputs and outputs to make sure we are in the right ballpark
    # note-- the model doesn't use mean or variance of all roads, so ignore that one
    print(lndvar)
    x=sort(names(olddt[,.SD, .SDcols=patterns(lndvar)]))
    y=sort(names(newdt[,.SD, .SDcols=patterns(lndvar)]))

    if (lndvar == 'lc'){
        x <- x[-which(x %in% c('lc_mn_0','lc_var_0'))]
    }
    tot.vars <- ceiling(sqrt(length(x)))
    png(paste0('./check_plots/', lndvar, '.png'), width=400*tot.vars, height=500*tot.vars)
    par(mfrow=c(tot.vars, tot.vars))
    if (lndvar == 'rd') y <- y[c(1,4,2,5,3,6)]
    mapply(
       function(x, y){
           plot(combo[,.SD, .SDcols=c(x, y)], main=y)
        },
       x=x,
       y=y
    )
    dev.off()
}

## variables used as model inputs
# var_rd3
# var_rgd
# var_rd2
# var_mast
# mean_rd3
# mean_mast
# var_tmin
# mean_lc_82
# mean_lc_90
# mean_tc
# mean_rgd
# var_lc_82
# var_tmax
# mean_dayl
# var_rd1
# mean_tmax
# var_dayl
# var_tc
# mean_tmin
# mean_drt
# mean_prcp
# mean_lc_42
# mean_rd2
# var_lc_90
# var_prcp
# var_lc_42
# mean_rd1
# mean_lc_81
# mean_lc_41
# mean_lc_71
# mean_lc_95
# mean_lc_52
# var_lc_71
# var_lc_41
# var_lc_52
# var_lc_81
# var_drt
# mean_lc_21
# var_lc_95
# mean_lc_43
# var_lc_43
# mean_lc_22
# mean_lc_11
# mean_lc_23
# mean_lc_31
# mean_lc_24
# var_lc_21
# var_lc_11
# var_lc_23
# var_lc_22
# var_lc_31
# var_lc_24
