d <- read.csv("D:/SAS-CCV/DOWNLOAD/DAICHILDL/ldltarget/data/LDLFUP_TARGET.csv",
              sep=";", stringsAsFactors=FALSE)
drugs <- c("sta","eze","bem","inc","pcs")
m <- sapply(d[drugs], function(x) ifelse(is.na(x) | x=="", 0, 1))
nfarm <- rowSums(m)

cat("N farmaci per paziente (tra i 5 flag):\n")
print(table(nfarm))
cat("\n% pazienti con >=2 farmaci:",
    round(mean(nfarm>=2)*100,2), "%\n")
cat("Su quelli con terapia=1:\n")
print(table(nfarm[d$terapia==1]))

cat("\n--- Combinazioni piu' frequenti (pazienti con >=1 farmaco) ---\n")
combo <- apply(m, 1, function(r) paste(drugs[r==1], collapse="+"))
combo[combo==""] <- "(nessuno)"
print(head(sort(table(combo), decreasing=TRUE), 15))

cat("\n--- Coerenza: terapia=0 ma almeno un farmaco? ---\n")
print(table(terapia=d$terapia, ha_farmaco=as.integer(nfarm>=1)))
