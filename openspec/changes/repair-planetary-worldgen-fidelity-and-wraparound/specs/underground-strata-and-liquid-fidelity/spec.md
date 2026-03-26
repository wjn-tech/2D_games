## ADDED Requirements

### Requirement: Underground Strata SHALL Exhibit Distinct Layer Progression
The system SHALL produce visibly distinct underground strata with variable soil thickness and depth-driven transitions, rather than constant-thickness dirt bands tied directly to surface contour.

#### Scenario: Variable soil thickness across columns
- **GIVEN** a newly generated world
- **WHEN** sampling multiple surface columns across at least one full biome region
- **THEN** soil-to-stone transition depth varies by column within configured bounds
- **AND** transition variance is deterministic for the same seed.

### Requirement: Material Intermix SHALL Be Observable in Mid-Depth Bands
The system SHALL generate observable dirt-in-stone and stone-in-dirt patches in configured depth bands as a mapped terrain behavior, with bounded density to avoid full material inversion.

#### Scenario: Dirt appears in stone and stone appears in dirt
- **GIVEN** a generated underground chunk within configured intermix depth bands
- **WHEN** the chunk is inspected after terrain passes complete
- **THEN** both patch types are present (stone in dirt and dirt in stone)
- **AND** patch density remains within configured min/max thresholds.

### Requirement: Underground Liquids SHALL Be Present and Persistent
The system SHALL place underground liquids (at least water; lava when configured) in designated depth bands, and those liquids SHALL remain observable after settle/cleanup passes.

#### Scenario: Water pockets exist below surface layers
- **GIVEN** a generated world and enabled liquid passes
- **WHEN** traversing underground depth bands targeted for liquid generation
- **THEN** liquid pockets or channels are observable in multiple regions
- **AND** they are not entirely eliminated by cleanup passes.

#### Scenario: Spawn-safe traversal remains protected
- **GIVEN** spawn-safe constraints are active
- **WHEN** terrain and liquid passes complete near spawn
- **THEN** liquids do not fully block mandatory early traversal paths.