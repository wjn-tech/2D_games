## ADDED Requirements

### Requirement: Surface Biome Boundaries SHALL Use Domain-Warped Transitions
The system SHALL replace straight vertical biome cuts with domain-warped boundaries and a bounded blend corridor.

#### Scenario: Boundary contour is non-linear
- **GIVEN** two adjacent major surface biomes
- **WHEN** sampling the boundary across a vertical slice range
- **THEN** boundary X-offset varies non-linearly with depth and position
- **AND** the transition is not represented as a single straight column.

#### Scenario: Blend corridor width remains controlled
- **GIVEN** boundary blending is enabled
- **WHEN** examining multiple boundary segments across different seeds
- **THEN** transition width stays within configured min/max corridor bounds
- **AND** hard-cut transitions are rejected by validation.

### Requirement: Underground and Surface Boundary Phases SHALL Not Be Fully Locked
The system SHALL decorrelate underground boundary phase from surface boundary phase to avoid identical top/bottom split silhouettes.

#### Scenario: Deep boundary diverges from surface boundary
- **GIVEN** a biome boundary sampled from surface to cavern depth
- **WHEN** comparing boundary offsets by depth band
- **THEN** deep-layer offsets are measurably different from surface-layer offsets
- **AND** no full-depth straight seam persists through the entire sampled range.