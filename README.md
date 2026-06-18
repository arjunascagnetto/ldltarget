# ldltarget

Studio di raggiungimento del target LDL sulla coorte DAICHI (analisi di sopravvivenza con
rischi competitivi: la morte è l'evento competitivo).

## Struttura
- `src/` — codice (script R e Python)
- `reports/` — report testuali, documento di sintesi (`studio_target_ldl.md`/`.pdf`)
- `outputs/` — figure (PNG)
- `data/` — dati sorgente **non versionati** (esclusi via `.gitignore`, vedi sotto)

## Contenuto principale
- `src/descrittiva_classe_eta.R` — classi di rischio per fascia di età.
- `src/descrittiva_ldl_basale.R` — LDL al basale per classe (tabella + boxplot).
- `src/cif_target.R` — CIF (Aalen-Johansen) del raggiungimento target, morte come rischio
  competitivo; stratificazione per classe e terapia; test di Gray.
- `src/finegray_target.R` — modello di Fine-Gray (subdistribution hazard, sHR).
- `src/coxcs_target.R` — modello di Cox causa-specifico (HR).
- `src/md_to_pdf.py` — conversione del report Markdown in PDF con figure.
- `reports/studio_target_ldl.md` / `.pdf` — documento di sintesi completo.

## Dati
- File CSV separati da `;`: `LDLFUP_TARGET.csv` (1 riga/paziente, ha `age` e `classe`),
  `LDLFUP_FARMACEUTICA.csv` (1 riga/prescrizione), `LDLFUP_LDL.csv`.
- Date in formato SAS DATE9 (es. `08OCT2022`); `31DEC9999` = data mancante/sentinella.
- **I dati dei pazienti NON sono pubblicati nel repository** (cartella `data/` e `*.csv` esclusi
  da `.gitignore`, perché sensibili). Per eseguire gli script occorre disporre dei CSV in locale.

## How-to: clone, dati e installazione pacchetti

### 1. Clonare il repository
```bash
git clone https://github.com/arjunascagnetto/ldltarget.git
cd ldltarget
```

### 2. Predisporre i dati
I CSV non sono nel repo. Copiarli nella cartella `data/` del progetto:
```bash
mkdir -p data
# copiare qui: LDLFUP_TARGET.csv, LDLFUP_FARMACEUTICA.csv, LDLFUP_LDL.csv
```
Gli script leggono i dati da `data/` ricavandola da `proj_dir` (in testa a ciascun `src/*.R`:
`data_dir <- file.path(proj_dir, "data")`). Per usarli su un'altra macchina basta aggiornare
**solo** `proj_dir` al percorso locale del progetto.

### 3. Installare i pacchetti R
Servono `survival` (di base in R) e `cmprsk`. In R / Rscript:
```r
install.packages(c("survival", "cmprsk"))
```
Verifica rapida:
```r
for (p in c("survival","cmprsk"))
  cat(p, requireNamespace(p, quietly = TRUE), "\n")
```

### 4. (Opzionale) Pacchetti Python per il PDF
Per rigenerare il PDF dal Markdown:
```bash
pip install markdown xhtml2pdf
```

### 5. Eseguire le analisi
```bash
Rscript src/descrittiva_classe_eta.R
Rscript src/descrittiva_ldl_basale.R
Rscript src/cif_target.R
Rscript src/finegray_target.R
Rscript src/coxcs_target.R
python   src/md_to_pdf.py      # rigenera reports/studio_target_ldl.pdf
```

## Metodi (sintesi)
- **CIF / Aalen-Johansen**: incidenza cumulativa del raggiungimento target con morte competitiva.
- **Fine-Gray (sHR)**: effetto delle covariate sul rischio assoluto (CIF).
- **Cox causa-specifico (HR)**: effetto sul tasso istantaneo (morte trattata come censura).
Dettagli e risultati in `reports/studio_target_ldl.md`.
