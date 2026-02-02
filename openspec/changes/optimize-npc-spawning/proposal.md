# Proposal: Optimize NPC Spawning

## 1. Problem Statement
NPCs are currently spawned at arbitrary coordinates based on noise values, leading to them appearing in the air or stuck inside ground tiles. Additionally, the current spawn rate results in too many NPCs scattered across the map, which can clutter the world and impact performance.

## 2. Proposed Solution
- **Ground-Only Spawning**: Modify `WorldGenerator.gd` to ensure NPCs are only spawned on valid ground tiles. For scattered NPCs, the generator will find the surface level for a given X coordinate before spawning.
- **Collision Awareness**: Implement a check to ensure the spawn location is not occupied by a solid tile.
- **Reduced Spawn Rate**: Lower the probability of scattered NPC generation to make encounters more meaningful and less frequent.
- **Camp Placement Refinement**: Ensure NPCs in camps are also placed on valid ground, accounting for the random offsets.

## 3. Scope
- `src/systems/world/world_generator.gd`: Refactor `generate_layer` and `_spawn_pois` to use ground-finding logic for NPC placement.

## 4. Dependencies
- `WorldGenerator`'s `TileMapLayer` references.
