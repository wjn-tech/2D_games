## 1. Data Contract
- [x] 1.1 Define hostile loot table schema with `signature_drop`, `common_pool`, and optional `rule_overrides`.
- [x] 1.2 Define deterministic precedence: `rule_override` > `monster_type_default` > `global_fallback`.
- [x] 1.3 Add validation rules for required fields, probability bounds, and quantity ranges.

## 2. Baseline Loot Matrix
- [x] 2.1 Author baseline loot entries for all 8 hostile monster types currently spawnable.
- [x] 2.2 Enforce signature uniqueness across monster types.
- [x] 2.3 Add underworld/depth overrides for `skeleton_underworld_legion` and `cave_bat_underworld_swarm`.

## 3. Monster Material Item Set
- [x] 3.1 Define new monster-material item IDs/resources for signature drops (one unique per hostile type).
- [x] 3.2 Define shared monster-material common pool IDs/resources (non-terrain items only).
- [x] 3.3 Add validation rule blocking terrain block items (`grass`, `dirt`, `stone`, etc.) in hostile default drop pools.

## 4. Runtime Integration Plan
- [x] 4.1 Integrate item loot roll into hostile death flow without removing spell absorption.
- [x] 4.2 Preserve existing XP and gold reward behavior.
- [x] 4.3 Route spawned/awarded items through existing inventory or `LootItem` pathways (implementation decision documented).

## 5. Verification
- [x] 5.1 Add automated validation script/check for full hostile coverage and signature uniqueness.
- [x] 5.2 Add deterministic simulation (fixed seed) to sample 1k kills per hostile and verify distribution sanity.
- [x] 5.3 Add regression checks confirming spell absorption still triggers on hostile death.
- [x] 5.4 Add validation check that hostile common pools exclude terrain block items by default.

## 6. Documentation and Sign-off
- [x] 6.1 Update hostile spawning doc with loot linkage and override semantics.
- [x] 6.2 Publish a designer-facing text table for monster drops and get review sign-off.
- [x] 6.3 Run `openspec validate add-hostile-unique-drop-tables --strict` and resolve all issues.
