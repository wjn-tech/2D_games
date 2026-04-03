param(
    [string]$SpawnTablePath = "data/npcs/hostile_spawn_table.json",
    [string]$TaxonomyPath = "data/npcs/terrain_taxonomy_31.json",
    [switch]$StrictCoverage = $true
)

$ErrorActionPreference = "Stop"

function New-AllowedSet {
    param([string[]]$Values)
    $set = @{}
    foreach ($v in $Values) { $set[$v] = $true }
    return $set
}

function Test-AllowedArray {
    param(
        [object[]]$Values,
        [hashtable]$Allowed,
        [string]$FieldName,
        [string]$RuleId,
        [System.Collections.Generic.List[string]]$Errors
    )

    if ($null -eq $Values -or $Values.Count -eq 0) {
        $Errors.Add("Rule '$RuleId' missing or empty field '$FieldName'.")
        return
    }

    foreach ($v in $Values) {
        $sv = [string]$v
        if (-not $Allowed.ContainsKey($sv)) {
            $Errors.Add("Rule '$RuleId' has invalid $FieldName value '$sv'.")
        }
    }
}

function Test-RuleMatchesTerrain {
    param(
        [pscustomobject]$Rule,
        [pscustomobject]$Terrain
    )

    $dims = @("map_biomes", "depth_bands", "cave_regions", "underworld_regions")
    foreach ($dim in $dims) {
        $ruleVals = @($Rule.$dim | ForEach-Object { [string]$_ })
        $terrainVals = @($Terrain.$dim | ForEach-Object { [string]$_ })

        if ($ruleVals -contains "Any") { continue }

        $intersects = $false
        foreach ($v in $ruleVals) {
            if ($terrainVals -contains $v) {
                $intersects = $true
                break
            }
        }

        if (-not $intersects) {
            return $false
        }
    }

    if ($null -ne $Terrain.feature_tags) {
        $ruleFeatures = @($Rule.feature_tags | ForEach-Object { [string]$_ })
        $terrainFeatures = @($Terrain.feature_tags | ForEach-Object { [string]$_ })

        if (-not ($ruleFeatures -contains "Any")) {
            $fIntersect = $false
            foreach ($f in $ruleFeatures) {
                if ($terrainFeatures -contains $f) {
                    $fIntersect = $true
                    break
                }
            }
            if (-not $fIntersect) { return $false }
        }
    }

    return $true
}

if (-not (Test-Path $SpawnTablePath)) {
    Write-Host "Spawn table not found: $SpawnTablePath"
    exit 1
}

if (-not (Test-Path $TaxonomyPath)) {
    Write-Host "Terrain taxonomy not found: $TaxonomyPath"
    exit 1
}

$spawnRoot = Get-Content -Raw -Path $SpawnTablePath | ConvertFrom-Json
$taxonomyRoot = Get-Content -Raw -Path $TaxonomyPath | ConvertFrom-Json

$rules = @($spawnRoot.rules)
$terrains = @($taxonomyRoot.terrains)

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

$allowed = @{
    map_biomes = New-AllowedSet @("Any", "FOREST", "PLAINS", "DESERT", "TUNDRA", "SWAMP", "UNDERGROUND", "UNDERGROUND_DESERT", "UNDERGROUND_TUNDRA", "UNDERGROUND_SWAMP")
    depth_bands = New-AllowedSet @("Any", "surface", "shallow_underground", "mid_cavern", "deep", "terminal")
    cave_regions = New-AllowedSet @("Any", "Surface", "Tunnel", "Chamber", "OpenCavern", "Pocket", "Connector", "Solid")
    underworld_regions = New-AllowedSet @("Any", "none", "hard_floor", "route", "floor", "cliff", "island", "cavity")
    time_phases = New-AllowedSet @("Any", "Day", "Night")
    ecozones = New-AllowedSet @("Any", "Forest", "Plains", "Desert", "Tundra", "Swamp")
    feature_tags = New-AllowedSet @("Any", "None", "StoneOutcrop", "DesertSpire", "FrostSpire", "MudMound", "GrassKnoll")
    rarity_tier = New-AllowedSet @("common", "uncommon", "rare", "elite")
}

