## ADDED Requirements

### Requirement: World Entry SHALL Use an Explicit Startup Loading Gate
The system SHALL route both new-game and load-game world entry through an explicit startup loading gate rather than treating scene reload completion as immediate gameplay readiness.

#### Scenario: Starting a finite or planetary world
- **WHEN** the player starts a new world whose topology or bootstrap path requires startup work after scene reload
- **THEN** the game enters a loading-gate phase before PLAYING becomes active
- **AND** gameplay access is withheld until a defined critical-ready checkpoint is satisfied

#### Scenario: Loading an existing world save
- **WHEN** the player loads a save that requires scene reload, world restore, and spawn recovery
- **THEN** the same startup loading gate is used instead of bypassing directly into active gameplay

### Requirement: Gameplay Activation SHALL Remain Blocked Until Critical Readiness
The system SHALL keep player entry blocked until critical startup providers confirm that the world is ready for safe gameplay handoff.

#### Scenario: Scene is reloaded but spawn area is not yet ready
- **WHEN** the gameplay scene has reloaded but the spawn area, critical terrain, or required restore steps are not yet confirmed ready
- **THEN** the player cannot move, interact, or meaningfully enter the world
- **AND** HUD or equivalent enter-world indicators remain gated until the handoff checkpoint is reached

### Requirement: Deferred Startup Work SHALL Not Prevent Safe Entry
The system SHALL distinguish critical-ready startup work from deferred startup work so nonessential enrichment does not extend blocked loading after a safe handoff point exists.

#### Scenario: Secondary enrichment is still pending
- **WHEN** critical-ready startup conditions are satisfied but secondary enrichment or nonessential post-start tasks remain
- **THEN** gameplay may begin without waiting for those deferred tasks to finish
- **AND** the deferred tasks continue under normal runtime budgeting rather than holding the loading gate open