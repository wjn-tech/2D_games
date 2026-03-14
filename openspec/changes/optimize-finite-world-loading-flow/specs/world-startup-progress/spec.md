## ADDED Requirements

### Requirement: Startup Progress SHALL Be Driven by Explicit Stage Reporting
The startup loading flow SHALL expose progress through explicit stages and provider-reported completion rather than relying only on fixed-duration animation or blind time-based interpolation.

#### Scenario: World startup contains multiple readiness steps
- **WHEN** scene stabilization, topology restore, world bootstrap, save restore, and gameplay handoff occur during startup
- **THEN** the loading progress model reflects those stages through explicit reporting
- **AND** no stage is marked complete until its defined completion condition is actually met

### Requirement: Startup Progress SHALL Cover Both New-Game and Load-Game Paths
The system SHALL use one progress model for both new-game and load-game entry so progress semantics do not diverge between the two startup paths.

#### Scenario: Comparing new game and save load entry
- **WHEN** the player starts a fresh world or loads an existing one
- **THEN** both entry paths report progress through the shared startup model
- **AND** path-specific work may contribute different stages or weights without changing the overall contract

### Requirement: Progress Completion SHALL Align with Gameplay Handoff
The progress model SHALL not present full completion until the startup gate is ready to release gameplay safely.

#### Scenario: Progress reaches full completion
- **WHEN** the loading progress reaches its completion point
- **THEN** the critical-ready checkpoint has already been satisfied
- **AND** the system may proceed directly into the final gameplay handoff without additional blocking startup stages still pending