## ADDED Requirements

### Requirement: Major Biomes SHALL Present Distinct Exploration Content
The exploration layer SHALL make major biomes feel different through deterministic terrain enrichments beyond base ground materials.

#### Scenario: Surface biome identity is readable in traversal
- **WHEN** a player moves across major surface biomes in a fresh world
- **THEN** each biome presents its own combination of terrain decoration, landmarking, material variation, or traversal silhouette
- **AND** those enrichments are preserved across chunk reloads for the same seed and coordinates

#### Scenario: Terrain enrichments coexist with chunk streaming and deltas
- **WHEN** enriched terrain chunks are loaded, unloaded, and reloaded after player edits
- **THEN** generated enrichments reappear deterministically
- **AND** player deltas continue to override generated tiles or placed entities without corruption

### Requirement: Terrain Richness SHALL Reinforce Exploration Decisions
The terrain system SHALL place content in ways that encourage route choice instead of only visual noise.

#### Scenario: Landmarks imply route or reward differences
- **WHEN** the player encounters biome landmarks, transition zones, or notable terrain formations
- **THEN** those features imply a meaningful difference in traversal, resource expectation, encounter type, or navigational guidance
