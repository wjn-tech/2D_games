## ADDED Requirements

### Requirement: Underground Generation SHALL Expose Natural Surface Entrances
The world generation system SHALL expose deterministic, readable surface-to-underground entrances as first-class generation outputs.

#### Scenario: Surface traversal discovers cave entries
- **WHEN** a player traverses representative non-spawn surface regions in a new world
- **THEN** the player periodically encounters readable cave entry points such as cave mouths, ravine cuts, sinkholes, cliff slits, funnel descents, or equivalent forms
- **AND** those entry points are deterministic for the same seed and topology metadata

#### Scenario: Spawn-safe area provides at least one forgiving descent
- **WHEN** the world is generated around the spawn-safe corridor
- **THEN** at least one early-game appropriate underground entry route is discoverable within bounded travel distance
- **AND** that route does not violate starter safety constraints

### Requirement: Underground Generation SHALL Provide Broad Deep-Cavern Progression
The world generation system SHALL produce deeper underground spaces with layered progression and visibly broader cave character than shallow bands.

#### Scenario: Deep descent changes cave scale and feel
- **WHEN** the player descends across ordered underground depth bands
- **THEN** cave openness, room scale, and connector behavior change in a readable progression
- **AND** deeper bands include broader cavern outcomes rather than only narrow tunnel repetition

#### Scenario: Deep cavern identity remains deterministic
- **WHEN** the same seed and chunk coordinates are regenerated after unload or reload
- **THEN** deep-cavern shape identity and depth-band classification remain stable

### Requirement: Underground Generation SHALL Include Shaped Large-Space Archetypes
The world generation system SHALL include deliberately shaped underground archetype families for large exploration spaces.

#### Scenario: Representative seeds contain large-space archetypes
- **WHEN** representative seeds are generated across supported world sizes
- **THEN** underground spaces include recognizable archetypes such as large chambers, horizontal galleries, compartment clusters, or equivalents
- **AND** these archetypes are not reduced to random isotropic carve noise pockets

### Requirement: Underground Generation SHALL Provide Long-Form Connector Routes
The world generation system SHALL provide at least one long-form connector route family that links multiple major cave spaces.

#### Scenario: Long connector route supports sustained traversal
- **WHEN** a player follows a generated long-form route in a representative underground region
- **THEN** the route connects multiple major cave spaces over meaningful distance
- **AND** the player can maintain orientation without repeatedly creating manual vertical shafts

### Requirement: Underground Generation SHALL Stay Streaming-Safe
The world generation system SHALL preserve walking-time smoothness while upgrading cave quality.

#### Scenario: Critical chunk load stays responsive during movement
- **WHEN** the player moves continuously through cave-heavy regions
- **THEN** traversal-critical chunk generation completes within bounded runtime work suitable for smooth movement
- **AND** non-critical enrichment is deferred without breaking immediate traversability

#### Scenario: New cave outputs preserve chunk continuity
- **WHEN** shaped entrances and deep-cavern archetypes cross chunk boundaries
- **THEN** geometry and traversal continuity remain intact across chunk seams
- **AND** wrapped-world seam behavior remains consistent
