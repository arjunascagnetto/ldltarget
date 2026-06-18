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

## Setup rapido (Windows)

Lo script `setup.ps1` verifica e installa il necessario (R + pacchetti `survival`/`cmprsk`,
Python + `markdown`/`xhtml2pdf`, installando R/Python via `winget` se assenti) e controlla i dati:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1        # solo setup
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Run   # setup + analisi + PDF
```

Nota: i dati (`data/*.csv`) non sono versionati e vanno copiati a parte (vedi sotto). In
alternativa al setup automatico, si possono seguire i passi manuali qui sotto.

## How-to manuale: clone, dati e installazione pacchetti

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
Gli script leggono i dati da `data/`: `proj_dir` (radice del progetto) viene ricavato
**automaticamente** dalla posizione dello script in `src/`, quindi `data_dir <-
file.path(proj_dir, "data")` funziona da qualsiasi cartella, senza path assoluti da modificare.
Basta che i CSV stiano in `<progetto>/data/`.

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

### 4. (Opzionale) Python per generare il PDF

Se Python non è installato, installarlo velocemente:

- Windows (winget):
```powershell
winget install -e --id Python.Python.3.12
```
- Windows (alternativa): se è già presente conda/Anaconda, nessuna installazione necessaria.
- macOS (Homebrew):
```bash
brew install python
```
- Linux (Debian/Ubuntu):
```bash
sudo apt update && sudo apt install -y python3 python3-pip
```

Verifica:
```bash
python --version
```

Poi i pacchetti per la conversione Markdown -> PDF:
```bash
pip install markdown xhtml2pdf
```

Generazione del PDF:
```bash
python src/md_to_pdf.py
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
