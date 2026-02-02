# Design: Quest System and Fog of War

## Architectural Reasoning

### Quest System
The `QuestManager` will be a global singleton that maintains a list of active and completed quests. Quests will be defined as Resources (`QuestResource`) containing:
- Title and Description.
- Objective (e.g., "Kill X enemies", "Collect Y items").
- Rewards (Money, Items, Reputation).
- Status (Not Started, Active, Completed).

NPCs will have a chance to be "Quest Givers". When interacted with, they will offer a quest from a pool of available templates.

### Fog of War
The `FogOfWar` will be a `TileMapLayer` placed above the world layers. It will be filled with black tiles initially. A "reveal" logic will run in `_process`, clearing tiles around the player's position. To optimize, we will only update when the player moves to a new tile.

### Discovery System
When a POI (like a camp) is revealed by the Fog of War, the `DiscoveryManager` will trigger a notification and potentially grant a small reward (e.g., "Discovered Bandit Camp! +10 XP").

## Trade-offs
- **Fog of War Performance**: Updating a TileMap every frame can be expensive. We will use a distance check to only update when the player has moved significantly.
- **Quest Complexity**: We will start with simple "Fetch" and "Kill" quests to keep the implementation straightforward.
