# Proposal: Implement Procedural World Generation and Sandbox Core

## Problem
The current game world is a static test scene (`test.tscn`) with manually placed tiles and resources. To achieve the "sandbox" vision, the game needs a system to generate varied, exploration-rich environments automatically.

## Proposed Changes
Implement a procedural generation system for a fixed-size 2D side-scrolling world. This includes terrain (biomes, caves), pre-defined minable structures, a multi-layer background system, and a basic lighting system.

### Core Components
1.  **World Generator**: A central manager that uses noise (FastNoiseLite) to generate terrain heightmaps and cave systems.
2.  **Biome System**: Defines rules for tile types, vegetation, and background layers based on horizontal position.
3.  **Structure Manager**: Handles the placement of pre-defined "stamps" (ruins, houses) into the generated terrain.
4.  **TileSet Expansion**: Create a comprehensive TileSet with placeholder textures for various materials (Dirt, Stone, Wood, Ore, etc.).
5.  **Lighting System**: A simple 2D lighting setup using `PointLight2D` for torches and `CanvasModulate` for day/night or cave darkness.

## Impact
- **Gameplay**: Provides replayability and exploration depth.
- **Architecture**: Introduces a data-driven approach to world building.
- **Assets**: Requires a structured TileSet that can be easily updated with final art.

## Verification Plan
- **Automated**: Unit tests for noise-to-tile mapping logic.
- **Manual**: Visual inspection of generated maps in a dedicated "World Gen Test" scene. Verify that structures are correctly embedded and minable.
