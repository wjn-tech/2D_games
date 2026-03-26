## ADDED Requirements

### Requirement: Project SHALL Introduce Runtime Liquid Simulation Compatible With Chunk Streaming
The project SHALL introduce a liquid simulation/runtime flow that is compatible with chunked world streaming, generation, and persistence boundaries.

#### Scenario: Phase-1 liquid set is bounded and explicit
- **WHEN** phase-1 implementation scope is applied
- **THEN** liquid simulation supports water and lava
- **AND** no additional liquid families are required for phase-1 completion

#### Scenario: Liquid update does not break chunk lifecycle
- **WHEN** chunks load, enrich, unload, and reload during gameplay
- **THEN** liquid state handling remains consistent with chunk lifecycle boundaries
- **AND** liquid processing does not require always-loaded global simulation state

#### Scenario: Liquid integration remains deterministic where required
- **WHEN** world generation and reload paths reconstruct a region with liquid-affecting stages
- **THEN** deterministic generation inputs remain deterministic
- **AND** runtime liquid evolution follows documented simulation rules

### Requirement: Liquid Integration SHALL Use Reference-Informed but Project-Compatible Design
Liquid system design SHALL be informed by the provided reference project architecture while being implemented in project-compatible form.

#### Scenario: Reference concepts are captured without direct dependency coupling
- **WHEN** liquid design decisions are documented for implementation
- **THEN** the design references relevant algorithmic concepts from `d:\godot\fluid-water-physics-2d-simulator-for-godot-4+`
- **AND** final module boundaries follow this project's world/chunk architecture

### Requirement: Liquid System SHALL Reserve Extension Interfaces for Future Liquid Families
The liquid integration SHALL expose extension points for future honey or special-liquid behaviors without requiring a full rewrite.

#### Scenario: Extension interface exists after phase-1
- **WHEN** phase-1 liquid integration is complete
- **THEN** extension interfaces for additional liquid families are present
- **AND** introducing a new liquid type does not require replacing core simulation loop contracts

### Requirement: Liquid Processing SHALL Respect Streaming Performance Budgets
Liquid updates SHALL be budget-aware so that entering ungenerated regions does not introduce major hitch regressions.

#### Scenario: Movement into new chunks stays budgeted
- **WHEN** the player traverses into ungenerated regions with active liquids
- **THEN** liquid-related work is budgeted or deferred
- **AND** critical traversal generation remains responsive

### Requirement: Bedrock Boundary SHALL Constrain Downward Liquid Propagation
Liquid behavior SHALL honor bedrock boundary rules in deep regions.

#### Scenario: Liquid cannot propagate downward through hard floor
- **WHEN** liquid simulation reaches bedrock hard floor zone
- **THEN** downward propagation is prevented by boundary rules
- **AND** valid liquid states above the floor remain allowed
