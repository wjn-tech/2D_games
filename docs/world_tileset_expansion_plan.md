# World Tileset Expansion Plan

This file defines phase-1 minimalist tile naming and expansion batches.

## Naming and Layering Convention
- `surface_primary`
- `underground_primary`
- `deep_primary`
- `bedrock_transition`
- `bedrock_floor`
- `liquid_contact_water`
- `liquid_contact_lava`

All phase-1 keys are exported and validated by `WorldGenerator.get_stage_tileset_mapping()`.

## Phase-1 Minimum Delivery
- Surface context tile mapping
- Underground context tile mapping
- Deep context tile mapping
- Bedrock transition and hard floor mappings
- Water and lava contact-edge mappings

## Incremental Batch Growth (Post Phase-1)
1. Batch A: micro-biome edge variants (frozen/sandy/sodden transitions)
2. Batch B: decorative terrain chips and cavity trims
3. Batch C: structure-adjacent transitional solids
4. Batch D: special-liquid contact edge variants

## Backward Compatibility
- Existing stage mapping keys must remain stable.
- New batch tiles are additive and cannot remove or rename phase-1 keys.
