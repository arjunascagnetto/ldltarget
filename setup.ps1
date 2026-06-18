<#
.SYNOPSIS
  Setup dell'ambiente per il progetto ldltarget (Windows).

.DESCRIPTION
  Verifica e installa il necessario:
    - R (via winget se assente) + pacchetti R: survival, cmprsk
    - Python (via winget se assente) + pacchetti pip: markdown, xhtml2pdf
  Controlla la presenza dei dati in .\data e, con -Run, esegue l'intera pipeline.

.PARAMETER Run
  Se presente, dopo il setup esegue tutti gli script di analisi e genera il PDF.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\setup.ps1
  powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Run
#>

param([switch]$Run)

$ErrorActionPreference = "Stop"
$ProjDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DataDir = Join-Path $ProjDir "data"
$SrcDir  = Join-Path $ProjDir "src"

function Info($m){ Write-Host "[ OK ] $m"   -ForegroundColor Green }
function Warn($m){ Write-Host "[WARN] $m"   -ForegroundColor Yellow }
function Step($m){ Write-Host "`n=== $m ===" -ForegroundColor Cyan }

# ---------------------------------------------------------------------
function Find-Rscript {
  $c = (Get-Command Rscript.exe -ErrorAction SilentlyContinue).Source
  if ($c) { return $c }
  $cands = @(
    "$env:LOCALAPPDATA\Programs\R",
    "C:\Program Files\R",
    "C:\Program Files (x86)\R"
  )
  foreach ($base in $cands) {
    if (Test-Path $base) {
      $f = Get-ChildItem $base -Filter Rscript.exe -Recurse -ErrorAction SilentlyContinue |
           Sort-Object FullName -Descending | Select-Object -First 1
      if ($f) { return $f.FullName }
    }
  }
  return $null
}

function Ensure-Winget {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget non disponibile. Installa 'App Installer' dal Microsoft Store, poi rilancia."
  }
}

# ---------------------------------------------------------------------
Step "R"
$Rscript = Find-Rscript
if (-not $Rscript) {
  Warn "Rscript non trovato. Installo R con winget..."
  Ensure-Winget
  winget install -e --id RProject.R --accept-source-agreements --accept-package-agreements
  $Rscript = Find-Rscript
  if (-not $Rscript) { throw "R installato ma Rscript non rilevato. Riapri il terminale e rilancia." }
}
Info "Rscript: $Rscript"

Step "Pacchetti R (survival, cmprsk)"
$rcode = @'
pkgs <- c("survival","cmprsk")
miss <- pkgs[!sapply(pkgs, requireNamespace, quietly=TRUE)]
if (length(miss)) {
  cat("Installo:", paste(miss, collapse=", "), "\n")
  install.packages(miss, repos="https://cloud.r-project.org")
} else cat("Pacchetti R gia' presenti.\n")
ok <- sapply(pkgs, requireNamespace, quietly=TRUE)
if (!all(ok)) { quit(status=1) }
cat("Pacchetti R OK.\n")
'@
$tmpR = Join-Path $env:TEMP "ldltarget_rsetup.R"
# scrittura senza BOM (R non tollera il BOM UTF-8)
[System.IO.File]::WriteAllText($tmpR, $rcode, (New-Object System.Text.UTF8Encoding($false)))
& $Rscript $tmpR
if ($LASTEXITCODE -ne 0) { throw "Installazione pacchetti R fallita." }
Remove-Item $tmpR -Force
Info "Pacchetti R pronti."

# ---------------------------------------------------------------------
Step "Python"
$py = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $py) {
  Warn "Python non trovato. Installo con winget..."
  Ensure-Winget
  winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
  $py = (Get-Command python -ErrorAction SilentlyContinue).Source
  if (-not $py) { throw "Python installato ma non rilevato. Riapri il terminale e rilancia." }
}
Info "Python: $py"

Step "Pacchetti Python (markdown, xhtml2pdf)"
& $py -m pip install --quiet --upgrade pip
& $py -m pip install --quiet markdown xhtml2pdf
if ($LASTEXITCODE -ne 0) { throw "Installazione pacchetti Python fallita." }
Info "Pacchetti Python pronti."

# ---------------------------------------------------------------------
Step "Dati"
$need = @("LDLFUP_TARGET.csv","LDLFUP_FARMACEUTICA.csv","LDLFUP_LDL.csv")
$missData = @()
foreach ($f in $need) { if (-not (Test-Path (Join-Path $DataDir $f))) { $missData += $f } }
if ($missData.Count) {
  Warn "Mancano i dati in $DataDir : $($missData -join ', ')"
  Warn "Copia i CSV in .\data prima di eseguire le analisi (non sono versionati)."
} else {
  Info "Dati presenti in $DataDir."
}

# ---------------------------------------------------------------------
if ($Run) {
  if ($missData.Count) { throw "Impossibile eseguire la pipeline: dati mancanti." }
  Step "Esecuzione pipeline"
  $scripts = @("descrittiva_classe_eta.R","descrittiva_ldl_basale.R",
               "cif_target.R","finegray_target.R","coxcs_target.R")
  foreach ($s in $scripts) {
    Write-Host "-> Rscript $s" -ForegroundColor Cyan
    & $Rscript (Join-Path $SrcDir $s)
    if ($LASTEXITCODE -ne 0) { throw "Errore in $s" }
  }
  Write-Host "-> python md_to_pdf.py" -ForegroundColor Cyan
  & $py (Join-Path $SrcDir "md_to_pdf.py")
  Info "Pipeline completata. Report e figure in reports/ e outputs/."
}

Write-Host "`nSetup completato." -ForegroundColor Green
if (-not $Run) {
  Write-Host "Per eseguire anche le analisi: .\setup.ps1 -Run" -ForegroundColor Gray
}
