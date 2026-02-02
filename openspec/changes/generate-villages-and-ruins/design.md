# Design: Village and Ruin Generation

## Architecture

### 1. Building Presets
Instead of purely procedural generation (which is complex to get right for interiors), we will use **Preset Scenes** with a **Medieval Wooden** aesthetic.
- Each preset will be a `.tscn` file containing:
    - A `TileMapLayer` (optional, for the structure itself if not using nodes).
    - `StaticBody2D` nodes for walls/roofs using wooden textures.
    - `Marker2D` nodes for NPC spawn points and Chest locations.
- **Building Types**:
    - `SmallHouse`: 1 NPC, 0-1 Chest. Medieval cottage style.
    - `Workshop`: 1 Specialized NPC (Blacksmith/Merchant), 1 Chest. Timber-framed design.
    - `Ruins`: Abandoned stone or rotted wood structures, 1-2 Chests.

### 2. Village Generation Logic
The `WorldGenerator` will be extended with a `_spawn_villages()` method:
1.  **Site Selection**: Find a wide area of flat ground (at least 30-50 tiles wide).
2.  **Layout**: Place 3-6 buildings with randomized spacing.
3.  **Pathing**: (Optional/Future) Add simple dirt paths between buildings.
4.  **NPC Spawning**: For each building, spawn the required NPC at its `Marker2D` location.

### 3. Loot System
- A new `Chest` node will be created.
- It will have a `LootTable` resource to determine what items it contains.
- Interacting with the chest opens a UI (reusing existing inventory/trade UI patterns).

### 4. Destructibility
- Buildings will be registered with the `DiggingManager` if they are tile-based.
- If they are node-based (like the current `Building.tscn`), they will need a `health` property or be instantly breakable by specific tools.

## Integration
- **WorldGenerator.gd**: Add `@export` arrays for village and ruin scenes.
- **NPC System**: Update `BaseNPC` to optionally "belong" to a home location.
- **Layering**: Ensure buildings are spawned on the correct `TileMapLayer` (Layer 0 for surface, Layer 1 for underground ruins).

## Trade-offs
- **Static vs. Procedural**: Preset scenes are easier to design and look better but are less varied. We will mitigate this by having multiple variations of each building type.
- **Performance**: Instantiating many scenes might be slower than setting tiles. We will limit the number of villages to 2-3 per world.
