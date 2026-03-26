## ADDED Requirements

### Requirement: Planetary Startup SHALL Gate Gameplay on Full-World Preload Completion
For finite planetary worlds, the startup pipeline SHALL complete full-world preload before entering gameplay state.

#### Scenario: Gameplay handoff is blocked until preload completes
- **WHEN** a new planetary world startup begins
- **THEN** game state remains in loading flow while preload is incomplete
- **AND** player input remains disabled during preload
- **AND** transition to gameplay occurs only after preload completion status is true

#### Scenario: Legacy topology keeps compatibility fallback
- **WHEN** startup runs in legacy/infinite topology mode
- **THEN** system is allowed to use spawn-area warmup fallback
- **AND** full-world preload gate is not mandatory

### Requirement: Full-World Preload SHALL Have Explicit Domain Coverage Rules
The preload process SHALL define deterministic domain boundaries so completion can be verified objectively.

#### Scenario: Completion requires all mandatory chunks in preload domain
- **WHEN** preload completion is evaluated
- **THEN** all chunks in configured preload domain are marked generated-and-persisted
- **AND** completion is rejected if any mandatory chunk is missing

#### Scenario: Domain rules remain deterministic per topology metadata
- **WHEN** identical seed and topology metadata are used
- **THEN** preload domain boundaries resolve to the same chunk set

### Requirement: Startup Failure Handling SHALL Be Structured for Preload Gate Failures
If preload cannot complete, startup SHALL fail safely with structured diagnostics and no partial gameplay handoff.

#### Scenario: Preload timeout aborts startup safely
- **WHEN** preload exceeds configured timeout or encounters unrecoverable failure
- **THEN** startup is aborted back to menu-safe state
- **AND** gameplay state is not entered
- **AND** failure diagnostics include at least reason code and progress snapshot
