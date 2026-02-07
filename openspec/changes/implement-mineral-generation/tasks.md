# Implementing Mineral Generation

## Tasks

### 1. Asset Generation
- [x] Update `tools/update_palette.py` to include new mineral definitions:
    -   Iron Ore (Rusty Triangles)
    -   Copper Ore (Orange Squares)
    -   Magic Crystal (Purple Shard)
    -   Staff Core (Blue Orb)
    -   Magic Speed Stone (Cyan Bolt)
- [x] Run `update_palette.py` to regenerate `assets/minimalist_palette.png`.
- [x] Update `assets/minimalist_tileset.tres` to include physics/collision for the new tile coordinates.

### 2. Resource Definition
- [x] Create `res://data/items/minerals/` directory.
- [x] Create `BaseItem` resources (`.tres`) for:
    -   `iron_ore.tres`
    -   `copper_ore.tres`
    -   `magic_crystal.tres`
    -   `staff_core.tres`
    -   `magic_speed_stone.tres`
- [x] Assign correct icons (AtlasTexture) to these resources.

### 3. World Generation Logic
- [x] Update `src/systems/world/world_generator.gd`:
    -   Add `export` variables for Mineral Atlas Coordinates.
    -   Initialize `FastNoiseLite` instances for mineral veins (distinct seeds/frequencies).
    -   Implement `_get_mineral_at(x, y)` function using noise thresholds and depth checks.
    -   Integrate into the block placement loop (replace generic Stone with Minerals based on probability).

### 4. Loot Tables
- [x] Update `src/systems/world/digging_manager.gd`:
    -   Update `_get_custom_data` (or the equivalent loot switch) to return the new Mineral Resources when mining the new Atlas Coordinates.

### 5. Validation
- [x] Run `scenes/test.tscn`.
- [x] Fly/Teleport to deep layers (Y > 300).
- [x] Verify visual presence of rare minerals.
- [x] Mine minerals and verify correct item drops in inventory.
