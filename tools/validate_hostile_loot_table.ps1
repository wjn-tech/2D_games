param(
    [string]$LootTablePath = "data/npcs/hostile_loot_table.json",
    [string]$SpawnTablePath = "data/npcs/hostile_spawn_table.json",
    [string]$LocalizationPath = "data/npcs/hostile_drop_localization.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $LootTablePath)) {
    throw "Missing loot table: $LootTablePath"
}
if (-not (Test-Path $SpawnTablePath)) {
    throw "Missing spawn table: $SpawnTablePath"
}
if (-not (Test-Path $LocalizationPath)) {
    throw "Missing localization map: $LocalizationPath"
}

$lootConfig = Get-Content -Raw -Encoding UTF8 $LootTablePath | ConvertFrom-Json
$spawnConfig = Get-Content -Raw -Encoding UTF8 $SpawnTablePath | ConvertFrom-Json
$localizationConfig = Get-Content -Raw -Encoding UTF8 $LocalizationPath | ConvertFrom-Json

$errors = New-Object System.Collections.Generic.List[string]

if ($lootConfig.schema -ne "hostile-loot-table.v1") {
    $errors.Add("schema must be hostile-loot-table.v1")
}

$terrainSet = New-Object "System.Collections.Generic.HashSet[string]"
foreach ($terrainId in $lootConfig.terrain_block_item_ids) {
    [void]$terrainSet.Add([string]$terrainId)
}

$localizedItemIds = New-Object "System.Collections.Generic.HashSet[string]"
foreach ($entry in @($localizationConfig.signature_drops) + @($localizationConfig.common_materials)) {
    if ($entry.item_id) {
        [void]$localizedItemIds.Add([string]$entry.item_id)
    }
}

$spawnRuleIds = New-Object "System.Collections.Generic.HashSet[string]"
foreach ($rule in $spawnConfig.rules) {
    if ($rule.id) {
        [void]$spawnRuleIds.Add([string]$rule.id)
    }
}

$spawnMonsterTypeMap = @{}
foreach ($p in $lootConfig.spawn_rule_to_monster_type.PSObject.Properties) {
    $spawnMonsterTypeMap[$p.Name] = [string]$p.Value
}

$monsterDefaults = @{}
foreach ($p in $lootConfig.monster_type_defaults.PSObject.Properties) {
    $monsterDefaults[$p.Name] = $p.Value
}

$ruleOverrides = @{}
foreach ($p in $lootConfig.rule_overrides.PSObject.Properties) {
    $ruleOverrides[$p.Name] = $p.Value
}

if ($monsterDefaults.Count -lt 8) {
    $errors.Add("monster_type_defaults should define all hostile monster archetypes (expected >= 8)")
}

$signatureItemOwners = @{}

function Test-DropEntry {
    param(
        [string]$Context,
        [pscustomobject]$Entry
    )

    if (-not $Entry.item_id) {
        $errors.Add("$Context missing item_id")
        return
    }

    $itemId = [string]$Entry.item_id
    $chance = [double]$Entry.chance
    $minQty = [int]$Entry.min_qty
    $maxQty = [int]$Entry.max_qty

    if ($chance -lt 0.0 -or $chance -gt 1.0) {
        $errors.Add("$Context chance out of range [0,1]: $chance")
    }
    if ($minQty -lt 1) {
        $errors.Add("$Context min_qty must be >= 1: $minQty")
    }
    if ($maxQty -lt $minQty) {
        $errors.Add("$Context max_qty must be >= min_qty ($minQty): $maxQty")
    }
    if ($terrainSet.Contains($itemId)) {
        $errors.Add("$Context uses forbidden terrain block item_id: $itemId")
    }
    if (-not $localizedItemIds.Contains($itemId)) {
        $errors.Add("$Context item_id is missing localization mapping: $itemId")
    }
}

foreach ($monsterType in $monsterDefaults.Keys) {
    $entry = $monsterDefaults[$monsterType]
    if (-not $entry.signature_drop) {
        $errors.Add("monster_type_defaults.$monsterType missing signature_drop")
    } else {
        Test-DropEntry -Context "monster_type_defaults.$monsterType.signature_drop" -Entry $entry.signature_drop
        $signatureItemId = [string]$entry.signature_drop.item_id
        if ($signatureItemOwners.ContainsKey($signatureItemId)) {
            $errors.Add("signature drop item_id must be unique per monster type: $signatureItemId already used by $($signatureItemOwners[$signatureItemId])")
        } else {
            $signatureItemOwners[$signatureItemId] = $monsterType
        }
    }

    if ($entry.common_pool) {
        $index = 0
        foreach ($common in $entry.common_pool) {
            Test-DropEntry -Context "monster_type_defaults.$monsterType.common_pool[$index]" -Entry $common
            $index += 1
        }
    }
}

foreach ($ruleId in $ruleOverrides.Keys) {
    if (-not $spawnRuleIds.Contains($ruleId)) {
        $errors.Add("rule_overrides.$ruleId does not exist in spawn table")
    }

    $entry = $ruleOverrides[$ruleId]
    if ($entry.signature_drop) {
        Test-DropEntry -Context "rule_overrides.$ruleId.signature_drop" -Entry $entry.signature_drop
    }
    if ($entry.common_pool) {
        $index = 0
        foreach ($common in $entry.common_pool) {
            Test-DropEntry -Context "rule_overrides.$ruleId.common_pool[$index]" -Entry $common
            $index += 1
        }
    }
}

foreach ($ruleId in $spawnRuleIds) {
    if (-not $spawnMonsterTypeMap.ContainsKey($ruleId)) {
        $errors.Add("spawn_rule_to_monster_type missing mapping for spawn rule: $ruleId")
        continue
    }

    $monsterType = $spawnMonsterTypeMap[$ruleId]
    if (-not $monsterDefaults.ContainsKey($monsterType)) {
        $errors.Add("spawn_rule_to_monster_type.$ruleId references unknown monster type: $monsterType")
    }
}

if ($errors.Count -gt 0) {
    Write-Host "Hostile loot table validation failed:" -ForegroundColor Red
    foreach ($message in $errors) {
        Write-Host " - $message" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Hostile loot table validation passed." -ForegroundColor Green
