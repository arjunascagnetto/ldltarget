# =====================================================================
# Modello di Fine-Gray (subdistribution hazard) per il raggiungimento
# del target LDL, con la MORTE come evento competitivo.
#
# Evento di interesse : target raggiunto (status=1)
# Evento competitivo  : morte            (status=2)
# Censura             : status=0
#
# Implementazione: survival::finegray (dataset pesato) + coxph.
# Da' gli stessi stimatori di cmprsk::crr ma scala a coorti grandi.
#
# Covariate (basale): eta', sesso, classe di rischio, LDL indice, terapia.
# Output: subdistribution Hazard Ratio (sHR) con IC 95% e p.
#
#   ldltarget/src      -> codice (questo file)
#   ldltarget/reports  -> tabella risultati
# =====================================================================

suppressMessages(library(survival))

data_dir   <- "D:/SAS-CCV/DOWNLOAD/DAICHILDL/longitudinal/data"
proj_dir   <- "D:/SAS-CCV/DOWNLOAD/DAICHILDL/ldltarget"
report_dir <- file.path(proj_dir, "reports")

# --- Dati ------------------------------------------------------------
d <- read.csv(file.path(data_dir, "LDLFUP_TARGET.csv"),
              sep = ";", stringsAsFactors = FALSE)
d <- d[!is.na(d$tempo) & d$tempo >= 0 & d$status %in% c(0,1,2), ]

# casi completi sulle covariate
d <- d[!is.na(d$age) & !is.na(d$ldl_indice) &
       d$gender %in% c("M","F") & !is.na(d$classe) &
       d$terapia %in% c(0,1), ]

# --- Covariate -------------------------------------------------------
d$age10  <- d$age / 10                         # eta' per 10 anni
d$ldl10  <- d$ldl_indice / 10                  # LDL per 10 mg/dL
d$classe <- relevel(factor(d$classe), ref = "4")   # ref = classe 4
d$gender <- relevel(factor(d$gender), ref = "F")   # ref = femmine
d$terapia<- factor(d$terapia, levels = c(0,1), labels = c("No","Si"))

# stato come fattore: 1o livello = censura, poi eventi
d$evento <- factor(d$status, levels = c(0,1,2),
                   labels = c("censor","target","morte"))

# --- Dataset pesato per l'evento di interesse "target" ---------------
fg <- finegray(Surv(tempo, evento) ~ ., data = d, etype = "target")

# --- Modello di Fine-Gray (coxph sui pesi) ---------------------------
m <- coxph(Surv(fgstart, fgstop, fgstatus) ~
             age10 + gender + classe + ldl10 + terapia,
           data = fg, weights = fgwt)

sm <- summary(m)
res <- data.frame(
  variabile = rownames(sm$coef),
  sHR       = round(sm$conf.int[, "exp(coef)"], 3),
  IC_low    = round(sm$conf.int[, "lower .95"], 3),
  IC_up     = round(sm$conf.int[, "upper .95"], 3),
  p_value   = signif(sm$coef[, "Pr(>|z|)"], 3),
  row.names = NULL
)

# --- Report ----------------------------------------------------------
rep_file <- file.path(report_dir, "finegray_target.txt")
sink(rep_file)
cat("======================================================================\n")
cat(" MODELLO DI FINE-GRAY - raggiungimento target LDL\n")
cat(" Evento competitivo: morte. sHR = subdistribution Hazard Ratio.\n")
cat(" Implementazione: survival::finegray + coxph (dataset pesato).\n")
cat(" Generato:", format(Sys.time(), "%Y-%m-%d %H:%M"), "\n")
cat("======================================================================\n\n")
cat("N pazienti:", nrow(d),
    "| target:", sum(d$status==1),
    "| morte:",  sum(d$status==2),
    "| censurati:", sum(d$status==0), "\n\n")
cat("Referenze: classe=4, sesso=F, terapia=No.\n")
cat("Scale: age10 = eta'/10 anni; ldl10 = LDL_indice/10 mg/dL.\n\n")
cat("sHR > 1 -> maggiore incidenza cumulativa di raggiungimento target\n")
cat("sHR < 1 -> minore incidenza cumulativa di raggiungimento target\n\n")
print(res, row.names = FALSE)
cat("\nConcordanza (C):", round(sm$concordance["C"], 3),
    "| n eventi (target):", m$nevent, "\n")
sink()

cat("Report:", rep_file, "\n")
print(res, row.names = FALSE)
cat("FATTO.\n")
