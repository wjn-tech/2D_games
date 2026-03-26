# Entity Management

## ADDED Requirements

### Requirement: Mob Spawning Density Cap
- The NPC Spawner MUST enforce a **Local Density Limit** for each mob type.
- When attempting to spawn a mob at a location `P`:
  - Calculate `count` of existing mobs of the same type within `local_density_radius` (default: 800.0).
  - If `count >= max_local_density` (default: 5), the spawn attempt is cancelled.
- This prevents mobs from infinitely stacking in narrow spawnable areas (e.g., mob farms or spawn traps).

#### Scenario: Spawner skips crowded area
Given the player is near a crowded cave with 5 zombies within 800 units,
When the spawner attempts to spawn another zombie in that cave,
Then the spawn is cancelled because the local density limit is reached.

### Requirement: Item Drop Merging
- Dropped items (`LootItem`) MUST attempt to merge with nearby compatible items.
- When an item lands (or periodically):
  - Check for other `LootItem` instances within `merge_radius` (default: 32.0).
  - If multiple compatible items (same `item_data`, not full stack) exist, the newer/smaller count item merges into the older/larger item.
  - The resulting item's `count` increases, and the other item is queue_freed.
- This significantly reduces the physics entity count for mining large veins or mass mob kills.

#### Scenario: Mining drops merge
Given the player mines a large coal vein dropping 10 individual coal items in a small area,
When physics settles,
Then the 10 items merge into a single `LootItem` stack of 10 coal.

### Requirement: Item Drop Global Cap
- The game MUST enforce a **Global/Local Drop Limit** to prevent memory/physics overload.
- If the total count of `LootItem` entities in the scene exceeds `max_dropped_items` (e.g., 200), the oldest active items (farthest from player) are despawned to specific limit.
- Alternatively, prevent dropping if limit reached (but despawning old is better). We will implement **Oldest Despawn**.

#### Scenario: Too many items despawn oldest
Given 200 items exist in the world (the cap),
When a new item is dropped,
Then the oldest existing item (or farthest from player) is removed to maintain the cap.
