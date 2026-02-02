# Proposal: Fix NPC Physics and Spawning

## 1. Problem Statement
NPCs currently exhibit several physical issues:
- **Wall Jitter**: When NPCs hit a wall, they may "jitter" or "twitch" due to rapid state changes or collision handling.
- **Spawning in Ground**: NPCs sometimes spawn partially inside tiles, causing them to get stuck or behave erratically.
- **Inconsistent Movement**: NPCs lack the "step-up" logic recently added to the player, making them less capable of navigating the terrain.

## 2. Proposed Solution
- **Fix Wall Jitter**: Add a small cooldown or "turn-around" buffer when an NPC hits a wall to prevent rapid direction switching.
- **Safe Spawning**: Adjust the `WorldGenerator` to spawn NPCs slightly higher above the ground and use `move_and_collide` or a similar check to ensure they land safely on the surface.
- **Step-Up Integration**: Ensure the `_handle_step_up` logic is correctly integrated and active for NPCs.

## 3. Scope
- `src/systems/npc/base_npc.gd`: Refine wall collision handling and state transitions.
- `src/systems/world/world_generator.gd`: Adjust NPC spawn height and placement logic.

## 4. Dependencies
- `LayerManager` for collision constants.
- `BaseNPC` physics logic.
