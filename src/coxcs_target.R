# =====================================================================
# Modello di Cox CAUSA-SPECIFICO per il raggiungimento del target LDL.
#
# Evento di interesse : target raggiunto (status=1)
# La MORTE (status=2) viene trattata come CENSURA (cause-specific hazard).
#
# Stessa specifica del Fine-Gray, per confronto diretto sHR vs HR.
# Covariate (basale): eta', sesso, classe di rischio, LDL indice, terapia.
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
d <- d[!is.na(d$age) & !is.na(d$ldl_indice) &
       d$gender %in% c("M","F") & !is.na(d$classe) &
       d$terapia %in% c(0,1), ]

# --- Covariate (stesse referenze del Fine-Gray) ----------------------
d$age10  <- d$age / 10
d$ldl10  <- d$ldl_indice / 10
d$classe <- relevel(factor(d$classe), ref = "4")
d$gender <- relevel(factor(d$gender), ref = "F")
d$terapia<- factor(d$terapia, levels = c(0,1), labels = c("No","Si"))

# evento causa-specifico: 1 = target raggiunto; morte e censura -> 0 (censura)
d$ev_target <- as.integer(d$status == 1)

# --- Cox causa-specifico ---------------------------------------------
m <- coxph(Surv(tempo, ev_target) ~
             age10 + gender + classe + ldl10 + terapia, data = d)

sm <- summary(m)
res <- data.frame(
  variabile = rownames(sm$coef),
  HR        = round(sm$conf.int[, "exp(coef)"], 3),
  IC_low    = round(sm$conf.int[, "lower .95"], 3),
  IC_up     = round(sm$conf.int[, "upper .95"], 3),
  p_value   = signif(sm$coef[, "Pr(>|z|)"], 3),
  row.names = NULL
)

# --- Report ----------------------------------------------------------
rep_file <- file.path(report_dir, "coxcs_target.txt")
sink(rep_file)
cat("======================================================================\n")
cat(" COX CAUSA-SPECIFICO - raggiungimento target LDL\n")
cat(" La morte e' trattata come censura (cause-specific hazard).\n")
cat(" HR = cause-specific Hazard Ratio.\n")
cat(" Generato:", format(Sys.time(), "%Y-%m-%d %H:%M"), "\n")
cat("======================================================================\n\n")
cat("N pazienti:", nrow(d),
    "| eventi target:", sum(d$ev_target),
    "| (morti+censure trattati come censura):", sum(d$ev_target==0), "\n\n")
cat("Referenze: classe=4, sesso=F, terapia=No.\n")
cat("Scale: age10 = eta'/10 anni; ldl10 = LDL_indice/10 mg/dL.\n\n")
cat("HR > 1 -> maggiore hazard ISTANTANEO di raggiungere il target\n")
cat("HR < 1 -> minore hazard istantaneo\n\n")
print(res, row.names = FALSE)
cat("\nConcordanza (C):", round(sm$concordance["C"], 3), "\n")
cat("Test PH globale (cox.zph) salvato sotto.\n\n")
print(cox.zph(m))
sink()

cat("Report:", rep_file, "\n")
print(res, row.names = FALSE)
cat("FATTO.\n")
