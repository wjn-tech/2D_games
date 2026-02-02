# Proposal: Refine NPC Ecological System

Implement a Terraria-inspired NPC spawning and behavior system where hostility is visually telegraphed, spawning is strictly environmental, and population is managed via player movement.

## Problem
Currently, NPC spawning is purely timer-based and doesn't respect the "empty area" rule effectively. Hostile NPCs are not visually distinct from neutral ones at a glance, and there is no mechanism to trigger spawning based on player exploration.

## Solution
1. **Hostile Visuals**: Hostile NPCs will receive a red color modulation to indicate danger.
2. **Foreground Check**: Spawning logic will verify that the target tile in the foreground layer (`LAYER_WORLD_0`) is empty.
3. **Movement-Triggered Spawning**: The `NPCSpawner` will track player displacement and attempt spawns every X units moved, rather than just every Y seconds.
4. **Respawning Ecology**: Areas can repopulate once the player leaves and returns, simulating a living world.

## Impact
- **Gameplay**: Clearer telegraphing of threats. Spawning feels more natural as it happens "ahead" of the player's path.
- **Performance**: Prevents spawning NPCs inside blocks which would otherwise waste physics processing and cause glitches.
- **Code**: Refines `NPCSpawner` and `BaseNPC`.
