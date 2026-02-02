# Design: Game Assembly Strategy

## 1. Integration Strategy
We will use a "Bottom-Up" assembly approach:
- **Level 0 (Global)**: Autoloads and Input Maps.
- **Level 1 (Entities)**: Player and NPC scenes.
- **Level 2 (Environment)**: TileMaps, Layers, and World Gen.
- **Level 3 (Systems)**: Crafting, Power, Weather.
- **Level 4 (UI/UX)**: HUD, Menus, and Feedback.

## 2. UX/UI Polish Principles
- **Visual Feedback**: Every action (mining, picking up items, interacting) must have a visual cue (Tween animations, particles, or UI updates).
- **Input Consistency**: Use the `GameManager` to centralize input handling to prevent window overlapping or "flashing" UI.
- **Clarity**: Use the placeholder TileSet with clear labels until final assets are ready.

## 3. Key Integration Points
- **EventBus**: The central nervous system. All components must communicate via signals to remain decoupled.
- **GameState**: The central data store. All UI and logic must read from/write to `GameState.player_data`.
- **UIManager**: The gatekeeper of the screen. All windows must be opened/closed through this manager.

## 4. Step-by-Step Format
Each instruction will include:
1.  **Goal**: What we are achieving.
2.  **Editor Steps**: Specific nodes to add, properties to change, and scripts to attach.
3.  **Verification**: How to test if it works.
