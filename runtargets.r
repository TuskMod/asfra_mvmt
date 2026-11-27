
# .libPaths("/home/eric.sodja/.conda/envs/asfra_run/lib/R/library")
#source targets file
source("_targets.R")


#Make pipeline
# for troubleshooting
# tar_make(callr_function = NULL, use_crew=FALSE, as_job=FALSE, shortcut=FALSE, names=washdrt.mv)

tar_make(use_crew=TRUE)
