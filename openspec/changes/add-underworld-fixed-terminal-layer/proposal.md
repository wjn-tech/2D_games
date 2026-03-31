# Change: Add Fixed Underworld Terminal Layer

## Why
Players want a large, memorable endgame underground destination that is guaranteed to appear every world, not a purely probabilistic deep-cave outcome. Current deep and terminal regions can still feel too fragmented or homogeneous across long traversal.

A fixed mega underworld space near bedrock can provide a stable exploration target similar to Terraria's hell layer while preserving this project's deterministic chunked world model.

## What Changes
- Add a new independent capability: `underworld-generation`.
- Introduce one deterministic world-scale underworld mega-space per world, anchored immediately above the bedrock transition region.
- Require near full-circumference horizontal coverage and minimum vertical span of 180 tiles.
- Require aggressive shape language: giant cavity floor, major cliffs/escarpments, and suspended island groups.
- Guarantee at least one natural primary access route from mid-cavern into the underworld.
- Increase ore density by 30% in configured underworld-adjacent bands.
- Allow controlled geometric intrusion into bedrock-transition space for dramatic boundary shaping.
- Keep existing saves compatible without forced chunk rewrite, while allowing legacy metadata to backfill underworld activation for newly generated depth chunks.

## Impact
- Affected specs:
  - underworld-generation
- Affected code (implementation stage, after approval):
  - src/systems/world/world_generator.gd
  - src/systems/world/world_topology.gd
  - src/systems/world/infinite_chunk_manager.gd
  - tests/test_worldgen_bedrock_and_liquid.gd
- Relationship to existing changes:
  - Complements improve-underground-diversity-and-ore-deposition by adding a deterministic terminal destination layer.
  - Complements enhance-natural-cave-entrances-and-deep-caverns by extending progression with a fixed end-layer objective.
