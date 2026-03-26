# Proposal: Implement Planetary Ring Topology and Physics-Based Fluid System

This proposal refactors the `WorldGenerator` to support a finite, seamless "Ring World" topology (as per `WorldTopology` configuration) and integrates a dynamic physics-based fluid system.

## Problem Statement
The current `WorldGenerator` implementation assumes an infinite, open-ended world. This leads to:
1.  **Seam Artifacts**: Linear noise sampling (`get_noise_1d(x)`) creates visible discontinuity at the world wrap-around point ($x=0$ and $x=W$).
2.  **Missing Features**: Key generation steps (liquid settling, smoothing, global structures) are skipped because they require global context, which was deemed impossible in an infinite world.
3.  **Static Liquids**: Liquids are currently static tiles without physical behavior or settling logic.

## Proposed Changes

### 1. Planetary Ring Topology (Seamless Generation)
Switch the noise sampling strategy from linear Cartesian coordinates to **Cylindrical/Polar Coordinates**.
- **Old**: `noise(x, y)`
- **New**: `noise(R * cos(θ), R * sin(θ), y)` where $\theta = \frac{x}{WorldWidth} \times 2\pi$.
- This ensures that $f(0, y) \equiv f(W, y)$, creating a perfectly seamless loop.

### 2. Restore Global Generation Passes
Since the world now has a finite circumference (defined in `WorldTopology`), we can restore the "Global Automata" phases that were skipped:
- **Step 51/99 (Liquid Settle)**: Run physically-simulated settling for a fixed duration during generation.
- **Step 55 (Smooth World)**: Apply cellular automata smoothing across all chunk seams.
- **Biomes**: Re-enable global biome placement logic (e.g., Dungeon, Jungle Temple) that relies on fixed world positions.

### 3. Cellular Automata Fluid System (Grid-Based)
Instead of expensive rigid-body physics, we will implement a high-performance **Cellular Automata (Grid-Based)** fluid system, similar to Terraria/Minecraft.
- **Why**: Rigid body fluids cannot scale to massive oceans or deep lakes efficiently in a tile-based game. Grid-based fluids differ seamlessly with the tilemap and allow for vast volumes of liquid.
- **Core Mechanism**:
    - **Liquid Layer**: A dedicated data layer (e.g., Layer 3 or a dictionary) storing liquid type and level (0.0 to 1.0) per tile.
    - **Flow Logic**: Liquids flow Down -> Side -> Equalize.
    - **Settling**: Liquids "sleep" when stable to save CPU.
- **Seamless Chunking**: Liquid simulation wakes up when chunks load and freezes when they unload, preserving the state perfectly.

## Scenarios
#### Scenario 1: Seamless Travel
- **Given** a generated Ring World of width 384 chunks.
- **When** the player travels from chunk 383 to chunk 0.
- **Then** the terrain height, biome, and caves should visually connect perfectly without any "chunk wall" or sharp transition.

#### Scenario 2: Dynamic Water Flow
- **Given** a lake in a loaded chunk.
- **When** the player digs a tunnel at the bottom of the lake.
- **Then** the water should flow down the tunnel tile-by-tile, draining the lake and filling the space below, eventually settling.

#### Scenario 3: Global Structure Placement
- **Given** a finite world plan.
- **When** generation starts.
- **Then** the system guarantees exactly one Dungeon, one Jungle, and other unique structures are placed at specific intervals on the number line ($0$ to $W$), ensuring they exist and don't overlap.
