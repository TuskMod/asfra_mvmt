
run.tc.var <- function(list, wash, tc){
    statevect <- wash[which(values(wash)[,'st.grp'] == list),]
    names(tc) <- 'tc_var'
    was.st <- terra::extract(tc, statevect, fun=var, bind=TRUE, na.rm=TRUE, touches=TRUE, small=TRUE)

    return(was.st)
}
