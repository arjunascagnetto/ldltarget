d <- read.csv("D:/SAS-CCV/DOWNLOAD/DAICHILDL/longitudinal/data/LDLFUP_TARGET.csv",
              sep=";", stringsAsFactors=FALSE)
cat("N righe:", nrow(d), "| pazienti unici:", length(unique(d$KEY_ANAGRAFE)),"\n\n")
cat("status:\n"); print(table(d$status, useNA="ifany"))
cat("\nreached:\n"); print(table(d$reached, useNA="ifany"))
cat("\nreached x status:\n"); print(table(reached=d$reached, status=d$status, useNA="ifany"))
cat("\nclasse x soglia:\n"); print(table(classe=d$classe, soglia=d$soglia, useNA="ifany"))
cat("\nterapia:\n"); print(table(d$terapia, useNA="ifany"))
for (v in c("sta","eze","bem","inc","pcs")) {
  cat("\n", v, ":\n"); print(table(d[[v]], useNA="ifany"))
}
cat("\ntempo (giorni): "); print(summary(d$tempo))
cat("\nldl_indice: "); print(summary(d$ldl_indice))
cat("\n% data_event presente quando status==1: ",
    mean(d$data_event[d$status==1] != "" , na.rm=TRUE)*100, "\n")
cat("status x terapia:\n"); print(table(status=d$status, terapia=d$terapia))
