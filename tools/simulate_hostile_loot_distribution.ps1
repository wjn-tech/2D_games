param(
    [string]$LootTablePath = "data/npcs/hostile_loot_table.json",
    [int]$SamplesPerMonster = 1000,
    [int]$Seed = 20251201
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $LootTablePath)) {
    throw "Missing loot table: $LootTablePath"
}

$config = Get-Content -Raw -Encoding UTF8 $LootTablePath | ConvertFrom-Json
$defaults = @{}
foreach ($p in $config.monster_type_defaults.PSObject.Properties) {
    $defaults[$p.Name] = $p.Value
}

$random = [System.Random]::new($Seed)

function Roll-Qty {
    param([pscustomobject]$Entry)
    $chance = [double]$Entry.chance
    if ($chance -le 0.0) { return 0 }
    if ($random.NextDouble() -gt $chance) { return 0 }

    $minQty = [int]$Entry.min_qty
    $maxQty = [int]$Entry.max_qty
    if ($maxQty -lt $minQty) { return 0 }
    if ($minQty -eq $maxQty) { return $minQty }

    return $random.Next($minQty, $maxQty + 1)
}

Write-Host "Simulating hostile loot distribution with seed=$Seed, samples=$SamplesPerMonster" -ForegroundColor Cyan

foreach ($monsterType in $defaults.Keys | Sort-Object) {
    $entry = $defaults[$monsterType]
    $totals = @{}

    for ($i = 0; $i -lt $SamplesPerMonster; $i += 1) {
        if ($entry.signature_drop) {
            $qty = Roll-Qty -Entry $entry.signature_drop
            if ($qty -gt 0) {
                $itemId = [string]$entry.signature_drop.item_id
                if (-not $totals.ContainsKey($itemId)) { $totals[$itemId] = 0 }
                $totals[$itemId] += $qty
            }
        }

        foreach ($common in $entry.common_pool) {
            $qty = Roll-Qty -Entry $common
            if ($qty -gt 0) {
                $itemId = [string]$common.item_id
                if (-not $totals.ContainsKey($itemId)) { $totals[$itemId] = 0 }
                $totals[$itemId] += $qty
            }
        }
    }

    Write-Host "`n[$monsterType]" -ForegroundColor Yellow
    if ($totals.Count -eq 0) {
        Write-Host "  no drops observed in simulation" -ForegroundColor Red
        continue
    }

    foreach ($kv in $totals.GetEnumerator() | Sort-Object Name) {
        $avg = [math]::Round(($kv.Value / [double]$SamplesPerMonster), 3)
        Write-Host ("  {0,-24} total={1,5}  avg/kill={2,6}" -f $kv.Key, $kv.Value, $avg)
    }
}

Write-Host "`nSimulation complete." -ForegroundColor Green
