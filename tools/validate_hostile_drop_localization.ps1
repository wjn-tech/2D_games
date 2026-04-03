param(
    [string]$LocalizationMapPath = "data/npcs/hostile_drop_localization.json",
    [string]$TranslationsCsvPath = "assets/translations.csv"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $LocalizationMapPath)) {
    Write-Host "Localization map not found: $LocalizationMapPath"
    exit 1
}

if (-not (Test-Path $TranslationsCsvPath)) {
    Write-Host "Translations CSV not found: $TranslationsCsvPath"
    exit 1
}

$map = Get-Content -Raw -Path $LocalizationMapPath -Encoding UTF8 | ConvertFrom-Json
$signatureRows = @($map.signature_drops)
$commonRows = @($map.common_materials)
$allRows = @($signatureRows + $commonRows)

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

# Parse CSV while ignoring comments/blank lines.
$rawLines = Get-Content -Path $TranslationsCsvPath -Encoding UTF8
$csvLines = @()
foreach ($line in $rawLines) {
    $trim = $line.Trim()
    if ($trim -eq "") { continue }
    if ($trim.StartsWith("#")) { continue }
    $csvLines += $line
}

if ($csvLines.Count -eq 0) {
    Write-Host "No CSV rows found after filtering comments: $TranslationsCsvPath"
    exit 1
}

$csvText = $csvLines -join "`n"
$translations = $csvText | ConvertFrom-Csv
$keyToRow = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([System.StringComparer]::Ordinal)

foreach ($tr in $translations) {
    $k = [string]$tr.keys
    if ([string]::IsNullOrWhiteSpace($k)) { continue }
    if ($keyToRow.ContainsKey($k)) {
        $errors.Add("Duplicate translation key in CSV: '$k'.")
    } else {
        $keyToRow.Add($k, $tr)
    }
}

$itemIds = New-Object System.Collections.Generic.HashSet[string]
$translationKeys = New-Object System.Collections.Generic.HashSet[string]
$zhNames = New-Object System.Collections.Generic.HashSet[string]

foreach ($row in $signatureRows) {
    $itemId = [string]$row.item_id
    $key = [string]$row.translation_key
    $zh = [string]$row.zh
    $en = [string]$row.en

    if ([string]::IsNullOrWhiteSpace($itemId)) { $errors.Add("Signature row has empty item_id.") }
    if ([string]::IsNullOrWhiteSpace($key)) { $errors.Add("Signature row '$itemId' has empty translation_key.") }
    if ($itemIds.Contains($itemId)) { $errors.Add("Duplicate item_id in map: '$itemId'.") } else { $null = $itemIds.Add($itemId) }
    if ($translationKeys.Contains($key)) { $errors.Add("Duplicate translation_key in map: '$key'.") } else { $null = $translationKeys.Add($key) }
    if ($zhNames.Contains($zh)) { $errors.Add("Duplicate zh name in map: '$zh'.") } else { $null = $zhNames.Add($zh) }

    if ($key -notmatch '^ITEM_HOSTILE_[A-Z0-9]+_[A-Z0-9_]+$' -or $key -match '^ITEM_HOSTILE_MAT_') {
        $errors.Add("Signature key format invalid: '$key'.")
    }

    if (-not $keyToRow.ContainsKey($key)) {
        $errors.Add("Missing translation row in CSV for key '$key' (item_id '$itemId').")
    } else {
        $tr = $keyToRow[$key]
        if ([string]$tr.zh -ne $zh) { $errors.Add("ZH mismatch for key '$key': map='$zh' csv='$($tr.zh)'.") }
        if ([string]$tr.en -ne $en) { $errors.Add("EN mismatch for key '$key': map='$en' csv='$($tr.en)'.") }
    }
}

foreach ($row in $commonRows) {
    $itemId = [string]$row.item_id
    $key = [string]$row.translation_key
    $zh = [string]$row.zh
    $en = [string]$row.en

    if ([string]::IsNullOrWhiteSpace($itemId)) { $errors.Add("Common row has empty item_id.") }
    if ([string]::IsNullOrWhiteSpace($key)) { $errors.Add("Common row '$itemId' has empty translation_key.") }
    if ($itemIds.Contains($itemId)) { $errors.Add("Duplicate item_id in map: '$itemId'.") } else { $null = $itemIds.Add($itemId) }
    if ($translationKeys.Contains($key)) { $errors.Add("Duplicate translation_key in map: '$key'.") } else { $null = $translationKeys.Add($key) }
    if ($zhNames.Contains($zh)) { $errors.Add("Duplicate zh name in map: '$zh'.") } else { $null = $zhNames.Add($zh) }

    if ($key -notmatch '^ITEM_HOSTILE_MAT_[A-Z0-9_]+$') {
        $errors.Add("Common-material key format invalid: '$key'.")
    }

    if (-not $keyToRow.ContainsKey($key)) {
        $errors.Add("Missing translation row in CSV for key '$key' (item_id '$itemId').")
    } else {
        $tr = $keyToRow[$key]
        if ([string]$tr.zh -ne $zh) { $errors.Add("ZH mismatch for key '$key': map='$zh' csv='$($tr.zh)'.") }
        if ([string]$tr.en -ne $en) { $errors.Add("EN mismatch for key '$key': map='$en' csv='$($tr.en)'.") }
    }
}

if ($allRows.Count -lt 1) {
    $errors.Add("Localization map has no rows.")
}

Write-Host "Hostile localization rows:" $allRows.Count
Write-Host "Signature rows:" $signatureRows.Count
Write-Host "Common rows:" $commonRows.Count

if ($warnings.Count -gt 0) {
    Write-Host "Warnings:"
    foreach ($w in $warnings) { Write-Host "  -" $w }
}

if ($errors.Count -gt 0) {
    Write-Host "Errors:"
    foreach ($e in $errors) { Write-Host "  -" $e }
    exit 1
}

Write-Host "Validation passed."
exit 0
