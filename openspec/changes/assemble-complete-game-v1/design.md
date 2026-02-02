# Design: Master Scene Orchestration

## 1. Scene Hierarchy (Main.tscn)
The `Main` scene will be organized as follows:
- **Main (Node)**: Root node with `GameManager` logic (if not autoloaded).
    - **Systems (Node)**: Container for non-visual managers that aren't Autoloads.
    - **World (Node2D)**: Container for `WorldGenerator` and the generated `TileMapLayers`.
    - **Entities (Node2D)**: Container for `Player`, `NPCs`, and `DroppedItems`.
    - **UI (CanvasLayer)**: Layer 100. Managed by `UIManager`.
        - **HUD**: Persistent status bars.
        - **Windows**: Container for dynamic windows (Inventory, Dialogue).
    - **Transitions (CanvasLayer)**: Layer 128. Fades and loading screens.

## 2. Game State Flow
The `GameManager` will control the following transitions:
1.  **MENU**: Show `MainMenu.tscn`. World is paused or hidden.
2.  **PLAYING**: Hide Menu, generate/load world, spawn player, show HUD.
3.  **PAUSED**: Stop time, show `PauseMenu.tscn`.
4.  **REINCARNATING**: On player death, show `ReincarnationWindow.tscn`. On confirm, reset player stats and respawn.

## 3. Communication Pattern
- **Signals**: All systems use `EventBus` to broadcast events (e.g., `item_collected`, `player_died`).
- **Dependency Injection**: The `Main` scene will pass references (like the active `TileMap`) to managers that need them (e.g., `DiggingManager`).

## 4. Resource Management
- **GameState**: Holds the persistent data (Inventory, Player Stats, World Seed).
- **SaveManager**: Serializes `GameState` to disk.
