# Mineral Generation Design

## Architectural Changes

### 1. New Mineral Definition
Minerals will be defined by strictly typed constants in `WorldGenerator` (Atlas Coords) and corresponding `BaseItem` resources.

### 2. Infinite World Adaptation Strategy
The user's reference code assumes a finite world with global tectonic simulation. We will adapt this to an **Infinite 2D Side-Scroller** using **stateless noise functions**.

*   **Coordinate System**: 
    *   X: Infinite Horizontal Axis.
    *   Y: Depth (0 = Surface, +Y = Down).
*   **Plate Simulation**:
    *   Instead of global arrays, we use `FastNoiseLite(TYPE_CELLULAR)` to determine "local geological regions".
    *   Regions with high "geological activity" (noise value) will have higher ore density.

### 3. Generation Algorithm (Noise Stacking)
To avoid complex stateful "walkers" that break at chunk boundaries, we use a **Noise Masking** approach:
1.  **Base Terrain**: Generated first (Dirt/Stone/Biomes).
2.  **Mineral Pass**: Iterate over stone/dirt blocks and apply mineral masks.
    *   `Map(x, y)` -> `MineralType`
    *   Rule: `if Noise_MineralA(x,y) > Threshold_A and Depth_Valid(y): Place MineralA`

### 4. Depth Stratification (Y-Axis)
We divide the world into vertical layers:
*   **Layer 0 (Surface / Shallow)**: Y < 100. Copper, Iron (Sparse).
*   **Layer 1 (Underground)**: 100 < Y < 300. Iron, Magic Crystal, Staff Core.
*   **Layer 2 (Deep)**: Y > 300. Magic Speed Stone, High-density clusters.

## Implementation Details

### Asset Pipeline (`update_palette.py`)
We will expand the Python script to generate the following minimalist icons (16x16 geometry):
-   **Iron**: Grey background, rust-colored triangles.
-   **Copper**: Grey background, orange/brown squares.
-   **Magic Crystal**: Dark background, purple shard.
-   **Staff Core**: Dark background, glowing blue circle.
-   **Magic Speed Stone**: Dark background, cyan lightning bolt/jagged shape.

### Data Structures
Update `WorldGenerator.gd`:
```gdscript
const MINERAL_TILES = {
    "iron": Vector2i(x, y),
    "copper": Vector2i(x, y),
    ...
}
```

Update `DiggingManager.gd`:
Add loot table entries mapping Atlas Coords -> Item Resources.
