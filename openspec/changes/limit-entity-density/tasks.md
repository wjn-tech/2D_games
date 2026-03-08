# Tasks

1.  ### Mob Spawning Local Density Check
    - [x] Update `NPCSpawner.gd` (`_try_spawn_cycle` or `_get_valid_spawn_pos`) to implement a `has_local_density_limit(pos, type)` check.
    - [x] Implement query logic: Calculate mobs of `type` within `spawn_radius` (e.g., 800px) using `Vector2.distance_squared_to` or `PhysicsShapeQuery`.
    - [x] Add `max_local_density` parameter to `SpawnRule` class (default: 3-5).
    - [x] Verify spawned mobs respect the density limit near clustered areas.

2.  ### Item Drop Merging Logic
    - [x] Update `LootItem.gd` to include a `_try_merge()` function called periodically (e.g., every 1s or on collision settle).
    - [x] Implement query: Find nearby `LootItem` via `Area2D` or `PhysicsShapeQuery` (radius ~32px).
    - [x] Add merge logic: If `other_item.item_data == self.item_data` and `other_item.count < stack_limit`, transfer count to `self` (or largest stack) and `queue_free()` the smaller one.
    - [x] Verify multiple dropped items combine into a single stack.

3.  ### Global Item Drop Cap (Safe Despawn)
    - [x] Update `LootItem.gd` or `InventoryManager.gd` to monitor total `LootItem` count (using grouping "loot").
    - [x] Implement cap enforcement: If `get_tree().get_nodes_in_group("loot").size() > MAX_LOOT_ITEMS` (e.g., 200), find the oldest or farthest item and `queue_free()` it.
    - [x] Add `creation_time` timestamp to `LootItem` for age tracking.
    - [x] Verify mass item drops (e.g., via debug command) automatically clean up old items.
