# =====================================================================
# CIF (incidenza cumulativa) del raggiungimento del target LDL
# Evento di interesse: target raggiunto (status=1)
# Evento competitivo : morte (status=2)
# Stimatore: Aalen-Johansen (survival::survfit) + test di Gray (cmprsk)
# Stratificazioni: classe di rischio (1-4) e terapia (0/1)
#
#   ldltarget/src      -> codice (questo file)
#   ldltarget/reports  -> tabelle CIF
#   ldltarget/outputs  -> figure
# =====================================================================

suppressMessages({
  library(survival)
  library(cmprsk)
})

data_dir   <- "D:/SAS-CCV/DOWNLOAD/DAICHILDL/longitudinal/data"
proj_dir   <- "D:/SAS-CCV/DOWNLOAD/DAICHILDL/ldltarget"
report_dir <- file.path(proj_dir, "reports")
output_dir <- file.path(proj_dir, "outputs")

# --- Dati ------------------------------------------------------------
d <- read.csv(file.path(data_dir, "LDLFUP_TARGET.csv"),
              sep = ";", stringsAsFactors = FALSE)

# pulizia minima: tempo valido e status atteso
d <- d[!is.na(d$tempo) & d$tempo >= 0 & d$status %in% c(0,1,2), ]

# stato come fattore (1 livello = censura)
d$status_f <- factor(d$status, levels = c(0,1,2),
                     labels = c("censor","target","morte"))

# tempi di valutazione (giorni) per le tabelle: da 1 a 6 anni
land_anni <- 1:6
land_m    <- land_anni * 12
land_d    <- land_anni * 365.25

# colori per gruppi
col_classe  <- c("#4DAF4A","#FFD92F","#FF7F00","#E41A1C")   # 1..4
col_terapia <- c("#377EB8","#E41A1C")                       # 0,1

# --- Funzione: CIF Aalen-Johansen per un raggruppamento ---------------
# group_var: nome colonna (fattore); restituisce survfit multi-stato
fit_aj <- function(dat) {
  survfit(Surv(tempo, status_f) ~ 1, data = dat)
}

# estrae CIF (pstate) del target ai tempi richiesti, con IC
cif_at_times <- function(fit, state = "target", times = land_d) {
  s  <- summary(fit, times = times, extend = TRUE)
  st <- which(fit$states == state)
  # summary restituisce matrici quando multi-stato
  data.frame(
    tempo_gg = s$time,
    cif      = s$pstate[, st],
    lower    = s$lower[, st],
    upper    = s$upper[, st]
  )
}

# --- Analisi per una variabile di stratificazione ---------------------
analizza <- function(group_var, cols, etichette = NULL, file_tag) {
  d[[group_var]] <- factor(d[[group_var]])
  lev <- levels(d[[group_var]])
  if (is.null(etichette)) etichette <- paste0(group_var, "=", lev)

  # ---- figura: CIF del solo target per gruppo ----
  fig <- file.path(output_dir, paste0("cif_target_", file_tag, ".png"))
  png(fig, width = 1100, height = 750, res = 130)
  plot(0, 0, type = "n", xlim = c(0, max(d$tempo)), ylim = c(0, 1),
       xlab = "Tempo (giorni)", ylab = "Incidenza cumulativa raggiungimento target",
       main = paste0("CIF raggiungimento target LDL per ", group_var,
                     "\n(morte = evento competitivo, Aalen-Johansen)"))
  abline(v = land_d, col = "grey85", lty = 3)

  tab_list <- list()
  for (i in seq_along(lev)) {
    dat_i <- d[d[[group_var]] == lev[i], ]
    fit_i <- fit_aj(dat_i)
    st    <- which(fit_i$states == "target")
    # curva passo
    lines(fit_i$time, fit_i$pstate[, st], type = "s",
          col = cols[i], lwd = 2)
    # tabella ai tempi fissi
    ct <- cif_at_times(fit_i)
    ct$gruppo <- etichette[i]
    ct$n      <- nrow(dat_i)
    ct$anni   <- land_anni
    tab_list[[i]] <- ct
  }
  legend("topleft", bty = "n", lwd = 2, col = cols[seq_along(lev)],
         legend = paste0(etichette, " (n=", sapply(lev, function(l) sum(d[[group_var]]==l)), ")"))
  dev.off()

  # ---- test di Gray (confronto CIF tra gruppi) ----
  g  <- cuminc(ftime = d$tempo, fstatus = d$status, group = d[[group_var]],
               cencode = 0)
  # estrai p per l'evento di interesse (failcode "1")
  pval <- NA
  if (!is.null(g$Tests)) {
    rn <- rownames(g$Tests)
    ix <- which(rn == "1")
    if (length(ix) == 1) pval <- g$Tests[ix, "pv"]
  }

  # ---- tabella CIF ai tempi fissi ----
  tab <- do.call(rbind, tab_list)
  tab <- tab[, c("gruppo","n","anni","cif","lower","upper")]
  tab$cif   <- round(tab$cif,   4)
  tab$lower <- round(tab$lower, 4)
  tab$upper <- round(tab$upper, 4)

  list(tab = tab, pval = pval, fig = fig)
}

# --- Esecuzione: classe e terapia ------------------------------------
res_classe  <- analizza("classe",  col_classe,
                        etichette = paste("Classe", 1:4),
                        file_tag  = "classe")
res_terapia <- analizza("terapia", col_terapia,
                        etichette = c("No terapia","In terapia"),
                        file_tag  = "terapia")

# --- Report testuale -------------------------------------------------
rep_file <- file.path(report_dir, "cif_target.txt")
sink(rep_file)
cat("======================================================================\n")
cat(" CIF RAGGIUNGIMENTO TARGET LDL (morte = evento competitivo)\n")
cat(" Stimatore Aalen-Johansen; confronto tra gruppi: test di Gray\n")
cat(" Generato:", format(Sys.time(), "%Y-%m-%d %H:%M"), "\n")
cat("======================================================================\n\n")

cat("N pazienti analizzati:", nrow(d), "\n")
cat("Eventi: target =", sum(d$status==1),
    "| morte =", sum(d$status==2),
    "| censurati =", sum(d$status==0), "\n\n")

cat("### CIF raggiungimento target per CLASSE di rischio ###\n")
cat("(cif = incidenza cumulativa; lower/upper = IC 95%)\n")
print(res_classe$tab, row.names = FALSE)
cat("\nTest di Gray (differenza CIF target tra classi): p =",
    format.pval(res_classe$pval, digits = 3, eps = 1e-4), "\n\n")

cat("### CIF raggiungimento target per TERAPIA ###\n")
print(res_terapia$tab, row.names = FALSE)
cat("\nTest di Gray (differenza CIF target per terapia): p =",
    format.pval(res_terapia$pval, digits = 3, eps = 1e-4), "\n")
sink()

cat("Report :", rep_file, "\n")
cat("Figure :", res_classe$fig, "\n         ", res_terapia$fig, "\n")
cat("FATTO.\n")
