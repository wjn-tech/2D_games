# Capability: World Streaming And Persistence

## ADDED Requirements

### Requirement: Wrapped Chunk Streaming
Runtime chunk streaming MUST remain continuous when the player crosses the east/west seam.

#### Scenario: Crossing the seam during normal play
- **GIVEN** a loaded world where the player approaches the eastern or western boundary of the circumference
- **WHEN** the player crosses that seam during normal movement
- **THEN** neighboring wrapped chunks MUST stream in as direct neighbors
- **AND** the player experience MUST remain continuous without teleport-style discontinuity or visible seam gaps

#### Scenario: Seam-adjacent systems query the same region
- **GIVEN** the player, minimap, or spawn logic references a seam-adjacent area from opposite sides of the world
- **WHEN** those systems request runtime chunk or region data
- **THEN** they MUST resolve the same canonical world segment
- **AND** they MUST NOT diverge because one caller used pre-wrap coordinates and another used post-wrap coordinates

### Requirement: Canonical Delta Persistence
World modifications MUST persist against canonical wrapped chunk identities.

#### Scenario: Reloading edits near the seam
- **GIVEN** the player modifies terrain near the east/west seam of a planetary world
- **WHEN** the area unloads and later reloads from either side of the seam
- **THEN** the same saved delta data MUST be reapplied to the same physical world segment
- **AND** the system MUST NOT lose edits or duplicate them under two different seam-side keys

### Requirement: Topology-Aware Save Compatibility
Save data MUST record the world topology needed to interpret chunk coordinates correctly.

#### Scenario: Loading a legacy infinite-world save
- **GIVEN** a save created before planetary topology metadata existed
- **WHEN** the game attempts to load it in a topology-aware build
- **THEN** the game MUST detect that the save lacks compatible topology metadata
- **AND** it MUST enter an explicit legacy handling path instead of silently treating the save as a planetary world

#### Scenario: Loading a saved planetary world
- **GIVEN** a save created from a planetary world
- **WHEN** the game restores that save in a later session
- **THEN** the saved topology mode, topology version, circumference, and related world metadata MUST be restored before seam-sensitive chunk data is interpreted
- **AND** runtime systems MUST use that restored metadata instead of editor defaults or currently loaded scene defaults