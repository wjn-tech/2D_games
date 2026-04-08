## ADDED Requirements

### Requirement: Boss Rooms SHALL Follow Tutorial-Style Compact Enclosed Composition
All four boss rooms SHALL follow tutorial-style compact enclosed composition baseline.

#### Scenario: Compact enclosed arena baseline exists
- **GIVEN** any boss room scene is loaded
- **WHEN** scene structure validation runs
- **THEN** scene contains enclosed arena collision boundaries (floor, ceiling, left wall, right wall)
- **AND** scene exposes required anchor nodes for player spawn and boss spawn

#### Scenario: Tutorial-style composition rhythm exists
- **GIVEN** any boss room scene is loaded
- **WHEN** visual baseline validation runs
- **THEN** scene includes explicit Background and Arena composition layers
- **AND** composition remains readable in a compact play area

#### Scenario: Compact arena size respects hard thresholds
- **GIVEN** any of the four boss room scene definitions
- **WHEN** arena bounds are measured by validation tools
- **THEN** total room width is less than or equal to 1400 units
- **AND** total room height is less than or equal to 700 units

### Requirement: Boss Rooms SHALL Remain Fully Isolated From Main World Streaming Dependencies
Boss room runtime SHALL not require main world chunk/streaming nodes.

#### Scenario: Encounter room runs without streaming world nodes
- **GIVEN** encounter scene is instantiated by encounter manager
- **WHEN** encounter lifecycle runs from intro to completion
- **THEN** encounter remains functional without world chunk streaming nodes
- **AND** room teardown does not require world streaming cleanup callbacks

### Requirement: Four Boss Rooms SHALL Share a Unified Structural Contract
Slime king, skeleton king, eye king, and mina rooms SHALL share the same structural contract for maintainability.

#### Scenario: Four-room contract consistency
- **GIVEN** all four boss room scene files
- **WHEN** structural contract check runs
- **THEN** each scene exposes the same required baseline nodes
- **AND** each scene passes the same isolation and intro-focus prerequisites
