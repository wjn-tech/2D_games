# Tasks: World and Content Implementation

## Phase 1: Data Foundation
- [x] **Task 1.1**: Create `res://data/items/` and define `wood.tres`, `stone.tres`, `iron.tres`.
- [x] **Task 1.2**: Create `res://data/recipes/` and define `pickaxe.tres`, `furnace.tres`.
- [x] **Task 1.3**: Update `GameState` to load these resources on startup.

## Phase 2: World Generation
- [x] **Task 2.1**: Create `res://scenes/world/world_generator.tscn` and script.
- [x] **Task 2.2**: Implement `generate_layer(layer_id)` using `FastNoiseLite`.
- [x] **Task 2.3**: Configure `TileSet` with physics layers for Layer 0, 1, and 2.

## Phase 3: Entity & Interaction
- [x] **Task 3.1**: Implement `Gatherable` spawning logic in the generator.
- [x] **Task 3.2**: Connect `Player` mining action to the `TileMapLayer` data.
- [x] **Task 3.3**: Place `LayerDoor` instances at noise-determined "cave entrances".

## Phase 4: Validation
- [x] **Task 4.1**: Verify player can move between layers.
- [x] **Task 4.2**: Verify items picked up are added to `InventoryUI`.
- [x] **Task 4.3**: Verify `WorldGenerator` produces different seeds.
