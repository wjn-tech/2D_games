## ADDED Requirements

### Requirement: Major Biome and Depth Bands SHALL Have Native Hostile Identity
The hostile spawning system SHALL provide biome- and depth-matched hostile families so exploration regions do not rely on the same small shared roster everywhere.

#### Scenario: Surface biomes gain native hostile presence
- **WHEN** the game evaluates hostile spawns for major surface biomes
- **THEN** each major biome has at least one native hostile family or variant that is favored there over generic fallback spawns

#### Scenario: Underground bands gain native hostile presence
- **WHEN** the game evaluates hostile spawns for underground and cavern depth bands
- **THEN** those bands include hostile families or variants that are favored by depth and underground biome identity rather than only surface carryovers

#### Scenario: Cave-native encounters differ by underground region type
- **WHEN** the game evaluates hostile spawns inside different underground cave archetypes or cave-region classes
- **THEN** encounter selection can vary by cave context such as chamber, tunnel, open cavern, or equivalent underground region identity

### Requirement: Hostile Composition SHALL Match Terrain Context
The spawning system SHALL use terrain context to shape encounter composition, not only raw biome labels.

#### Scenario: Terrain features influence encounter composition
- **WHEN** hostile spawn logic evaluates positions near themed caves, landmarks, or biome-specific terrain regions
- **THEN** spawn weighting, grouping, or family selection responds to that terrain context in a deterministic way

### Requirement: Cave Hostile Placement SHALL Respect Reachability and Fairness
The hostile spawning system SHALL respect cave reachability so underground encounters are placed in spaces the player can meaningfully enter, fight through, and exit.

#### Scenario: Regular cave encounters avoid sealed pockets
- **WHEN** the spawn system evaluates regular hostile placements inside underground caves
- **THEN** it avoids placing standard encounters in sealed, unreachable, or trivially unfair cave pockets unless those spaces are explicitly designated as special challenge areas

#### Scenario: Cave encounter pressure matches available space
- **WHEN** the spawn system places hostile groups in narrow tunnels, open chambers, or vertical cave connectors
- **THEN** the chosen hostile family, grouping, or attack style is compatible with the local traversal space instead of producing constant pathing or combat breakdowns
