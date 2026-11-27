
read.model <- function(vnm, home, k, save_str){
    load(file.path(home,"models",paste0('GBM_', vnm,'_random_',save_str,'_kfold_', k, '.rds'), fsep = .Platform$file.sep))
    return(m)
}
