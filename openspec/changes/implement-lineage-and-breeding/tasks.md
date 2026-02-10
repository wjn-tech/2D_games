# Tasks: Lineage and Breeding

## Phase 1: Data Structure Refactor
- [x] Refactor `CharacterData` to support `wild_levels` and `tamed_levels`. <!-- id: 1 -->
- [x] Implement `get_stat_value()` calculation logic with mutability. <!-- id: 2 -->
- [x] Add serialization support for new attribute structure in `SaveManager`. <!-- id: 3 -->

## Phase 2: NPC Interaction & Mating
- [x] Update `SocialManager` to handle `spouse` relationships. <!-- id: 4 -->
- [x] Implement `woohoo` command/interaction conditional on marriage. <!-- id: 5 -->
- [x] Create `Baby` entity variant (scaled down sprite). <!-- id: 6 -->

## Phase 3: Breeding & Genetics Core
- [x] Implement `BreedingManager.generate_offspring(parent_a, parent_b)`. <!-- id: 7 -->
- [x] Implement Stat Inheritance algorithm (55/45 rule). <!-- id: 8 -->
- [x] Implement Mutation logic (7.3% chance, +2 levels, counter increment). <!-- id: 9 -->

## Phase 4: Lifecycle & Growth
- [x] Add `age` and `growth_stage` logic to `CharacterData`. <!-- id: 10 -->
- [x] Implement `GrowthSystem` (time-based scaling and stat updates). <!-- id: 11 -->
- [x] Add `Imprinting` interaction minigame (simple button press/feed). <!-- id: 12 -->

## Phase 5: Death & Inheritance UI
- [x] Implement `HeirSelectionUI` (List children, show stats). <!-- id: 13 -->
- [x] Update `Player.gd` death logic to trigger Inheritance flow. <!-- id: 14 -->
- [x] Implement "Camera Transition & Control Swap" logic. <!-- id: 15 -->
- [x] Create `LootContainer` prefab for creating "Death Cache" (dropped inventory). <!-- id: 16 -->

## Phase 6: Debug & Quality of Life
- [x] Implement `DebugManager` or extended Godot console commands. <!-- id: 17 -->
- [x] Implement `debug_force_marry` and `debug_set_affinity`. <!-- id: 18 -->
- [x] Implement `debug_grow_child` to skip wait times. <!-- id: 19 -->
- [x] Implement `debug_kill_player` to test heir selection loop. <!-- id: 20 -->
