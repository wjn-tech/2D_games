# Tasks: Implement Planetary Ring Topology and Physics-Based Fluid System

## 1. Implement Cylindrical Noise
- [x] Implement `WorldGenerator.get_noise_cylindrical(noise_obj, x, y, circumference, frequency)`: Map 2D linear x/y to 3D cylindrical coordinates.
- [x] Update `WorldGenerator` to use `get_noise_cylindrical` for all surface height (`noise_continental`), biome (`noise_temperature`), and cave structure (`noise_cave`, `noise_tunnel`) generation.
- [x] Add `WorldTopology.is_planetary_ring()` to query if the world is a ring world. If true, use cylindrical mapping.

## 2. Restore Global Generation Passes
- [x] Restore `WorldGenerator.generate_global_map()` to execute generation in passes for a defined `world_width`.
- [x] Implement `WorldGenerator.settle_liquids()`: Global cellular automata simulation step to settle all `_liquid_seeds` into stable pools.
- [x] Implement `WorldGenerator.smooth_world()`: Apply smoothing filters across chunk boundaries (since the world is finite).
- [x] Validate standard structures (Dungeon, Jungle, etc.) are placed uniquely and correctly in global coordinates.

## 3. Implement Cellular Automata Fluid System (Grid-Based)
- [x] **Data Model**:
    - [x] Create `FluidComponent` for chunks (PackedByteArray, size 16x16 or 32x32).
    - [x] Define liquid constants (WATER, LAVA, HONEY, levels 0-8).
- [x] **FluidManager**:
    - [x] Implement `active_chunk_set` tracking.
    - [x] Implement `tick()` function with CA rules (Down -> Side -> Equalize).
    - [x] Implement `settle` logic (sleep if static).
- [x] **Rendering**:
    - [x] Create `FluidTileLayer` scene (or use dedicated TileMapLayer).
    - [x] Add shader for liquid surface animation.
- [x] **Integration**:
    - [x] Hook `ChunkManager` load/unload to hydrate/dehydrate fluid layer from disk.

## 4. Global Structure Planner
- [x] Implement `WorldStructurePlanner` which runs *before* chunk generation.
- [x] Reserve X-ranges for Dungeon, Jungle, etc. on the ring [0, W].
- [x] Pass structure constraints to `WorldGenerator` (e.g., "At X=500, force Dungeon Pattern").

## 4. Optimization & Polish
- [x] Optimize `FluidParticleManager`: Only update active physics bodies. Freeze settled bodies.
- [x] Verify seamless transition at world wrap-around ($x=0 \leftrightarrow x=W$).
- [x] Benchmark generation time and runtime fluid performance.
