## ADDED Requirements

### Requirement: Underground Generation SHALL Enforce Deterministic Regional Zoning
The world generation system SHALL classify underground space using deterministic zoning that combines depth progression and macro-region context, producing stable underground region identity for the same seed and coordinates.

#### Scenario: Same seed regenerates same underground zone identity
- **WHEN** the same seed regenerates the same underground chunk coordinates after unload or reload
- **THEN** underground zone identity remains stable
- **AND** cave archetype selection inputs derived from zone identity remain stable

#### Scenario: Different macro regions produce different underground zoning outcomes
- **WHEN** underground chunks are generated beneath different macro surface regions at similar depths
- **THEN** their underground zone identity differs in at least one structural dimension (archetype mix, openness profile, or connector bias)

### Requirement: Underground Generation SHALL Provide Budgeted Large-Cavern Opportunities
The world generation system SHALL provide explicit large-cavern opportunities at bounded frequency, rather than relying only on narrow-lane or small-pocket outcomes.

#### Scenario: Representative traversal windows include large-space outcomes
- **WHEN** representative seeds are sampled over configured underground traversal windows
- **THEN** each sampled window includes budgeted opportunities for large-cavern outcomes
- **AND** those outcomes are not replaced entirely by narrow tunnels or isolated micro-pockets

### Requirement: Underground Stratification SHALL Stay Moderately Expressive
The world generation system SHALL keep underground stratification readable with medium-strength transitions that avoid both flat homogeneity and abrupt visual discontinuity.

#### Scenario: Depth transitions are readable but not harsh
- **WHEN** players descend across adjacent depth bands in representative seeds
- **THEN** they observe clear regional transition cues in space structure and materials
- **AND** transitions remain smooth enough to avoid hard-cut band boundaries in normal traversal

### Requirement: Spawn-Safe Exploration SHALL Include Early Descent Access
The world generation system SHALL provide at least one beginner-friendly underground descent route within bounded spawn-safe exploration distance.

#### Scenario: Early-game route is discoverable near spawn
- **WHEN** a new world is generated and the player explores the configured spawn-safe travel window
- **THEN** at least one natural descent route is discoverable without deep manual shaft excavation
- **AND** the route remains consistent for the same seed/topology metadata

### Requirement: Underground Generation SHALL Preserve Long-Route Connectivity
The world generation system SHALL preserve at least one deterministic long-route connector family that links multiple exploration spaces without obvious single-wave monotony.

#### Scenario: Long-route traversal spans multiple cave spaces
- **WHEN** players follow generated connector routes in representative underground regions
- **THEN** they can traverse across multiple major cave spaces through continuous routes
- **AND** chunk seams do not routinely break that continuity

### Requirement: Underground Generation SHALL Expose Structured Metadata for Consumers
The world generation system SHALL expose deterministic underground metadata needed by gameplay and diagnostics.

#### Scenario: Consumer systems query underground metadata at a tile
- **WHEN** a system queries underground generation metadata at a world position
- **THEN** the response includes zone identity, cave archetype identity, depth-band identity, and reachability context
- **AND** the metadata is deterministic for the same seed and position

### Requirement: Underground Variety SHALL Be Regression-Validated
The project SHALL include validation checks that detect regressions toward homogeneous underground structure.

#### Scenario: Validation rejects homogeneous underground outputs
- **WHEN** deterministic validation runs on representative seeds
- **THEN** it fails if underground diversity metrics fall below configured thresholds for archetype variety, large-space occurrence, or route continuity
- **AND** it reports actionable diagnostics for the failing metrics.

### Requirement: Underground Upgrade SHALL Preserve Liquid System Contracts
Underground generation upgrades SHALL preserve existing liquid generation/simulation behavior contracts and must not introduce liquid regressions.

#### Scenario: Liquid behavior remains stable after underground changes
- **WHEN** underground-generation upgrades are enabled for new worlds/chunks
- **THEN** liquid seeding, runtime flow, and persistence contracts continue to satisfy existing liquid validation coverage
- **AND** no new liquid regression is introduced as a side effect of cave/zoning changes

### Requirement: New Underground Rules SHALL Apply Without Forced Legacy Rewrite
The underground-generation upgrade SHALL keep existing saves compatible and SHALL NOT require mandatory retroactive full-world rewrite.

#### Scenario: Existing save remains playable without migration rewrite
- **WHEN** an existing save created before this change is loaded
- **THEN** the save remains playable under prior generated terrain state
- **AND** upgraded underground rules apply to newly generated worlds/chunks without forcing old-world full backfill