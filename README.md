# ldltarget

Analisi descrittive sulla coorte LDL (progetto DAICHI).

## Struttura
- `src/` — codice (script R)
- `reports/` — report testuali
- `outputs/` — figure

## Contenuto attuale
- `src/descrittiva_classe_eta.R` — distribuzione delle classi di rischio per fascia di età,
  sui pazienti con ≥1 prescrizione nel file FARMACEUTICA. Età recuperata dal file TARGET.
  Produce `reports/descrittiva_classe_eta.txt` e le figure in `outputs/`.

## Note dati
- Dati sorgente: `../longitudinal/data/` (CSV separati da `;`).
- Date in formato SAS DATE9 (es. `08OCT2022`); `31DEC9999` = mancante.
- Eseguire con: `Rscript src/descrittiva_classe_eta.R`
