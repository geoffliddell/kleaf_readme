# Inserting the following line into simul_abc.R just before 'test':
# > debug(model_Kleaf)
# then clicking through until Rleaf has been formed
# then running this script

Rvein_BB <- range(Rvein[[1]])
write(Rvein_BB, file = "Rvein_BB.csv")



Rmeso_BB <- range(Rmeso[[1]])
write(Rmeso_BB, file = "Rmeso_BB.csv")


mResistances <- as.data.frame(cbind(Rx[data$ratio > sa[[1]]], Rmeso[[1]][data$ratio > sa[[1]]]))
colnames(mResistances) <- c("Rvein", "Rmeso")

write_csv(mResistances, file = "mResistances_BB.csv")