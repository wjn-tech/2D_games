# Change: Expand Exploration Terrain and Hostiles

## Why
The project already has a functioning infinite world, biome-aware spawning, and a small hostile roster, but the exploration loop still feels thin. Current terrain generation relies on a relatively simple height-and-cave threshold model, surface content is sparse outside houses and ruins, and only a handful of hostile families spawn with limited biome coupling and attack identity.

## What Changes
- Enrich underground generation with more navigable cave structure, explicit reachability rules, biome-themed subterranean pockets, and stronger ore/encounter composition.
- Expand surface and transition terrain richness with biome landmarks, decorative variation, and clearer regional identity.
- Increase hostile variety so major biome and depth bands are paired with native enemy families instead of reusing the same small set everywhere.
- Define a signature combat pattern for each hostile family in scope so enemies are recognized by behavior, not only by sprite/name.
- Align spawning, terrain tagging, cave-region classification, and encounter composition so new terrain features and enemy families reinforce each other.

## Current Baseline
- World generation is driven by WorldGenerator and InfiniteChunkManager, with noise-based surface height, hard biome selection, cave/tunnel carving, trees, houses, and ruins.
- Cave space is still primarily derived from threshold-based carve noise, so underground readability and player route quality are inconsistent.
- The active hostile roster is small: slime, zombie, skeleton, antlion, and demon eye.
- Underground and cavern spawning currently depend on simple zone/depth gating, with only limited cave-native encounter identity.
- Surface and underground biomes exist, but exploration content density and enemy differentiation are still limited.
- There are currently no published OpenSpec specs, so this proposal establishes the first formal requirements for exploration content enrichment.

## Impact
- Affected specs: exploration-underground-generation, exploration-terrain-richness, hostile-biome-ecosystem, hostile-signature-attacks
- Affected code: src/systems/world/world_generator.gd, src/systems/world/infinite_chunk_manager.gd, src/systems/npc/npc_spawner.gd, scenes/npc/*.tscn, src/systems/npc/ai/**/*.gd, projectile/attack resources tied to hostile families
- Affected content: new biome decoration resources, new hostile scenes/resources, new AI/BT attack patterns, new spawn rule data
