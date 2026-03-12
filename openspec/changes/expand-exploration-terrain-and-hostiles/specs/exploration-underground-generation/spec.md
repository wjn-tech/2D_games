## ADDED Requirements

### Requirement: Underground Cave Networks SHALL Provide Distinct Traversal Archetypes
The world generation system SHALL produce underground cave spaces using more than a single carve-threshold pattern, so that players encounter distinct traversal archetypes within the infinite world.

#### Scenario: Representative underground regions differ in structure
- **WHEN** the game generates underground chunks for multiple deterministic seeds and depth bands
- **THEN** the resulting cave layouts include at least chamber-like spaces, connective tunnel-like paths, and biome-themed underground pockets or equivalents
- **AND** those layouts remain deterministic for the same seed and chunk coordinates

#### Scenario: Underground caves remain navigable after chunk reload
- **WHEN** a generated underground region is unloaded and later regenerated from the same seed and chunk coordinates
- **THEN** its cave topology and traversal-critical openings match the original generated state before player deltas are applied

### Requirement: Underground Cave Networks SHALL Preserve Player Reachability
The world generation system SHALL preserve practical underground reachability so cave diversity does not collapse into sealed pockets, excessive dead ends, or disconnected vertical progression.

#### Scenario: Underground descent remains traversable across chunk boundaries
- **WHEN** the game generates adjacent underground chunks for the same seed
- **THEN** cave openings, shafts, chambers, and connective passages align well enough that traversal routes are not routinely broken at chunk seams

#### Scenario: Encounter spaces are not dominated by sealed pockets
- **WHEN** the game generates underground and cavern regions intended for exploration or hostile spawning
- **THEN** most encounter-worthy cave spaces remain enterable and escapable by ordinary player traversal tools expected for that progression band
- **AND** intentionally sealed or special pockets, if any, are treated as explicit exceptions rather than the default cave outcome

### Requirement: Underground Generation SHALL Support Encounter-Aware Regions
The world generation system SHALL expose enough information for encounter systems to distinguish meaningful underground region types when spawning enemies or placing resources.

#### Scenario: Spawn systems can query underground region identity
- **WHEN** a hostile or content system evaluates an underground position
- **THEN** it can determine the biome/depth identity and whether the area belongs to a distinct underground region or cave archetype suitable for themed encounters
- **AND** it can distinguish whether that region is open, tunnel-like, chamber-like, pocket-like, or equivalently classified for encounter decisions

#### Scenario: Spawn systems can query underground reachability context
- **WHEN** a hostile spawn system evaluates a candidate cave position
- **THEN** it can determine whether the surrounding cave space is reachable, traversal-worthy, and suitable for regular encounter placement rather than a sealed or invalid pocket
