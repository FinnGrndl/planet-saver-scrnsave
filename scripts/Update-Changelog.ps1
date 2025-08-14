#Requires -Version 7
<#
.SYNOPSIS
Erzeugt/aktualisiert CHANGELOG.md anhand der Git-Tags und Commits.

.DESCRIPTION
Nimmt den aktuell gepushten Tag (aus $env:TAG_NAME), ermittelt den vorherigen Tag,
listet die Commits im Bereich (prevTag..currentTag) und prependet einen neuen
Abschnitt in CHANGELOG.md.

.Falls kein vorheriger Tag existiert:
Nimmt alle Commits bis zum aktuellen Tag.
#>

$ErrorActionPreference = "Stop"

# --- Hilfsfunktionen ---
function Get-Tags {
    git tag --sort=-v:refname | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
}

function Get-PrevTag([string]$currentTag, [string[]]$allTags) {
    $idx = $allTags.IndexOf($currentTag)
    if ($idx -ge 0 -and ($idx + 1) -lt $allTags.Count) {
        return $allTags[$idx + 1]
    }
    return $null
}

# --- Bestimme aktuellen/letzten Tag ---
$currentTag = $env:TAG_NAME
if ([string]::IsNullOrWhiteSpace($currentTag)) {
    # Fallback: jüngster Tag
    $currentTag = (git describe --tags --abbrev=0).Trim()
}

$allTags = @(Get-Tags)
$prevTag = Get-PrevTag -currentTag $currentTag -allTags $allTags

# --- Datum des aktuellen Tags ---
$tagDate = (git log -1 --format=%ad --date=short $currentTag).Trim()
if (-not $tagDate) { $tagDate = (Get-Date -Format 'yyyy-MM-dd') }

# --- Commits sammeln ---
if ($null -ne $prevTag) {
    $range = "$prevTag..$currentTag"
} else {
    # erster Release-Tag im Repo
    $range = $currentTag
}

# Commit-Format: - message (shortsha)
$commits = git log --pretty=format:"- %s (%h)" $range
if (-not $commits) {
    $commits = "- Keine Änderungen aufgeführt."
}

# --- Abschnitt bauen ---
$header = "## $currentTag — $tagDate"
$newSection = @()
$newSection += $header
$newSection += $commits
$newSectionText = ($newSection -join "`n") + "`n`n"

# --- Bestehendes CHANGELOG lesen/aufbauen ---
$changelogPath = Join-Path (Get-Location) "CHANGELOG.md"
if (Test-Path $changelogPath) {
    $existing = Get-Content $changelogPath -Raw
    # Falls bereits ein Header für diesen Tag existiert, nichts tun (idempotent)
    if ($existing -match [regex]::Escape($header)) {
        Write-Host "CHANGELOG bereits aktuell für $currentTag."
        exit 0
    }
    $content = "# Changelog`n`n" + $newSectionText + ($existing -replace '^\# Changelog\s*\n*','')
} else {
    $content = "# Changelog`n`n" + $newSectionText
}

# --- Schreiben ---
Set-Content -Path $changelogPath -Value $content -NoNewline
Write-Host "CHANGELOG.md aktualisiert."
