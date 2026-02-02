# Proposal: Assemble Complete Game Architecture

## 1. Problem Statement
The project has many high-quality individual components (14 systems, various UI windows, world generation), but they are currently fragmented. `test.tscn` is used for development but lacks the structure of a finished game, while `Main.tscn` is a skeleton. There is no unified flow from the Main Menu to the gameplay loop and back.

## 2. Proposed Solution
We will transform the project into a cohesive game by:
1.  **Unifying the Entry Point**: Setting `Main.tscn` as the startup scene and implementing a robust `GameManager` state machine.
2.  **Scene Orchestration**: Organizing the `Main` scene into logical layers (World, Entities, UI, Systems).
3.  **System Integration**: Ensuring all 14 systems (Industrial, Lineage, Combat, etc.) are either Autoloaded or instantiated within the `Main` scene and communicating via `EventBus`.
4.  **UI Stack Management**: Using `UIManager` to handle all window transitions (Inventory, Crafting, Dialogue) on top of the `HUD`.
5.  **Gameplay Loop**: Implementing the transition from World Exploration -> Death -> Reincarnation Window -> New Character.

## 3. Scope
- **In-Scope**:
    - Refactoring `Main.tscn` to be the master scene.
    - Updating `GameManager` to handle game states (MENU, PLAYING, PAUSED, REINCARNATING).
    - Connecting `WorldGenerator` to the `Main` scene flow.
    - Integrating the `HUD` and `Inventory` into the persistent UI layer.
- **Out-of-Scope**:
    - Creating new art assets.
    - Implementing complex multiplayer features.
    - Writing extensive lore/dialogue content (placeholders will be used).

## 4. Impact
- **Architecture**: Moves from a "scene-per-feature" model to a "master-scene-with-components" model.
- **UX**: Provides a seamless experience from startup to gameplay.
