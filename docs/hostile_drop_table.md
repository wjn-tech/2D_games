# Hostile Drop Table (v1)

- Loot config: `res://data/npcs/hostile_loot_table.json`
- Runtime resolver: `res://src/systems/npc/hostile_loot_table.gd`
- Death integration: `res://src/systems/npc/base_npc.gd`

## Resolution Precedence

1. `rule_overrides[spawn_rule_id]`
2. `monster_type_defaults[monster_type]`
3. `global_fallback`

## Designer Review Table

| Monster Type | Signature Drop | Signature Chance / Qty | Common Pool A | Common Pool B |
| --- | --- | --- | --- | --- |
| slime | slime_essence | 0.78 / 1-2 | gelatin_residue 0.42 / 1-2 | arcane_dust 0.28 / 1 |
| bog_slime | bog_core | 0.73 / 1-2 | toxic_slurry 0.40 / 1-2 | arcane_dust 0.22 / 1 |
| zombie | rotten_talisman | 0.66 / 1 | tainted_flesh 0.48 / 1-2 | torn_cloth 0.31 / 1 |
| skeleton | bone_fragment | 0.74 / 1-3 | bone_dust 0.46 / 1-2 | cursed_powder 0.24 / 1 |
| cave_bat | echo_wing | 0.64 / 1-2 | bat_fur 0.44 / 1-2 | sonar_membrane_shard 0.25 / 1 |
| frost_bat | frost_gland | 0.70 / 1-2 | frozen_membrane 0.41 / 1-2 | chill_dust 0.30 / 1 |
| antlion | antlion_mandible | 0.76 / 1-2 | chitin_fragment 0.45 / 1-2 | desert_resin 0.27 / 1 |
| demon_eye | void_eyeball | 0.60 / 1 | shadow_ichor 0.38 / 1-2 | arcane_shard 0.28 / 1 |

## Rule Overrides

| Spawn Rule ID | Override Changes |
| --- | --- |
| skeleton_underworld_legion | bone_fragment chance 0.82, cursed_powder chance 0.34 |
| cave_bat_underworld_swarm | echo_wing chance 0.70, sonar_membrane_shard chance 0.37 |

## Guardrails

- Hostile default pools disallow terrain block items: `grass`, `dirt`, `stone`, `sand`, `snow`, `mud`, `ice`, `hard_rock`, `wood`.
- Signature drops are unique across the 8 hostile monster types.
- Export compatibility: resolver existence checks use `ResourceLoader.exists` for `res://data/npcs/hostile_loot_table.json` before opening text content, avoiding export-only false negatives from filesystem-only checks.

## Validation Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_hostile_loot_table.ps1
powershell -ExecutionPolicy Bypass -File tools/simulate_hostile_loot_distribution.ps1
powershell -ExecutionPolicy Bypass -File tools/check_hostile_death_pipeline.ps1
```
