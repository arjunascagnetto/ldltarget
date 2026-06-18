# =====================================================================
# Descrittiva: distribuzione classi di rischio per fasce di eta'
# Coorte: pazienti presenti nel file FARMACEUTICA (chi ha >=1 prescrizione)
# Date in formato SAS/americano DATE9 (es. 08OCT2022)
#
# Struttura progetto:
#   ldltarget/src      -> codice (questo file)
#   ldltarget/reports  -> report testuali
#   ldltarget/outputs  -> figure
# =====================================================================

proj_dir    <- "D:/SAS-CCV/DOWNLOAD/DAICHILDL/ldltarget"
data_dir    <- file.path(proj_dir, "data")
report_dir  <- file.path(proj_dir, "reports")
output_dir  <- file.path(proj_dir, "outputs")

# --- parser robusto per date DATE9 (mesi in inglese maiuscolo) ---
parse_date9 <- function(x) {
  x <- toupper(trimws(as.character(x)))
  x[x == "" | x == "."] <- NA
  mesi <- c(JAN=1,FEB=2,MAR=3,APR=4,MAY=5,JUN=6,
            JUL=7,AUG=8,SEP=9,OCT=10,NOV=11,DEC=12)
  gg   <- as.integer(substr(x, 1, 2))
  mmm  <- substr(x, 3, 5)
  aaaa <- as.integer(substr(x, 6, 9))
  mm   <- mesi[mmm]
  out  <- rep(as.Date(NA), length(x))
  ok   <- !is.na(gg) & !is.na(mm) & !is.na(aaaa)
  out[ok] <- as.Date(sprintf("%04d-%02d-%02d", aaaa[ok], mm[ok], gg[ok]))
  out[!is.na(aaaa) & aaaa >= 9999] <- NA   # sentinella 31DEC9999 -> NA
  out
}

# --- 1) Apertura file farmaceutica con parsing date ---
farm <- read.csv(file.path(data_dir, "LDLFUP_FARMACEUTICA.csv"),
                 sep = ";", stringsAsFactors = FALSE)
farm$data_indice       <- parse_date9(farm$data_indice)
farm$DATA_PRESCRIZIONE <- parse_date9(farm$DATA_PRESCRIZIONE)

# --- 2) Eta' (dal TARGET) SOLO per i pazienti presenti nel farmaceutica ---
tg  <- read.csv(file.path(data_dir, "LDLFUP_TARGET.csv"),
                sep = ";", stringsAsFactors = FALSE)
tg1 <- tg[!duplicated(tg$KEY_ANAGRAFE), c("KEY_ANAGRAFE","age","classe")]

id_farm <- unique(farm$KEY_ANAGRAFE)
pz <- tg1[tg1$KEY_ANAGRAFE %in% id_farm, ]
pz <- pz[!is.na(pz$classe), ]

# fasce di eta'
br  <- c(-Inf, 55, 65, 75, 85, Inf)
lab <- c("<55","55-64","65-74","75-84","85+")
pz$fascia <- cut(pz$age, breaks = br, labels = lab, right = FALSE)
pz$classe <- factor(pz$classe, levels = sort(unique(pz$classe)))

tab  <- table(Fascia = pz$fascia, Classe = pz$classe)
prow <- round(prop.table(tab, 1) * 100, 1)
pcol <- round(prop.table(tab, 2) * 100, 1)

# --- 3) REPORT testuale ---
report_file <- file.path(report_dir, "descrittiva_classe_eta.txt")
sink(report_file)
cat("======================================================================\n")
cat(" DESCRITTIVA: CLASSE DI RISCHIO x FASCIA DI ETA'\n")
cat(" Coorte: pazienti con >=1 prescrizione nel file FARMACEUTICA\n")
cat(" Generato:", format(Sys.time(), "%Y-%m-%d %H:%M"), "\n")
cat("======================================================================\n\n")

cat("=== FILE FARMACEUTICA ===\n")
cat("Righe (prescrizioni):", nrow(farm), "\n")
cat("Pazienti distinti    :", length(id_farm), "\n")
cat("Range data_indice    :", format(range(farm$data_indice, na.rm=TRUE)), "\n")
cat("Range data_prescriz. :", format(range(farm$DATA_PRESCRIZIONE, na.rm=TRUE)),
    "  (NB: presenti date future, da verificare)\n\n")

cat("=== POPOLAZIONE ANALIZZATA (livello paziente) ===\n")
cat("N pazienti con classe nota:", nrow(pz), "\n")
cat("Eta': media", round(mean(pz$age,na.rm=TRUE),1),
    "| mediana", median(pz$age,na.rm=TRUE),
    "| range", paste(range(pz$age,na.rm=TRUE), collapse="-"), "\n\n")

cat("--- Conteggi (n) ---\n");           print(addmargins(tab))
cat("\n--- % di riga (classi entro fascia) ---\n");  print(prow)
cat("\n--- % di colonna (eta' entro classe) ---\n"); print(pcol)
cat("\n--- Distribuzione complessiva classi (%) ---\n")
print(round(prop.table(table(pz$classe)) * 100, 1))
cat("\n--- Distribuzione complessiva fasce eta' (%) ---\n")
print(round(prop.table(table(pz$fascia)) * 100, 1))
sink()
cat("Report scritto in:", report_file, "\n")

# --- 4) FIGURE ---
cols <- c("#4DAF4A","#FFD92F","#FF7F00","#E41A1C")  # classi 1..4

# (a) barre impilate % per fascia di eta'
fig1 <- file.path(output_dir, "classe_per_fascia_eta_pct.png")
png(fig1, width = 1000, height = 700, res = 130)
barplot(t(prop.table(tab, 1) * 100), beside = FALSE, col = cols,
        xlab = "Fascia di eta'", ylab = "% pazienti",
        main = "Distribuzione classi di rischio per fascia di eta' (%)",
        legend.text = paste("Classe", levels(pz$classe)),
        args.legend = list(x = "topright", bty = "n", inset = c(-0.02,0)))
dev.off()

# (b) barre raggruppate conteggi
fig2 <- file.path(output_dir, "classe_per_fascia_eta_conteggi.png")
png(fig2, width = 1000, height = 700, res = 130)
barplot(t(tab), beside = TRUE, col = cols,
        xlab = "Fascia di eta'", ylab = "N pazienti",
        main = "Classi di rischio per fascia di eta' (conteggi)",
        legend.text = paste("Classe", levels(pz$classe)),
        args.legend = list(x = "topleft", bty = "n"))
dev.off()

cat("Figure scritte in:", fig1, "e", fig2, "\n")
cat("FATTO.\n")
