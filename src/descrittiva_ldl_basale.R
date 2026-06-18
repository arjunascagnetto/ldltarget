# =====================================================================
# Descrittiva dell'LDL al basale (ldl_indice) per classe di rischio
#   ldltarget/src      -> codice (questo file)
#   ldltarget/reports  -> tabella
#   ldltarget/outputs  -> figura (boxplot)
# =====================================================================

data_dir   <- "D:/SAS-CCV/DOWNLOAD/DAICHILDL/longitudinal/data"
proj_dir   <- "D:/SAS-CCV/DOWNLOAD/DAICHILDL/ldltarget"
report_dir <- file.path(proj_dir, "reports")
output_dir <- file.path(proj_dir, "outputs")

d <- read.csv(file.path(data_dir, "LDLFUP_TARGET.csv"),
              sep = ";", stringsAsFactors = FALSE)
d <- d[!is.na(d$ldl_indice) & !is.na(d$classe), ]
d$classe <- factor(d$classe, levels = 1:4)

# soglia target per classe (per confronto)
soglia <- c("1"=116, "2"=100, "3"=70, "4"=55)

# statistiche per classe
descr <- do.call(rbind, lapply(levels(d$classe), function(k) {
  x <- d$ldl_indice[d$classe == k]
  data.frame(
    classe   = k,
    n        = length(x),
    soglia   = soglia[k],
    media    = round(mean(x), 1),
    sd       = round(sd(x), 1),
    mediana  = round(median(x), 1),
    Q1       = round(quantile(x, .25), 1),
    Q3       = round(quantile(x, .75), 1),
    min      = round(min(x), 1),
    max      = round(max(x), 1),
    # % gia' sotto soglia al basale
    pct_sotto_soglia = round(mean(x < soglia[k]) * 100, 1)
  )
}))

# test globale (LDL basale differisce tra classi?)
kt <- kruskal.test(ldl_indice ~ classe, data = d)

# --- Report ----------------------------------------------------------
rep_file <- file.path(report_dir, "descrittiva_ldl_basale.txt")
sink(rep_file)
cat("======================================================================\n")
cat(" LDL AL BASALE (ldl_indice) PER CLASSE DI RISCHIO\n")
cat(" Generato:", format(Sys.time(), "%Y-%m-%d %H:%M"), "\n")
cat("======================================================================\n\n")
cat("N totale:", nrow(d), "| LDL complessivo: media",
    round(mean(d$ldl_indice),1), " mediana", round(median(d$ldl_indice),1), "mg/dL\n\n")
print(descr, row.names = FALSE)
cat("\n'pct_sotto_soglia' = % pazienti gia' sotto il target LDL al basale.\n")
cat("\nKruskal-Wallis (LDL basale tra classi): chi2 =",
    round(kt$statistic,1), " df =", kt$parameter,
    " p =", format.pval(kt$p.value, eps=1e-10), "\n")
sink()

# --- Figura: boxplot LDL basale per classe ---------------------------
fig <- file.path(output_dir, "ldl_basale_per_classe.png")
png(fig, width = 1000, height = 700, res = 130)
cols <- c("#4DAF4A","#FFD92F","#FF7F00","#E41A1C")
bp <- boxplot(ldl_indice ~ classe, data = d, col = cols, outline = FALSE,
              xlab = "Classe di rischio", ylab = "LDL al basale (mg/dL)",
              main = "LDL al basale per classe di rischio")
# linea della soglia target per ciascuna classe
for (i in 1:4) segments(i-0.4, soglia[i], i+0.4, soglia[i],
                        col = "black", lwd = 2, lty = 2)
legend("topright", bty = "n", lty = 2, lwd = 2,
       legend = "soglia target di classe")
dev.off()

cat("Report:", rep_file, "\nFigura:", fig, "\n")
print(descr, row.names = FALSE)
cat("FATTO.\n")
