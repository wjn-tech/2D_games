- [x] **Assets: Palette**
  - [x] Create `res://assets/minimalist_palette.png` (Simple grid of colors).
  - [x] Create `res://assets/minimalist_tileset.tres` configuring the atlas.

- [x] **System: Background**
  - [x] Modify `src/systems/world/background_controller.gd`.
  - [x] Remove existing texture layers.
  - [x] Implement solid color with depth interpolation.

- [x] **System: Tiles**
  - [x] Update `WorldGenerator.gd` to point to new TileSet source IDs.
  - [x] Ensure `InfiniteChunkManager` palette maps to new IDs.

- [x] **System: Trees**
  - [x] Update `InfiniteChunkManager._generate_tree_at` logic to matches 3x3 pattern.
  - [x] Add `Slope` tiles to tileset for roots.

- [x] **Entities: Visuals**
  - [x] Create `res://scenes/characters/MinimalistVisual.tscn` (Implemented as `res://scenes/visuals/MinimalistEntity.tscn`).
  - [x] Update `Player.tscn` (Code injection in `player.gd`) to use MinimalistVisual.
  - [x] Update `BaseNPC` to conditionally use MinimalistVisual or replace sprite.
