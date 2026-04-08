## ADDED Requirements

### Requirement: Strict Terrain-Correspondent Spawn Matching
The system SHALL spawn hostile families only when all required terrain dimensions for a rule are explicitly matched: map biome, depth band, cave region, and underworld region.

#### Scenario: Reject incomplete strict rule
- **WHEN** a hostile spawn rule omits any required terrain dimension
- **THEN** the loader marks the rule invalid and excludes it from runtime candidate selection

#### Scenario: Spawn only in exact terrain context
- **WHEN** runtime context differs from a rule in any required terrain dimension
- **THEN** that rule is not considered a valid spawn candidate

### Requirement: Terrain Coverage for Approved Taxonomy
The system SHALL provide native hostile coverage for every terrain class in the approved 31-class terrain taxonomy.

#### Scenario: Coverage validation report
- **WHEN** validation tooling runs on the spawn table
- **THEN** it outputs uncovered terrain classes and fails acceptance when any class has zero native hostile mapping

### Requirement: Minimum Candidate Diversity Per Terrain
The system SHALL provide at least two hostile candidate families for each approved terrain class.

#### Scenario: Detect single-family terrain
- **WHEN** validation tooling evaluates terrain-to-family mappings
- **THEN** any terrain class with fewer than two candidate families fails validation

### Requirement: Specialized Family Mapping for 15 Hostiles
The system SHALL map the approved 15 hostile families to terrain-consistent spawn habitats, with explicit rarity and density control values.

#### Scenario: Family rule completeness
- **WHEN** a hostile family is registered in the table
- **THEN** each family has explicit terrain mapping, spawn probability, active cap, and group range definitions

### Requirement: Rare Global Family with Terrain Hotspots
The system SHALL support a globally rare hostile family with explicit hotspot multipliers in designated terrains.

#### Scenario: Mimic cluster hotspot behavior
- **WHEN** the globally rare family is evaluated in hotspot terrains
- **THEN** effective spawn weight is increased according to configured hotspot multipliers while preserving global rarity baseline

#### Scenario: Mimic cluster baseline rate
- **WHEN** effective spawn probability is computed for the globally rare family
- **THEN** base effective probability is 0.12% per eligible spawn evaluation and hotspot terrains apply x2 multiplier

### Requirement: Underworld Region Participation
The system SHALL allow hostile spawning across all supported underworld regions where terrain rules are satisfied.

#### Scenario: Underworld region eligibility
- **WHEN** a valid hostile rule targets underworld habitats
- **THEN** route, floor, cliff, island, cavity, and hard_floor regions are all valid spawn contexts

### Requirement: Deterministic Overlap Resolution
The system SHALL resolve overlapping valid rules deterministically according to documented weighting and priority behavior.

#### Scenario: Mixed-terrain overlap
- **WHEN** multiple families are valid in a mixed terrain boundary context
- **THEN** candidate selection follows configured priority and weighted probability rules with deterministic reproducibility under identical seed and state