$requiredFields = @(
    "id", "enemy_scene", "spawn_probability", "ecozones", "map_biomes", "depth_bands",
    "depth_zones", "time_phases", "origin_type", "max_active_count", "group_min", "group_max",
    "feature_tags", "cave_regions", "underworld_regions", "terrain_priority", "rarity_tier", "behavior_profile_id"
)

$seenRuleIds = @{}

foreach ($rule in $rules) {
    $ruleId = [string]$rule.id
    if ([string]::IsNullOrWhiteSpace($ruleId)) {
        $errors.Add("Rule missing id.")
        continue
    }

    if ($seenRuleIds.ContainsKey($ruleId)) {
        $errors.Add("Duplicate rule id '$ruleId'.")
    } else {
        $seenRuleIds[$ruleId] = $true
    }

    foreach ($field in $requiredFields) {
        if (-not ($rule.PSObject.Properties.Name -contains $field)) {
            $errors.Add("Rule '$ruleId' missing required field '$field'.")
        }
    }

    if ([string]::IsNullOrWhiteSpace([string]$rule.enemy_scene)) {
        $errors.Add("Rule '$ruleId' has empty enemy_scene.")
    }

    $p = [double]$rule.spawn_probability
    if ($p -le 0.0 -or $p -gt 1.0) {
        $errors.Add("Rule '$ruleId' has invalid spawn_probability '$p' (must be 0 < p <= 1).")
    }

    Test-AllowedArray -Values @($rule.ecozones) -Allowed $allowed.ecozones -FieldName "ecozones" -RuleId $ruleId -Errors $errors
    Test-AllowedArray -Values @($rule.map_biomes) -Allowed $allowed.map_biomes -FieldName "map_biomes" -RuleId $ruleId -Errors $errors
    Test-AllowedArray -Values @($rule.depth_bands) -Allowed $allowed.depth_bands -FieldName "depth_bands" -RuleId $ruleId -Errors $errors
    Test-AllowedArray -Values @($rule.cave_regions) -Allowed $allowed.cave_regions -FieldName "cave_regions" -RuleId $ruleId -Errors $errors
    Test-AllowedArray -Values @($rule.underworld_regions) -Allowed $allowed.underworld_regions -FieldName "underworld_regions" -RuleId $ruleId -Errors $errors
    Test-AllowedArray -Values @($rule.time_phases) -Allowed $allowed.time_phases -FieldName "time_phases" -RuleId $ruleId -Errors $errors
    Test-AllowedArray -Values @($rule.feature_tags) -Allowed $allowed.feature_tags -FieldName "feature_tags" -RuleId $ruleId -Errors $errors

    $tier = [string]$rule.rarity_tier
    if (-not $allowed.rarity_tier.ContainsKey($tier)) {
        $errors.Add("Rule '$ruleId' has invalid rarity_tier '$tier'.")
    }

    if ($null -eq $rule.hotspot_multiplier) {
        $warnings.Add("Rule '$ruleId' has no hotspot_multiplier (defaults to 1.0).")
    } elseif ([double]$rule.hotspot_multiplier -lt 1.0) {
        $errors.Add("Rule '$ruleId' has hotspot_multiplier < 1.0.")
    }
}

$coverage = @{}
foreach ($terrain in $terrains) {
    $tid = [string]$terrain.id
    $coverage[$tid] = New-Object System.Collections.Generic.HashSet[string]
}

foreach ($terrain in $terrains) {
    $tid = [string]$terrain.id
    foreach ($rule in $rules) {
        if (Test-RuleMatchesTerrain -Rule $rule -Terrain $terrain) {
            $null = $coverage[$tid].Add([string]$rule.id)
        }
    }
}

foreach ($terrain in $terrains) {
    $tid = [string]$terrain.id
    $count = $coverage[$tid].Count
    if ($StrictCoverage -and $count -lt 2) {
        $errors.Add("Terrain '$tid' has only $count matching family rules (required >= 2).")
    } elseif ($count -lt 2) {
        $warnings.Add("Terrain '$tid' has only $count matching family rules.")
    }
}

Write-Host "Spawn rules:" $rules.Count
Write-Host "Terrain classes:" $terrains.Count

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
