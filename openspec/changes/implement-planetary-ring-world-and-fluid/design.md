# Design: Implement Planetary Ring Topology and Physics-Based Fluid System

## Architecture Overview

The core change is shifting from Cartesian Noise to **Polar/Cylindrical Noise** for terrain generation, and integrating a rigid-body fluid simulation for the water/lava system.

### 1. Cylindrical Noise Mapping

To achieve seamless world wrapping ($X=0$ connected to $X=W$), we map 2D coordinates `(x, y)` to 3D cylindrical coordinates `(x', y', z')`:

1.  **Global Parameters**:
    - `WorldCircumference`: The total width of the world (e.g., 512 chunks = 32768 tiles).
    - `WorldRadius`: `WorldCircumference / (2 * PI)`.

2.  **Mapping Formula**:
    - `theta = (x / WorldCircumference) * 2 * PI`
    - `x' = WorldRadius * cos(theta)`
    - `y' = WorldRadius * sin(theta)`
    - `z' = y` (vertical axis remains linear)
    - `noise_val = noise_3d(x', y', z')`

This transformation guarantees that `noise(0, y)` is sampled at `(R, 0, y)` and `noise(W, y)` is sampled at `(R, 0, y)`, ensuring **perfect continuity**.

### 2. Global Generation Pipeline

Restore the skipped global passes by iterating through the finite world:

1.  **Phase 1**: Generate base terrain and biomes (Parallel/Chunked).
2.  **Phase 2 (Global)**: Locate unique structures (Dungeon, Jungle Temple) based on absolute positions.
3.  **Phase 3 (Global)**: **Fluid Settle Simulation**. Since the world is bounded, iterate a cellular automata simulation for N steps to settle all liquids into stable pools *before* gameplay starts.
4.  **Phase 4 (Global)**: **Smooth World**. Apply smoothing filters across chunk boundaries.

### 3. Cellular Automata Fluid System (Grid-Based)

#### 3.1. Data Model
- **Storage**: `ChunkData` will include a `fluid_grid: PackedByteArray` (size matching chunk dimensions, e.g., 16x16 or 32x32).
    - `0`: Empty
    - `1-8`: Water Level (1=low, 8=full block)
    - `9-16`: Lava Level, etc.
- **State**: Fluids have `static` and `active` states. Active fluids are candidates for update in the next tick.

#### 3.2. Simulation (Cellular Automata)
- **Ticking**: A global `FluidManager` ticks every N frames (e.g., 5-10 ticks/sec, independent of rendering).
- **Rules**:
    1.  **Down**: If space below is empty/not full, move liquid down.
    2.  **Flow**: If space below is blocked, flow Left/Right.
    3.  **Refill**: Source blocks (infinite springs) regenerate if enabled; finite liquid drains.
    4.  **Settle**: If a liquid cannot move, mark it as `Sleep`. Waking requires neighbor updates.
- **Optimization**:
    - Only chunks in the "Active Simulation Radius" (usually smaller than visual radius) are processed.
    - `ActiveChunkSet` tracks chunks with moving liquid.

#### 3.3. Rendering
- **Visuals**: Use a dedicated `TileMapLayer` (Godot 4.3+) for liquids to allow semi-transparency and smooth meshing if desired.
- **Shader**: A shader on the liquid tiles handles the "wobbly" surface effect or flow animation, keeping the logic discrete.
    "fluid_particles": [
        { "pos": Vector2(100, 200), "vel": Vector2(0, 0), "type": "water" },
        ...
    ]
}
```

### 4. Trade-offs

- **Performance vs. Simulation**: Running a full physics simulation for fluids is expensive. We must limit the number of active particles or use a hybrid approach (Cellular Automata for large bodies, Physics Particles for small splashes).
- **Generation Time**: Global passes increase generation time compared to pure streaming generation. However, for a finite world, this one-time cost is acceptable for higher quality.
