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
Python via `winget` se assente) e **crea un venv `.venv`** in cui installa `markdown`/`xhtml2pdf`
(senza toccare il Python di sistema), poi controlla i dati. Ordine corretto dei passi:

**1. Clonare il repository ed entrarci**
```powershell
git clone https://github.com/arjunascagnetto/ldltarget.git
cd ldltarget
```

**2. Copiare i dati nella cartella `data/`** (già presente dopo il clone; i CSV non sono nel
repo e lo script non li crea né li scarica)
```powershell
# copiare in data/ i 3 CSV: LDLFUP_TARGET.csv, LDLFUP_FARMACEUTICA.csv, LDLFUP_LDL.csv
```
> I dati vanno ottenuti **separatamente** dal responsabile del progetto (non sono nel repo né
> nel `git clone`): ad esempio l'archivio cifrato `ldltarget_data.zip` (anch'esso fuori dal repo),
> da estrarre dentro `data/`.

**3. Eseguire il setup** (solo dopo aver messo i dati)
```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1        # solo setup
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Run   # setup + analisi + PDF
```

> ⚠️ Senza i dati in `data/`, `setup.ps1 -Run` si ferma con errore "dati mancanti".

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

Creare un **ambiente virtuale dedicato** nel progetto (`.venv`, non versionato) e installarvi i
pacchetti per la conversione Markdown -> PDF (così non si tocca il Python di sistema/Anaconda):
```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install markdown xhtml2pdf
```

Generazione del PDF (usando il Python del venv):
```powershell
.\.venv\Scripts\python.exe src\md_to_pdf.py
```

### 5. Eseguire le analisi
```powershell
Rscript src/descrittiva_classe_eta.R
Rscript src/descrittiva_ldl_basale.R
Rscript src/cif_target.R
Rscript src/finegray_target.R
Rscript src/coxcs_target.R
.\.venv\Scripts\python.exe src\md_to_pdf.py   # rigenera reports/studio_target_ldl.pdf
```

## Metodi (sintesi)
- **CIF / Aalen-Johansen**: incidenza cumulativa del raggiungimento target con morte competitiva.
- **Fine-Gray (sHR)**: effetto delle covariate sul rischio assoluto (CIF).
- **Cox causa-specifico (HR)**: effetto sul tasso istantaneo (morte trattata come censura).
Dettagli e risultati in `reports/studio_target_ldl.md`.
