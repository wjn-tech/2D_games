param(
    [string]$CraftingManagerPath = "src/systems/crafting/crafting_manager.gd",
    [string]$PlayerPath = "scenes/player.gd",
    [string]$EncounterManagerPath = "src/systems/boss/boss_encounter_manager.gd",
    [string]$EncounterScenePath = "src/systems/boss/boss_encounter_scene.gd",
    [string]$BossContractsTestPath = "tests/test_boss_progression_contracts.gd"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$requiredFiles = @(
    "data/items/boss/slime_king_sigil.tres",
    "data/items/boss/skeleton_king_sigil.tres",
    "data/items/boss/eye_king_sigil.tres",
    "data/items/boss/slime_king_core.tres",
    "data/items/boss/skeleton_king_core.tres",
    "data/items/boss/eye_king_core.tres",
    "data/items/boss/forbidden_key.tres",
    "scenes/worlds/encounters/boss_slime_king.tscn",
    "scenes/worlds/encounters/boss_skeleton_king.tscn",
    "scenes/worlds/encounters/boss_eye_king.tscn",
    "scenes/worlds/encounters/boss_mina_finale.tscn",
    "src/systems/boss/boss_encounter_scene.gd",
    "src/systems/boss/boss_encounter_manager.gd"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "Boss progression pipeline check failed: missing files" -ForegroundColor Red
    foreach ($file in $missingFiles) {
        Write-Host " - $file" -ForegroundColor Red
    }
    exit 1
}

$checks = @(
    @{ path = $CraftingManagerPath; name = "boss sigil recipes"; pattern = "_add_boss_progression_recipes" },
    @{ path = $CraftingManagerPath; name = "forbidden key arcane dust cost"; pattern = '"arcane_dust"\s*:\s*10' },
    @{ path = $PlayerPath; name = "boss encounter interact hook"; pattern = "try_start_encounter_from_player" },
    @{ path = $PlayerPath; name = "boss encounter defeat hook"; pattern = "handle_player_death" },
    @{ path = $EncounterManagerPath; name = "finale completion persistence"; pattern = "mina_finale_completed" },
    @{ path = $EncounterManagerPath; name = "intro focus duration fixed to 1.2"; pattern = "INTRO_FOCUS_DURATION\s*:=\s*1\.2" },
    @{ path = $EncounterManagerPath; name = "intro lock ceiling for player agency"; pattern = "MAX_INPUT_LOCK_DURATION\s*:=\s*2\.0" },
    @{ path = $EncounterManagerPath; name = "entry stability attempts fixed to 30"; pattern = "ENTRY_STABILITY_ATTEMPTS\s*:=\s*30" },
    @{ path = $EncounterManagerPath; name = "entry mapping stability self check"; pattern = "run_entry_mapping_self_check" },
    @{ path = $EncounterScenePath; name = "compact room width threshold"; pattern = "MAX_COMPACT_ROOM_WIDTH\s*:=\s*1400\.0" },
    @{ path = $EncounterScenePath; name = "compact room height threshold"; pattern = "MAX_COMPACT_ROOM_HEIGHT\s*:=\s*700\.0" },
    @{ path = $EncounterScenePath; name = "streaming isolation validator"; pattern = "validate_streaming_isolation" },
    @{ path = $EncounterScenePath; name = "visual fidelity validator"; pattern = "validate_visual_fidelity_baseline" },
    @{ path = $EncounterScenePath; name = "combat readability validator"; pattern = "validate_combat_readability_baseline" },
    @{ path = $EncounterScenePath; name = "theme token export"; pattern = "theme_particle_profile" },
    @{ path = $BossContractsTestPath; name = "boss contract required attempts"; pattern = "REQUIRED_ENTRY_ATTEMPTS\s*:=\s*30" }
)

$missingPatterns = @()
foreach ($check in $checks) {
    if (-not (Test-Path $check.path)) {
        $missingPatterns += "$($check.name) (file missing: $($check.path))"
        continue
    }
    $content = Get-Content -Raw -Encoding UTF8 $check.path
    if ($content -notmatch $check.pattern) {
        $missingPatterns += "$($check.name) (pattern: $($check.pattern))"
    }
}

if ($missingPatterns.Count -gt 0) {
    Write-Host "Boss progression pipeline check failed: missing behavior" -ForegroundColor Red
    foreach ($item in $missingPatterns) {
        Write-Host " - $item" -ForegroundColor Red
    }
    exit 1
}

$requiredSceneNodes = @("Background", "FarLayer", "MidLayer", "ForeLayer", "Arena", "Gates", "PlayerSpawn", "BossSpawn", "IntroFocus")
$sceneNodeMissing = @()
foreach ($scenePath in @(
    "scenes/worlds/encounters/boss_slime_king.tscn",
    "scenes/worlds/encounters/boss_skeleton_king.tscn",
    "scenes/worlds/encounters/boss_eye_king.tscn",
    "scenes/worlds/encounters/boss_mina_finale.tscn"
)) {
    $sceneContent = Get-Content -Raw -Encoding UTF8 $scenePath
    foreach ($nodeName in $requiredSceneNodes) {
        $nodePattern = '\[node name="' + [regex]::Escape($nodeName) + '"'
        if ($sceneContent -notmatch $nodePattern) {
            $sceneNodeMissing += "$scenePath missing node $nodeName"
        }
    }
}

if ($sceneNodeMissing.Count -gt 0) {
    Write-Host "Boss progression pipeline check failed: missing encounter scene baseline nodes" -ForegroundColor Red
    foreach ($item in $sceneNodeMissing) {
        Write-Host " - $item" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Boss progression pipeline check passed." -ForegroundColor Green
