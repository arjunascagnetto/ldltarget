# Studio di raggiungimento del target LDL

Fonte dati: `longitudinal/data/LDLFUP_TARGET.csv` (62.346 pazienti, 1 riga per paziente).

## Descrittive

### Identificativo e baseline
| Colonna | Significato | Uso |
|---|---|---|
| `KEY_ANAGRAFE` | ID paziente | chiave |
| `data_indice` | data di arruolamento (T0) | origine del tempo |
| `ldl_indice` | LDL al basale (mediana 118,8; range 55–456) | covariata chiave + verifica baseline |
| `gender`, `age` | sesso, età (mediana 74) | covariate / stratificazione |

### Definizione del target (outcome)
| Colonna | Significato |
|---|---|
| `classe` | classe di rischio 1–4 |
| `soglia` | target LDL dipendente dalla classe: classe1→116, classe2→100, classe3→70, classe4→55 mg/dL |
| `reached` | 1 = target raggiunto durante il follow-up |

Distribuzione classe × soglia (confermata corretta):

| classe | soglia (mg/dL) | n |
|---|---|---|
| 1 | 116 | 3.183 |
| 2 | 100 | 7.958 |
| 3 | 70 | 17.549 |
| 4 | 55 | 33.656 |

### Tempo ed esito (rischi competitivi)
| Colonna | Significato |
|---|---|
| `status` | 0 = censurato · 1 = target raggiunto · 2 = morte |
| `tempo` | giorni di follow-up (mediana 947, max 2233) |
| `data_event` | data raggiungimento target (presente nel 100% dei status=1) |
| `data_decesso` / `data_fine` | morte (`31DEC9999`=vivo) / fine follow-up (censura amministrativa a 31DEC2025) |

Distribuzione `status`:

| status | descrizione | n |
|---|---|---|
| 0 | censurato | 43.925 |
| 1 | target raggiunto | 7.585 |
| 2 | morte (evento competitivo) | 10.836 |

### Terapia
| Colonna | Significato | n con flag = 1 |
|---|---|---|
| `terapia` | in terapia ipolipemizzante sì/no | 21.401 |
| `sta` | statina | 20.246 |
| `eze` | ezetimibe | 5.779 |
| `bem` | acido bempedoico | 144 |
| `inc` | inclisiran | 16 |
| `pcs` | PCSK9 inibitore | 114 |

### Multiterapia (combinazioni di farmaci al basale)

Numero di farmaci per paziente (tra i 5 flag):

| N. farmaci | Pazienti | % totale |
|---|---|---|
| 0 (nessuna terapia) | 40.945 | 65,7% |
| 1 | 16.597 | 26,6% |
| 2 | 4.710 | 7,6% |
| 3 | 94 | 0,2% |
| 4–5 | 0 | 0% |

- **Multiterapia (≥2 farmaci): 4.804 pazienti = 7,7% del totale, 22,4% dei 21.401 in terapia.**
- I flag sono coerenti: `terapia=1` ⟺ ≥1 farmaco; `terapia=0` ⟺ nessun farmaco (0 incongruenze).

Tutte le 17 combinazioni osservate (coda inclusa):

| Combinazione | Pazienti |
|---|---|
| sta | 15.524 |
| sta+eze | 4.631 |
| eze | 982 |
| sta+eze+bem | 62 |
| pcs | 57 |
| eze+bem | 44 |
| bem | 27 |
| eze+pcs | 23 |
| sta+eze+pcs | 23 |
| inc | 7 |
| eze+bem+pcs | 5 |
| eze+inc | 5 |
| bem+pcs | 4 |
| sta+eze+inc | 3 |
| sta+pcs | 2 |
| eze+bem+inc | 1 |
| sta+bem | 1 |

Nota: la multiterapia è quasi sempre statina-centrica (`sta+eze` domina). I farmaci innovativi
(`bem` 144, `pcs` 114, `inc` 16) compaiono quasi solo in combinazione e con numeri piccoli →
nei modelli avranno scarsa potenza come categorie singole; probabile raggruppamento (es.
"combinazione" o "include farmaco innovativo").

## Disegno dello studio (proposto)

L'outcome `reached` ha un rischio competitivo evidente (10.836 morti prima del target),
quindi non Kaplan-Meier semplice ma:

