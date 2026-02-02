# Tasks: Refine NPC Ecology

- [x] **Implementation: Visual Hostility**
    - Modify `BaseNPC.gd` to apply red modulation if `alignment == "Hostile"`.
- [x] **Implementation: Movement Tracking**
    - Add `last_spawn_pos` and `spawn_distance_threshold` to `NPCSpawner.gd`.
    - Implement logic to trigger `_try_spawn()` based on distance traveled from `last_spawn_pos`.
- [x] **Implementation: Empty Tile Validation**
    - Update `NPCSpawner._get_random_spawn_pos` to ensure the foreground tile at the candidate position is empty (`-1`).
- [ ] **Refinement: Spawning Rates**
    - Adjust `max_mobs` and `spawn_interval` (as a failsafe/background rate) to prevent overcrowding.
- [x] **Verification**
    - Verify NPCs spawn in open areas (caves/surface) and not inside walls.
    - Verify Hostile NPCs are tinted red.
    - Verify NPCs spawn as the player explores new areas.
