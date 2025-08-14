<#
.SYNOPSIS
Löst den Bildschirmschoner aus (effektiv: Bildschirm geht schlafen, je nach Energieeinstellungen).

.DESCRIPTION
Startet scrnsave.scr über PowerShell. Auf den meisten Windows-Setups
führt das nach kurzer Zeit zum Abschalten des Displays.

.NOTES
- Erfordert Windows.
- Verhalten hängt von den Energieoptionen und Richtlinien ab.
#>

# Fail fast
$ErrorActionPreference = "Stop"

# Prüfen, ob wir auf Windows laufen
if (-not $IsWindows) {
    Write-Error "Dieses Script ist nur für Windows geeignet."
    exit 1
}

# Auflösung: scrnsave.scr starten
# Das ist der „leere“ Windows-Standard-Bildschirmschoner.
$screenSaver = Join-Path $env:WINDIR "System32\scrnsave.scr"

if (-not (Test-Path $screenSaver)) {
    Write-Error "scrnsave.scr wurde nicht gefunden unter: $screenSaver"
    exit 2
}

Start-Process -FilePath $screenSaver
Write-Host "Bildschirmschoner gestartet. Der Bildschirm schaltet sich gemäß deinen Energieeinstellungen ab."
