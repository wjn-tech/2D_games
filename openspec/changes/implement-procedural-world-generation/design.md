# Design: Procedural World Generation

## Architecture Overview
The world generation follows a layered approach:
1.  **Base Terrain**: 1D Noise for surface height, 2D Noise for cave density.
2.  **Biome Mapping**: Divide the horizontal axis into regions (Forest, Desert, etc.).
3.  **Feature Placement**: Scatter ores, trees, and small plants.
4.  **Structure Injection**: Place larger pre-defined structures (JSON or Scene-based templates).

## Technical Details

### 1. Noise and Biomes
We will use `FastNoiseLite` for deterministic generation based on a seed.
- **Heightmap**: `noise.get_noise_1d(x)` determines the surface level.
- **Caves**: `noise.get_noise_2d(x, y)` with a threshold determines if a tile is empty.
- **Biomes**: A simple `Dictionary` mapping x-ranges to `BiomeResource` objects containing tile IDs and decoration rules.

### 2. TileSet Structure
The `TileSet` will be organized by "Material Type" using custom data layers:
- `material_id`: String (e.g., "dirt", "stone").
- `hardness`: Int (for mining power checks).
- `is_background`: Bool (for background wall layers).

### 3. Structure Templates
Structures will be defined as `StructureTemplate` resources or small `.tscn` files that the generator "paints" onto the `TileMapLayer`.
- **Minable**: Since they are painted as tiles, they naturally inherit the `DiggingManager` logic.

### 4. Lighting
- **Global**: `CanvasModulate` for ambient light.
- **Local**: `PointLight2D` for torches and glowing ores.
- **Shadows**: Enable `LightOccluder2D` on solid tiles to create cave atmosphere.

## Trade-offs
- **Fixed Size vs Infinite**: Fixed size allows for easier global features (like a world-ending dungeon at the edge) and simpler saving/loading, but limits long-term exploration.
- **Tile-based vs Sprite-based Structures**: Tile-based structures are easier to mine/modify but harder to animate or give complex physics. We will stick to tile-based for the "sandbox" feel.
