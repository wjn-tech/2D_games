# Design: Minimalist Visual Style

## 1. Background System
The current `BackgroundController` uses ParallaxLayers. We will simplify this:
- **Sky**: Pure White (`Color(0.9, 0.9, 0.9)`) to avoid eye strain, but "white" in concept.
- **Underground**: Pure Black (`Color(0.0, 0.0, 0.0)`).
- **Transition**: Use `CanvasLayer` with a fullscreen `ColorRect`.
    - Script updates `ColorRect.color` based on `camera.y`.
    - Formula: `color = lerp(surface_white, deep_black, depth / max_depth)`.

## 2. Tileset System
Instead of loading distinct .png files for atlas regions, we will use a generated 16x16 minimalist palette.
- **Palette**: A single small texture (e.g., 64x64) where each pixel or small block is a color.
- **Mapping**:
    - Grass: Green
    - Dirt: Brown
    - Stone: Gray
    - Sand: Light Yellow/White
    - Mud: Black/Dark Gray
- **Technique**: Use a `TileSet` with `AtlasSource`. The input texture will be a `GradientTexture2D` or a manually constructed small PNG during runtime (or a saved resource). For simplicity and editability, we might use a small mapped png.

## 3. Tree Generation
Modify `InfiniteChunkManager._generate_tree_at`:
- **Canopy (3x3)**:
    - Row 1: `[G, G, G]`
    - Row 2: `[G, B, G]`
    - Row 3: `[G, B, G]`
- **Trunk**: Brown Blocks (`B`).
- **Roots**: Special shape. Since we want "Right Triangle" blocks, this implies the TileSet need slanted tiles.
    - **Requirement**: Add `Slope` tiles to the TileSet.

## 4. Entity Representation
- **Player/NPC**: Replace `AnimatedSprite2D` with a composed `Node2D` containing `ColorRect`s or `Sprite2D`s using 1x1 pixel textures scaled up.
- **Structure**:
    - `VisualRoot` node.
    - `Body` (16x32 block).
    - Optional `Head/Eyes` for direction.
