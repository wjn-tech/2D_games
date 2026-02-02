# Design: Master Scene Architecture

## 1. Scene Hierarchy (`Main.tscn`)
The Master Scene will be organized as follows:

- **Main (Node2D)**: Root node.
    - **Systems (Node)**: Container for non-visual system controllers (e.g., `CombatManager`, `LineageManager`).
    - **World (Node2D)**: Container for the procedural world.
        - **WorldGenerator**: The node responsible for generating tiles.
        - **TileMapLayers**: The actual layers for terrain, objects, etc.
    - **Entities (Node2D)**: Container for dynamic objects.
        - **Player**: The player character.
        - **NPCs**: Container for all NPCs.
        - **Items**: Container for dropped items.
    - **UI (CanvasLayer)**: The top-level UI container.
        - **MainMenu**: The initial screen.
        - **HUD**: The in-game interface.
        - **Windows**: Container for pop-up windows (Inventory, Crafting, etc.).

## 2. Initialization Flow
1. **Startup**: `GameManager` (Autoload) starts in `START_MENU` state.
2. **Main Scene Load**: `Main.tscn` loads. `UIManager` hides the `HUD` and shows the `MainMenu`.
3. **Start Game**: User clicks "Start" in `MainMenu`.
4. **State Change**: `GameManager` transitions to `PLAYING`.
5. **World Gen**: `WorldGenerator` is triggered to create the map.
6. **UI Switch**: `UIManager` hides `MainMenu` and shows `HUD`.
7. **Player Spawn**: Player is placed at a valid starting position.

## 3. Key Components
- **GameManager**: Orchestrates the high-level state machine.
- **UIManager**: Manages visibility and input focus for all UI elements.
- **WorldGenerator**: Handles the procedural generation logic.
