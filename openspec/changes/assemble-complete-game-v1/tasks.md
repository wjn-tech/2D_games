# Tasks: Game Assembly Roadmap

## Phase 1: Master Scene Setup
- [x] **Task 1.1**: Refactor `Main.tscn` to match the new hierarchy (Systems, World, Entities, UI).
- [x] **Task 1.2**: Set `Main.tscn` as the startup scene in `project.godot`.
- [x] **Task 1.3**: Update `GameManager` to handle the `MENU` -> `PLAYING` transition.

## Phase 2: UI Integration
- [x] **Task 2.1**: Connect `MainMenu.tscn` to the `GameManager` start signal.
- [x] **Task 2.2**: Ensure `HUD.tscn` updates correctly from `GameState` data.
- [x] **Task 2.3**: Verify `UIManager` can open/close `InventoryWindow` and `DialogueWindow` within the `Main` scene.

## Phase 3: World & Entity Linkage
- [x] **Task 3.1**: Ensure `WorldGenerator` places the player at a valid spawn point on start.
- [x] **Task 3.2**: Connect `LifespanManager` to the player in the `Main` scene to trigger death.
- [x] **Task 3.3**: Link `DiggingManager` to the generated `TileMapLayer` in the `Main` scene.

## Phase 4: System Loop Closure
- [x] **Task 4.1**: Implement the "Death to Reincarnation" flow: Player dies -> Show Window -> Select Heir -> Respawn in `Main`.
- [x] **Task 4.2**: Connect `WeatherManager` to the `World` node to apply visual effects (rain/snow).
- [x] **Task 4.3**: Final verification of the "Mining -> Crafting -> Building" loop in the integrated environment.