1. **Incidenza cumulativa (Aalen-Johansen / CIF)** del raggiungimento target, con la morte
   come evento competitivo; curve complessive e per `classe`, `terapia`, `gender`, fasce di età.
2. **Modello di Fine-Gray** (subdistribution hazard) per i fattori associati al raggiungimento,
   aggiustando per età, sesso, classe, `ldl_indice`, terapia/tipo di farmaco.
3. **Cause-specific Cox** in parallelo, per separare effetto biologico e predittivo.
4. Descrittive di supporto: % raggiungimento e tempo mediano per classe.

Le soglie per classe sono confermate corrette.

## Protocollo

Analisi: **curve di incidenza cumulativa (CIF) del raggiungimento del target LDL, con la morte
come evento competitivo.**

### Definizione del modello time-to-event
- Tempo: `tempo` (giorni dall'arruolamento, `data_indice` = T0).
- Stato a 3 livelli da `status`:
  - `0` = censurato (fine follow-up / amministrativo a 31DEC2025)
  - `1` = **target raggiunto** (evento di interesse)
  - `2` = **morte** (evento competitivo)
- Oggetto: `Surv(tempo, factor(status, 0:2, labels = c("censor","target","morte")))`.

### Stimatore
- **Aalen-Johansen via `survival::survfit`** → CIF con IC 95% (è lo stimatore corretto sotto
  rischio competitivo; NON 1−Kaplan-Meier).
- **`cmprsk::cuminc`** in parallelo per il **test di Gray** sul confronto tra gruppi.

### Stratificazioni (concordate)
1. **`classe` di rischio (1–4)** — analisi principale (la soglia dipende dalla classe).
2. **`terapia` (0/1)** al basale.
- (Sesso, fasce di età e gruppi di farmaco: analisi secondarie eventuali.)

### Output
- **Figure** (`ldltarget/outputs/`): curve CIF del **solo raggiungimento target** (la CIF della
  morte non viene rappresentata in figura), una per stratificazione (classe; terapia).
- **Tabelle** (`ldltarget/reports/`): CIF stimata a tempi fissi (1–6 anni) con IC 95%
  per gruppo, tempo mediano al target dove stimabile, e **p del test di Gray**.

## Risultati CIF

Script: `src/cif_target.R` · Report dettagliato: `reports/cif_target.txt` ·
Figure: `outputs/cif_target_classe.png`, `outputs/cif_target_terapia.png`.

Coorte: 62.346 pazienti — target raggiunto 7.585, morte (competitivo) 10.836, censurati 43.925.
Stimatore Aalen-Johansen (morte = evento competitivo).

### CIF raggiungimento target per CLASSE di rischio (%)

| Classe (n) | 1 anno | 2 anni | 3 anni | 4 anni | 5 anni | 6 anni |
|---|---|---|---|---|---|---|
| 1 (n=3.183) | 4,0 | 12,5 | 18,4 | 21,6 | 25,1 | 27,1 |
| 2 (n=7.958) | 4,0 | 10,5 | 16,1 | 20,3 | 23,9 | 26,0 |
| 3 (n=17.549) | 2,3 | 6,1 | 9,3 | 11,8 | 14,3 | 16,4 |
| 4 (n=33.656) | 3,2 | 7,7 | 11,1 | 13,5 | 15,6 | 17,8 |

Test di Gray (differenza tra classi): **p < 0,0001**.

### CIF raggiungimento target per TERAPIA (%)

| Gruppo (n) | 1 anno | 2 anni | 3 anni | 4 anni | 5 anni | 6 anni |
|---|---|---|---|---|---|---|
| No terapia (n=40.945) | 2,0 | 5,3 | 8,2 | 10,3 | 12,6 | 14,5 |
| In terapia (n=21.401) | 5,3 | 12,7 | 18,2 | 22,2 | 25,1 | 27,7 |

Test di Gray (differenza per terapia): **p < 0,0001**.

Note: IC 95% per gruppo/tempo nel file `cif_target.txt`. Gli IC al 5°–6° anno sono più larghi
per il calo dei pazienti a rischio (follow-up: mediana 947 gg, max 2233 gg).
