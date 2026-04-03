# Hostile Spawn Table Standard

This project now uses a standardized external hostile spawn table:

- Source file: `res://data/npcs/hostile_spawn_table.json`
- Terrain taxonomy: `res://data/npcs/terrain_taxonomy_31.json`
- Loader: `res://src/systems/npc/npc_spawner.gd`
- Schema id: `hostile-spawn-table.v1`

## Rule Fields

Each rule in `rules` supports these fields:

- `id` (string): unique rule id for maintenance.
- `enemy_scene` (string): hostile NPC scene path.
- `spawn_probability` (float 0.0-1.0): probability weight used in candidate selection.
- `terrain_priority` (int): overlap influence factor used in weighted selection.
- `rarity_tier` (string): `common`, `uncommon`, `rare`, `elite`.
- `behavior_profile_id` (string): behavior package identifier for hostile signature moves.
- `hotspot_multiplier` (float >= 1.0): multiplier for designated hotspot terrains.
- `hotspot_terrain_ids` (string array): terrain ids in taxonomy used by hotspot multiplier.
- `ecozones` (string array): ecozones/biomes where rule is valid. Supports `Any`.
- `map_biomes` (string array): strict biome ids from world generation output. Supports `Any`.
- `depth_bands` (string array): strict depth bands from topology output. Supports `Any`.
- `underworld_regions` (string array): strict underworld region ids from underground metadata. Supports `Any`.
- `depth_zones` (string array): `SURFACE`, `UNDERGROUND`, `CAVERN`, `SPACE`.
- `time_phases` (string array): `Day`, `Night`, or `Any`.
- `origin_type` (string): spawn style (`natural`, `burrow`, `falling`, `emerging`).
- `max_active_count` (int): max simultaneous active count for this enemy type.
- `group_min` and `group_max` (int): spawned group size range.
- `requires_no_wall` and `requires_wall` (bool): wall constraints.
- `feature_tags` (string array): surface feature gate. Supports `Any`.
- `cave_regions` (string array): cave region gate. Supports `Any`.
- `min_openness` (float): minimum cave openness requirement.
- `requires_reachable_cave` (bool): cave reachability requirement.

## Probability Semantics

- Rules are first filtered by environment constraints (`map_biomes`, `depth_bands`, `underworld_regions`, `ecozones`, `depth_zones`, `time_phases`, cave/feature/wall constraints, and per-type cap).
- For each valid candidate, spawner computes effective weight using:
	- Base term: `spawn_probability`
	- Hotspot term: multiplied by `hotspot_multiplier` when current context hits any `hotspot_terrain_ids`
	- Priority term: multiplied by `1.0 + terrain_priority * 0.35`
- Among valid candidates, one rule is selected by weighted random using the effective weight.
- `spawn_probability` is relative within the current candidate pool, not a global guaranteed spawn rate.

## Strict Terrain Alignment

- `map_biomes` must match `WorldGenerator.get_biome_at(...)` output ids:
`FOREST`, `PLAINS`, `DESERT`, `TUNDRA`, `SWAMP`, `UNDERGROUND`, `UNDERGROUND_DESERT`, `UNDERGROUND_TUNDRA`, `UNDERGROUND_SWAMP`.
- `depth_bands` must match topology depth ids:
`surface`, `shallow_underground`, `mid_cavern`, `deep`, `terminal`.
- `underworld_regions` must match underground metadata ids:
`none`, `hard_floor`, `route`, `floor`, `cliff`, `island`, `cavity`.
- Spawner resolves spawn context from `get_biome_at` and `get_underground_generation_metadata_at_pos`, so hostile spawn points track actual generated eco-terrain positions.
- Strict loader behavior: each rule MUST explicitly provide `map_biomes`, `depth_bands`, `cave_regions`, and `underworld_regions`; otherwise the rule is skipped.
- Runtime underworld safeguard: when `underworld_active=true` and a rule targets explicit underworld regions, cave reachability/openness hard-gates are bypassed to avoid deep-layer dead zones.

## Validation Tool

- Script: `tools/validate_hostile_spawn_table.ps1`
- Command:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_hostile_spawn_table.ps1
```

- What it checks:
	- Required fields and enum validity
	- Duplicate rule ids
	- Probability and multiplier constraints
	- Terrain coverage contract (each terrain class has at least two candidate hostile families in strict mode)

## Current Ecozone-Oriented Hostile Rules

- Forest/Plains surface: `slime` (0.08), `zombie` (0.095)
- Swamp surface/underground: `bog_slime` (0.11)
- Desert surface day: `antlion` (0.15)
- Tundra surface/underground/cavern: `frost_bat` (0.09)
- Underground/cavern generic: `skeleton` (0.105), `cave_bat` (0.115)
- Underworld subregions: `skeleton_underworld_legion` (0.028), `cave_bat_underworld_swarm` (0.022)
- Surface night generic: `demon_eye` (0.07)

## Failure Behavior

If the JSON file is missing or invalid, the spawner falls back to built-in defaults with matching values so gameplay stays functional.

## Hostile Drop Localization Reference

- Hostile drop localization map: `res://data/npcs/hostile_drop_localization.json`
- Translation rows: `res://assets/translations.csv`

The hostile drop review flow requires each drop `item_id` to have:

1. A unique translation key in `hostile_drop_localization.json`.
2. A matching bilingual row (`keys`, `zh`, `en`) in `translations.csv`.

Validation command:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_hostile_drop_localization.ps1
```

## Hostile Loot Linkage

- Hostile loot table: `res://data/npcs/hostile_loot_table.json`
- Runtime resolver: `res://src/systems/npc/hostile_loot_table.gd`
- Spawn metadata propagation: `NPCSpawner` writes `spawn_rule_id` and `hostile_monster_type` to each spawned hostile instance.

Death-time drop resolution in `BaseNPC` uses deterministic precedence:

1. `rule_overrides[spawn_rule_id]`
2. `monster_type_defaults[monster_type]`
3. `global_fallback`

Designer-facing drop matrix is maintained in:

- `res://docs/hostile_drop_table.md`