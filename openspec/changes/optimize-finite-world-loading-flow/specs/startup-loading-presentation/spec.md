## ADDED Requirements

### Requirement: Loading Presentation SHALL Persist Across Scene Reloads
The startup loading presentation SHALL live in a persistent transition layer or equivalent path that remains valid across gameplay scene changes.

#### Scenario: Scene transition from menu into gameplay
- **WHEN** the player leaves MainMenu or SaveSelection and the gameplay scene is reloaded or replaced
- **THEN** the loading presentation remains visible throughout the transition
- **AND** it does not disappear simply because the outgoing scene was destroyed

### Requirement: Loading Presentation SHALL Show Animated Progress Feedback
The loading presentation SHALL provide an animated progress bar and stage-aware loading feedback while the startup gate is active.

#### Scenario: Startup loading is still in progress
- **WHEN** the world is still preparing critical startup work
- **THEN** the player sees an animated loading presentation with progress feedback that updates as startup stages advance
- **AND** the presentation remains visually active until the gameplay handoff is ready

### Requirement: Loading Presentation SHALL Preserve Safety on Failure
If startup cannot reach critical readiness, the loading presentation SHALL remain in control and keep gameplay blocked until the player chooses a safe recovery path.

#### Scenario: Startup provider fails or times out
- **WHEN** a startup stage cannot confirm readiness within the allowed recovery policy
- **THEN** the loading presentation switches to a failure-safe state instead of dismissing normally
- **AND** gameplay remains blocked until retry, return-to-menu, or another safe recovery action is chosen