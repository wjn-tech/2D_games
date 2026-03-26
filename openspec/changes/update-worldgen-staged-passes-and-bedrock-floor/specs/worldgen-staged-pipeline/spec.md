## ADDED Requirements

### Requirement: World Generation SHALL Execute as Deterministic Staged Pass Families
The world generation system SHALL execute chunk generation through deterministic staged pass families with explicit order and deterministic pass inputs.

#### Scenario: Same seed and chunk reproduces the same pass outputs
- **WHEN** the same seed, topology metadata, and chunk coordinate are generated multiple times
- **THEN** staged pass family order remains identical
- **AND** the final tile outputs are deterministic

#### Scenario: Stage order is explicit and inspectable
- **WHEN** chunk generation is invoked in runtime streaming
- **THEN** the system applies pass families in a documented order
- **AND** each pass family has a bounded responsibility scope

### Requirement: Staged Pass Families SHALL Follow Terraria-Core Logical Grouping
The world generation staged pipeline SHALL map to Terraria-core logical groups (terrain foundation, cave carving, biome macro shaping, resource distribution, structures/micro-biomes, liquid settle and cleanup) with project-compatible adjustments.

#### Scenario: Core grouping coverage is present
- **WHEN** a new world is generated with this pipeline enabled
- **THEN** each Terraria-core logical group is represented by at least one staged pass family
- **AND** the ordering preserves upstream-to-downstream dependency flow

#### Scenario: Compatibility adjustments stay minimal and explicit
- **WHEN** project constraints require divergence from Terraria-core behavior
- **THEN** each divergence is documented as a compatibility adjustment
- **AND** the adjustment does not invalidate the core stage ordering model

### Requirement: Pass Conflict Resolution SHALL Follow Explicit Priority Rules
The world generation pipeline SHALL define explicit conflict resolution where later pass families override earlier pass families by default unless an explicit preservation rule applies.

#### Scenario: Later pass overrides earlier pass in overlap
- **WHEN** two pass families write to the same tile position and layer
- **THEN** the later pass family result is retained by default
- **AND** exceptions require explicit preservation rules

#### Scenario: Protected traversal zones remain preserved
- **WHEN** a protected traversal or spawn-safe rule applies
- **THEN** conflicting later pass writes do not break required traversability
- **AND** the preservation exceptions are explicitly declared in a whitelist

### Requirement: Critical Runtime Path SHALL Remain Minimal and Traversal-First
The runtime streaming pipeline SHALL restrict critical chunk work to traversal-essential staged outputs and defer non-essential pass families to enrichment.

#### Scenario: New chunk remains immediately traversable
- **WHEN** the player enters an ungenerated region
- **THEN** critical generation provides collision-ready traversable terrain
- **AND** non-essential decorative or enrichment families are deferred

#### Scenario: Enrichment completion does not regress chunk continuity
- **WHEN** deferred pass families are applied after critical load
- **THEN** chunk seams remain continuous
- **AND** previously traversable space remains valid unless explicitly redesigned by spec
