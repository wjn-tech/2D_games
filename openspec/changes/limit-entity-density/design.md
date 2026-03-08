# Design: Entity Density Limiting

## Overview
This design implements strict density limits for mobs and items to prevent the "infinite stacking" performance issue.

## Mob Density Control
- **Responsibility**: `NPCSpawner`
- **Logic**: Before spawning a mob at `pos`, perform a `PhysicsShapeQuery` (radius ~800px) or iterate through `get_nodes_in_group("hostile_npcs")`.
- **Optimization**: Since `get_nodes_in_group` might be slow with many nodes, we optimize by:
    - Only checking mobs of the *same type* (scene path).
    - Using `distance_squared_to` check (fast) instead of physics query (which involves engine overhead).
    - Limiting checks per frame (e.g., spawn cycle is infrequent anyway).
    - `max_local_density` is defined per `SpawnRule` (e.g., 5 for swarming mobs, 1 for bosses).

## Item Drop Density Control
- **Responsibility**: `LootItem` (self-management) + `InventoryManager` (global cap)
- **Merging**:
    - Each `LootItem` checks periodically (e.g., every 1s via `Timer` or `_process` with interval) for nearby items.
    - Uses `Area2D` overlap or `PhysicsShapeQuery` (radius ~32px).
    - Merges if `item_data` matches and total stack size <= `max_stack`.
    - Merged item updates visual count/label if implemented.
- **Global Cap**:
    - Centralized check in `InventoryManager` or decentralized check in `LootItem`?
    - **Decentralized Approach**: When a new item spawns, check `get_tree().get_nodes_in_group("loot").size()`.
    - If count > `MAX_GLOBAL_DROPS` (e.g., 200), find the item with the oldest `timestamp` (or farthest from player) and `queue_free()` it.
    - This distributes the check cost but ensures the cap is maintained.

## Performance Considerations
- **Item Merging Frequency**: Checking every frame is too expensive. We'll use a `Timer` with random offset (0.5s - 1.5s) to stagger checks.
- **Global Cap Check**: Only performed when adding new items, so overhead is minimal (O(N) search for oldest/farthest happens rarely if cap is respected, or O(1) if maintained). actually O(N) is fine for N=200.
