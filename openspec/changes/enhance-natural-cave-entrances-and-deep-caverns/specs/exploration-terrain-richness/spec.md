## ADDED Requirements

### Requirement: Surface Terrain SHALL Telegraph Underground Opportunities
Surface terrain generation SHALL provide readable cues that indicate likely underground access opportunities.

#### Scenario: Player can identify likely descent points from terrain shape
- **WHEN** a player scans nearby terrain during normal exploration
- **THEN** terrain silhouettes and local formations provide readable hints for underground entry opportunities
- **AND** entry cue readability does not depend solely on decorative props

### Requirement: Surface Regions SHALL Use Biome-Appropriate Entrance Families
The world generation system SHALL bias entrance-family selection by local biome and relief context.

#### Scenario: Entrance silhouettes vary with region context
- **WHEN** representative biome and relief regions are generated
- **THEN** at least two entrance-family silhouettes are used across the same world
- **AND** chosen silhouettes remain compatible with local region identity

### Requirement: Surface Entrance Density SHALL Be Budgeted
Natural cave entrances SHALL follow deterministic density and spacing budgets.

#### Scenario: Entrances are discoverable without over-fragmenting surface
- **WHEN** a full world is generated and sampled across representative regions
- **THEN** entrances appear frequently enough to support exploration
- **AND** spacing and per-region caps prevent excessive continuous surface fragmentation

### Requirement: Starter Surface SHALL Preserve Safe Early Traversal
Starter surface terrain SHALL remain forgiving while still exposing early exploration hooks.

#### Scenario: Starter corridor remains traversable and informative
- **WHEN** a new player explores the spawn-adjacent corridor
- **THEN** terrain avoids repeated severe cliffs or trap-like fissures that block expected early movement
- **AND** the corridor still exposes at least one readable underground exploration prompt
