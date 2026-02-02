# Design: World and Content Architecture

## 1. Procedural Generation Flow
The `WorldGenerator` will follow these steps:
1.  **Noise Setup**: Configure `FastNoiseLite` for terrain height and resource distribution.
2.  **Layer Mapping**:
    - **Layer 0 (Surface)**: Grass, trees, surface ores.
    - **Layer 1 (Underground)**: Stone, caves, iron/copper.
    - **Layer 2 (Deep)**: Hard rock, lava, rare gems.
3.  **Chunking**: (Optional for V1) Divide the world into chunks for performance.
4.  **Entity Spawning**: Place NPCs and `Gatherable` nodes based on noise thresholds.

## 2. Data-Driven System
We will use Godot's `Resource` system to allow easy expansion:
- `BaseItem`: ID, Name, Icon, Type (Material, Tool, Food).
- `Recipe`: Inputs (Item + Qty), Output (Item), Station required.
- `NPCData`: Stats, SpriteFrames, AI Type.

## 3. Multi-Layer Interaction
- The `LayerManager` will toggle the visibility and collision of `TileMapLayer` nodes.
- `LayerDoor` nodes will be procedurally placed to allow the player to move between layers.

## 4. Integration with 14 Systems
- **Industrial**: Power grids will be placed on the `Underground` layer.
- **Settlement**: NPCs will be recruited and assigned to "Jobs" which correspond to world coordinates.
- **Lineage**: Character data will be saved as resources to persist across world regenerations.
