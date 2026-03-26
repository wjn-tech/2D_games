# Capability: Planetary World Topology

## ADDED Requirements

### Requirement: Finite Horizontal Circumference
Each planetary world MUST define a finite horizontal circumference for traversal and generation.

#### Scenario: Walking east around the world
- **GIVEN** a planetary world with a defined horizontal circumference
- **WHEN** the player keeps moving east across the final surface chunk boundary
- **THEN** the next generated or loaded chunk MUST be the wrapped western neighbor of the same world
- **AND** completing one full circumference MUST return the player to the same originating world region instead of entering newly invented terrain

### Requirement: Topology Selection For New Worlds
New world creation MUST choose an explicit topology mode and supported world-size preset before generation begins.

#### Scenario: Creating a new planetary world
- **GIVEN** the player starts a new save
- **WHEN** the game initializes a planetary world
- **THEN** the save metadata MUST record a planetary topology mode and a supported world-size preset
- **AND** the circumference used by generation and streaming MUST be derived from that preset instead of an implicit infinite default

### Requirement: Seam-Safe Wrapped Distance
Systems that compare horizontal positions MUST use shortest wrapped distance rather than unbounded absolute x distance.

#### Scenario: Querying nearby content across the seam
- **GIVEN** the player is near the eastern seam and a landmark lies just west of the world origin
- **WHEN** the game evaluates regional proximity, spawn relevance, or map queries
- **THEN** the landmark MUST be treated as nearby using wrapped distance
- **AND** the seam MUST NOT cause the two positions to be treated as opposite ends of an infinite world

### Requirement: Canonical Wrapped Coordinates
Chunk addressing and topology-aware world queries MUST normalize horizontal coordinates to canonical wrapped identifiers.

#### Scenario: Loading the same seam chunk from either side
- **GIVEN** a world with wrapped chunk indices
- **WHEN** the seam-adjacent chunk is requested from the eastern side and later from the western side
- **THEN** both requests MUST resolve to the same canonical chunk identity
- **AND** the system MUST NOT create duplicate runtime chunks for the same physical world segment