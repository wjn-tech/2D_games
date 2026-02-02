# Tasks: Implement Procedural World Generation

- [ ] **Phase 1: Foundation & Assets**
    - [ ] 1.1 Create a new `TileSet` with placeholder textures (Dirt, Stone, Wood, Sand, Ore).
    - [ ] 1.2 Add custom data layers to the `TileSet` (`material_id`, `hardness`).
    - [ ] 1.3 Create a `WorldSettings` Resource to store seed, dimensions, and biome definitions.

- [ ] **Phase 2: Terrain Generation**
    - [ ] 2.1 Implement `WorldGenerator.gd` with `FastNoiseLite` integration.
    - [ ] 2.2 Generate 1D heightmap for the surface.
    - [ ] 2.3 Generate 2D noise for cave systems.
    - [ ] 2.4 Implement biome mapping logic (Forest vs Desert).

- [ ] **Phase 3: Structures & Features**
    - [ ] 3.1 Implement a `StructureManager` to handle template placement.
    - [ ] 3.2 Create 2-3 example structure templates (e.g., "Stone Ruin", "Wooden Shack").
    - [ ] 3.3 Scatter vegetation (trees, grass) based on biomes.

- [ ] **Phase 4: Visuals & Lighting**
    - [ ] 4.1 Set up `CanvasModulate` for global ambient light.
    - [ ] 4.2 Implement a basic `ParallaxBackground` with placeholder layers.
    - [ ] 4.3 Add a "Torch" item/light source for the player.

- [ ] **Phase 5: Integration & Testing**
    - [ ] 5.1 Create a `WorldGenTest.tscn` to demonstrate the generation.
    - [ ] 5.2 Ensure `DiggingManager` works correctly with generated tiles.
    - [ ] 5.3 Add a "Regenerate World" button for testing purposes.
