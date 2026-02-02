# Design: World Expansion and Parallax Background

## Architecture
The world expansion will be handled by modifying the `WorldGenerator` parameters. The background system will be a new component integrated into the main scene.

### 1. World Expansion
- **WorldGenerator.gd**: Update `@export` variables `world_width` and `world_height` to 1000 and 500 respectively.
- **Performance**: Since the current generation is tile-by-tile in a loop, 500,000 tiles might take a few seconds. We will ensure the generation process is as efficient as possible without moving to a full chunking system yet (to keep it simple as per guardrails).

### 2. Parallax Background System
- **Node Structure**:
    - `ParallaxBackground` (Global or per-scene)
        - `ParallaxLayer` (Sky - Scale 0.0)
            - `Sprite2D` (Gradient or solid color)
        - `ParallaxLayer` (Distant Mountains - Scale 0.1)
            - `Sprite2D` (Repeating texture)
        - `ParallaxLayer` (Mid-ground Hills - Scale 0.3)
            - `Sprite2D` (Repeating texture)
- **Assets**: We will use existing assets from `assets/background/` or create simple placeholders if suitable assets aren't found.
- **Integration**: The background will be added to `test.tscn` (the current main scene).

### 3. Vertical Background Transition
- A script will monitor the camera's Y position.
- When the player goes below the "surface" level (e.g., Y > 0 in map coordinates), the background will transition to an "Underground" style (darker, rocky textures).

## Trade-offs
- **Static vs. Dynamic**: A full dynamic sky system (day/night) is deferred to a later proposal to keep this change scoped to "Terraria-style background".
- **Memory**: A 1000x500 TileMapLayer uses more memory but is well within Godot's capabilities for a 2D game.
