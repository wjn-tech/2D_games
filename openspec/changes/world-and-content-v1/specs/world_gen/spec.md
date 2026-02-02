# Capability: Procedural World Generation

## ADDED Requirements

### Requirement: Multi-Layer Terrain Generation
The system must generate three distinct physical layers using noise functions.

#### Scenario: Surface Generation
- **Given**: A random seed.
- **When**: The `WorldGenerator` initializes.
- **Then**: It should create a `TileMapLayer` for Layer 0 with grass, trees, and surface resources.

#### Scenario: Layer Transition
- **Given**: The player is at a `LayerDoor`.
- **When**: The player interacts with the door.
- **Then**: The `LayerManager` should switch the active collision layer and visibility to the target layer.

### Requirement: Resource Distribution
Resources (ores, wood) must be distributed based on noise density.

#### Scenario: Ore Vein Spawning
- **Given**: A noise map for "Iron Density".
- **When**: Generating Layer 1 (Underground).
- **Then**: Clusters of `Gatherable` nodes or specific Tile IDs should be placed where density > 0.7.
