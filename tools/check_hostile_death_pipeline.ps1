param(
    [string]$BaseNpcPath = "src/systems/npc/base_npc.gd"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $BaseNpcPath)) {
    throw "Missing file: $BaseNpcPath"
}

$content = Get-Content -Raw -Encoding UTF8 $BaseNpcPath
$requiredPatterns = @(
    @{ name = "spell absorption"; pattern = "SpellAbsorptionManager.*handle_npc_death\(self\)" },
    @{ name = "normal loot call"; pattern = "_drop_normal_loot\(\)" },
    @{ name = "xp reward"; pattern = "add_experience\(" },
    @{ name = "gold reward"; pattern = "change_money\(" }
)

$missing = @()
foreach ($required in $requiredPatterns) {
    if ($content -notmatch $required.pattern) {
        $missing += $required.name
    }
}

if ($missing.Count -gt 0) {
    Write-Host "Hostile death pipeline check failed:" -ForegroundColor Red
    foreach ($item in $missing) {
        Write-Host " - missing behavior: $item" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Hostile death pipeline check passed." -ForegroundColor Green
