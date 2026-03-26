# Capability: Macro World Layout

## ADDED Requirements

### Requirement: Seeded World Plan
The system MUST derive a world-scale layout plan from the world seed before local chunk decoration is finalized.

#### Scenario: Rebuilding the same world plan
- **GIVEN** the same world seed and the same topology metadata
- **WHEN** a new session reconstructs the planetary world plan
- **THEN** the ordered sequence of major surface regions, transition arcs, and landmark reservations MUST be identical

### Requirement: Spawn-Safe Starting Region
Each planetary world MUST reserve a deterministic spawn-safe starting region inside the macro layout.

#### Scenario: Starting a new world
- **GIVEN** a newly created planetary world
- **WHEN** the player first spawns into the world
- **THEN** the spawn position MUST lie within a reserved starting region that is suitable for early traversal and basic resource access
- **AND** that starting region MUST NOT be placed directly on the world seam or inside a unique high-danger landmark zone

### Requirement: Reserved Landmark Placement
Major world landmarks and unique regional anchors MUST be reserved at the world-plan level instead of being decided only by chunk-local randomness.

#### Scenario: Generating a world with reserved landmark slots
- **GIVEN** a planetary world plan that includes reserved landmark arcs
- **WHEN** chunk generation reaches those arcs
- **THEN** the designated landmark family MUST appear in its reserved region
- **AND** the same unique landmark family MUST NOT be duplicated arbitrarily in unrelated arcs

#### Scenario: Preserving landmark spacing around the world
- **GIVEN** a planetary world plan with multiple landmark reservations
- **WHEN** the plan places unique or regional rare landmarks
- **THEN** landmark spacing MUST respect their configured minimum wrapped separation
- **AND** spawn-safe regions and transition arcs MUST be able to exclude incompatible landmark categories

### Requirement: Surface-To-Underground Regional Coupling
Macro surface regions MUST influence the underground region identity beneath them.

#### Scenario: Descending beneath a macro biome
- **GIVEN** a surface region tagged as a specific macro biome
- **WHEN** the player descends into the underground depth bands below that region
- **THEN** the underground biome variants, structure themes, and resource modifiers MUST reflect the overlying macro region
- **AND** transitions between neighboring macro regions MUST remain deterministic at chunk boundaries