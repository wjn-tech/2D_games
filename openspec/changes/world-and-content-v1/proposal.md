# Proposal: World Construction and Content Integration

## 1. Problem Statement
The project currently has a robust technical skeleton (14 core systems) and a functional UI framework, but it lacks a playable world and the data (Resources) to drive the sandbox experience. There is no procedural terrain, and the systems are not yet integrated into a cohesive gameplay loop.

## 2. Proposed Solution
We will implement the "World & Content" layer:
1.  **Procedural World Generation**: Create a `WorldGenerator` that uses `FastNoiseLite` to generate multi-layered terrain (Surface, Underground, Deep).
2.  **Data-Driven Content**: Define and create initial `.tres` resources for Items, Recipes, and NPC types.
3.  **System Integration**: Connect the `LayerManager` with the generated world and ensure the `Player` can interact with resources across different layers.
4.  **Gameplay Loop**: Implement the "Mining -> Crafting -> Building -> Settlement" cycle.

## 3. Scope
- **In-Scope**:
    - `WorldGenerator` script and scene.
    - `TileSet` configuration for 3 layers.
    - Resource definitions for `BaseItem`, `Recipe`, `NPCData`.
    - Integration of `Gatherable` nodes into the world gen.
- **Out-of-Scope**:
    - Advanced AI behaviors (beyond basic wander/chase).
    - Final high-fidelity art assets.
    - Multiplayer networking.

## 4. Impact
- **Architecture**: Introduces a centralized world generation flow.
- **Performance**: Uses `TileMapLayer` for efficient rendering of large sandbox areas.
- **UX**: Provides the first "playable" environment for the user.
