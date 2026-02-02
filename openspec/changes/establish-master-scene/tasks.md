# Tasks: Establish Master Scene

## Phase 1: Scene Structure
- [x] **Task 1.1**: Refactor `Main.tscn` hierarchy.
    - Create `Systems`, `World`, `Entities`, and `UI` containers.
    - Move existing `WorldGenerator` and `TileMapLayer` nodes into `World`.
    - Move `Player` into `Entities`.
    - Ensure `MainMenu` and `HUD` are under `UI`.
- [x] **Task 1.2**: Set `Main.tscn` as the main scene in `project.godot`.

## Phase 2: Flow Integration
- [x] **Task 2.1**: Connect `MainMenu` signals to `GameManager`.
    - Ensure "Start Game" button triggers `GameManager.start_game()`.
- [x] **Task 2.2**: Update `GameManager` to handle scene-specific initialization.
    - When entering `PLAYING` state, trigger `WorldGenerator.generate_world()`.
- [x] **Task 2.3**: Update `UIManager` to manage `Main.tscn` UI nodes.
    - Automatically find and reference `MainMenu` and `HUD` within the scene.

## Phase 3: Validation
- [x] **Task 3.1**: Verify game starts at Main Menu.
- [x] **Task 3.2**: Verify clicking "Start" generates the world and shows the HUD.
- [x] **Task 3.3**: Verify Player can move in the generated world.
