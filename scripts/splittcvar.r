
split.tc.var <- function(tc, wash){
    washtab <- data.table(values(wash))[,.(tnmid, states)]
    washtab[,state1 := tstrsplit(states, ',', keep=1)]
    washtab[,st.ct:= round(1:.N, -3)/1000, by=state1]
    washtab[,st.grp := paste0(state1, st.ct)]
    return(washtab)
}
