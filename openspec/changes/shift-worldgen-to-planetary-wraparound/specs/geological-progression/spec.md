# Capability: Geological Progression

## ADDED Requirements

### Requirement: Ordered Depth Bands
Planetary worlds MUST provide ordered depth bands with distinct generation rules instead of relying on unbounded downward extension.

#### Scenario: Descending through the world interior
- **GIVEN** a planetary world with defined depth bands
- **WHEN** the player keeps descending from the surface
- **THEN** the world MUST transition through the configured underground bands in order
- **AND** the deepest progression region MUST be a designed terminal band or boundary rather than endless repeated extension

#### Scenario: World plan modifies local depth expression
- **GIVEN** two locations in different macro regions but at the same depth band
- **WHEN** the world generator resolves local underground content
- **THEN** both locations MUST obey the same global depth ordering
- **AND** each location MAY apply different cave style, material palette, hazards, or structure themes according to its macro region

### Requirement: Bounded Vertical Connectors
Vertical cave connectors MUST be constrained to intended depth transitions and traversal safety rules.

#### Scenario: Following a major vertical shaft
- **GIVEN** a generated shaft or connector that links underground regions
- **WHEN** the player falls or travels through that connector
- **THEN** the connector MUST terminate within intended adjacent depth bands or landing intervals
- **AND** generation MUST NOT create infinitely continuing freefall corridors as a normal outcome

### Requirement: Stratified Resources And Hazards
Resource placement and underground hazards MUST vary by both depth band and macro world region.

#### Scenario: Comparing ore and hazard distribution across regions
- **GIVEN** two underground areas at different depth bands or under different macro regions
- **WHEN** generation determines ore, hazards, liquids, or special material strata
- **THEN** the resulting composition MUST reflect both the local depth band and the world-plan region identity
- **AND** rare materials or danger zones MUST follow deterministic placement rules for the world seed

### Requirement: Terminal Depth Boundary
The deepest progression region of a planetary world MUST resolve to a deliberate terminal state rather than silently continuing the same generation rules forever.

#### Scenario: Reaching the deepest intended band
- **GIVEN** a player reaches the deepest intended progression region of a planetary world
- **WHEN** new chunks generate below or at the boundary of that region
- **THEN** generation MUST follow the configured terminal-band rules or explicit boundary behavior
- **AND** it MUST NOT degrade into accidental infinite extension of ordinary cave generation