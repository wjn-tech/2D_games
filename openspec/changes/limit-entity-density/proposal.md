# Proposal: Limit Entity Density

## 1. Problem Statement
The game currently allows unlimited stacking of entities (both mobs and item drops) in a specific area.
- Monster spawners (or natural spawning) can produce infinite mobs if not cleared, leading to extreme performance degradation ("lag").
- Item drops from mining or mob kills accumulate indefinitely without merging or despawning, cluttering the world and consuming physics resources.
- The user specifically requested a strict limit on entity density to prevent these issues.

## 2. Proposed Solution
Implement a strict density control system for both NPCs and Item Drops.

### Mob Density
- **Global & Local Limits**: Modify `NPCSpawner` to enforce not just a global count but a **local density limit** (e.g., max X mobs within radius R of a spawn point).
- **Spawn Rejection**: If the local area is crowded, cancel the spawn attempt.
- **Dynamic Despawn**: Aggressively despawn mobs that are far from the player AND exceed the global limit (already partially implemented, but needs strict enforcement).

### Item Drop Density
- **Item Merging**: Implement logic in `LootItem` to detect nearby compatible items (same type, not full stack) and merge them into a single entity with a higher count.
- **Area Limit**: Implement a "Soft Cap" for dropped items in a chunk/area. If the limit is reached, either:
    - Prevent new drops (unfriendly).
    - Despawn the oldest/lowest-value items in that area.
    - Merge aggressively.
    - **Resolution**: We will implement **Item Merging** as the primary solution, and a **Global/Local Cap** that despawns the oldest items if density becomes critical.

## 3. Scope
- `src/systems/npc/npc_spawner.gd`: Add local density check using `PhysicsShapeQuery` or group counting within radius.
- `src/entities/loot_item.gd`: Add `try_merge()` logic and `despawn_timer`.
- `scenes/world/loot_item.tscn`: Add `Area2D` for merge detection (or use physics query).

## 4. Dependencies
- `NPCSpawner` existing logic.
- `LootItem` existing logic.
