# Specification: World Generation

## ADDED Requirements

### Requirement: Procedural Terrain Generation
The system SHALL generate a 2D side-scrolling terrain based on a seed, including surface variation and underground caves.

#### Scenario: Generating a new world
- **GIVEN** A world seed and dimensions (e.g., 500x200 tiles).
- **WHEN** The `WorldGenerator` is triggered.
- **THEN** A `TileMapLayer` is populated with tiles representing surface (dirt/grass), underground (stone), and empty spaces (caves).

### Requirement: Biome Diversity
The system SHALL support multiple biomes with distinct tile sets and generation rules.

#### Scenario: Transitioning between biomes
- **WHEN** The generator moves across the horizontal axis.
- **THEN** The surface tile changes from "Grass" (Forest) to "Sand" (Desert) based on the biome map.

### Requirement: Placeholder TileSet
The system SHALL use a TileSet with clearly labeled placeholder textures for development.

#### Scenario: Identifying tile types
- **WHEN** A developer looks at the generated world.
- **THEN** Tiles are visually distinguishable by labels (e.g., "D" for Dirt, "S" for Stone, "W" for Wood).
