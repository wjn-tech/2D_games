## ADDED Requirements

### Requirement: World Generation SHALL Preserve Terraria-Core Step Logic Ordering
The world generation system SHALL preserve Terraria-core logic ordering at the level of core generation groups, while allowing explicit project-compatibility adjustments.

#### Scenario: Core order is respected in generation pipeline
- **WHEN** a new world generation run is executed
- **THEN** terrain foundation and cave shaping run before resource and structure enrichment groups
- **AND** liquid settle and cleanup groups run after major terrain/structure groups

#### Scenario: Compatibility-only deviations are documented
- **WHEN** a stage diverges from Terraria-core behavior due to project constraints
- **THEN** the deviation is documented as a compatibility adjustment
- **AND** the adjustment does not reorder unrelated core groups without explicit rationale

### Requirement: Terraria-Core Alignment SHALL Be Evaluated by Dual Metrics
The system SHALL evaluate terraria-core alignment using both core-stage coverage rate and step-item coverage rate.

#### Scenario: Dual coverage metrics are produced
- **WHEN** generation alignment validation is executed for the proposal scope
- **THEN** the report includes `core stage coverage rate`
- **AND** the report includes `step item coverage rate`

#### Scenario: Acceptance requires both metrics
- **WHEN** release readiness for this change is evaluated
- **THEN** both coverage metrics must meet defined acceptance thresholds

### Requirement: Stage Priority SHALL Follow Later-Override Rule by Default
Stage conflict resolution SHALL use later-stage override as the default rule, with explicit whitelist-based preservation exceptions.

#### Scenario: Overlap resolves to later stage output
- **WHEN** two stages write different outputs to the same tile and layer
- **THEN** the later stage output is retained by default

#### Scenario: Whitelisted preserve zones block unsafe overwrite
- **WHEN** a write targets a whitelist-preserved zone (for example spawn-safe or required traversal)
- **THEN** the preserve rule prevents destructive overwrite
- **AND** the exception remains deterministic

### Requirement: Existing Cave Entrance and Deep-Cavern Capability SHALL Be Integrated as Subordinate Scope
The terraria-core sequencing capability SHALL integrate existing cave entrance and deep-cavern improvements as subordinate scoped outputs.

#### Scenario: Prior cave enhancement remains active under new sequencing
- **WHEN** the sequencing pipeline executes for a cave-heavy region
- **THEN** natural entrances and deep-cavern archetypes remain present
- **AND** their execution order follows the new stage ordering and priority model
