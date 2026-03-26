## ADDED Requirements

### Requirement: World Generation SHALL Provide a Configurable Bedrock Floor Boundary
The world generation system SHALL define a configurable deep-world boundary using a bedrock transition band and a hard floor depth.

#### Scenario: Bedrock transition appears before hard floor
- **WHEN** terrain depth reaches the configured bedrock start depth
- **THEN** generated terrain transitions into a bedrock-dominant band
- **AND** cave-carving freedom is reduced according to boundary rules

#### Scenario: Hard floor blocks deeper carve propagation
- **WHEN** generation depth reaches or exceeds the configured hard floor depth
- **THEN** cave and structure carve passes cannot create deeper traversable voids below that boundary

### Requirement: Streaming SHALL Prevent Infinite Downward Chunk Expansion
The streaming system SHALL enforce lower-bound handling so that player movement cannot trigger unbounded downward chunk expansion.

#### Scenario: Requests below hard floor are bounded
- **WHEN** chunk requests target coordinates below the configured hard floor boundary
- **THEN** the system rejects those requests without enqueuing them into normal chunk load queues
- **AND** pending load queues do not grow unbounded from downward traversal

#### Scenario: Freefall boundary behavior remains safe
- **WHEN** the player reaches deep boundary regions during high-speed descent
- **THEN** the system still provides safe-ground or boundary-safe behavior without triggering endless deeper loading

### Requirement: Depth Boundary Rules SHALL Be Deterministic and Save-Compatible
Depth boundary behavior SHALL remain deterministic per seed/topology metadata and SHALL define a compatibility strategy for pre-existing saves.

#### Scenario: Deterministic boundary for same world metadata
- **WHEN** the same world seed and topology metadata are loaded
- **THEN** bedrock start depth and hard floor depth resolve identically
- **AND** boundary generation outcomes are reproducible

#### Scenario: Existing saves without boundary metadata remain playable
- **WHEN** an old save missing new depth-boundary fields is loaded
- **THEN** the system keeps legacy depth-boundary behavior for that save
- **AND** loading does not fail due to missing boundary fields

### Requirement: Bedrock Boundary Depth SHALL Be Preset-Driven
The system SHALL derive bedrock transition and hard-floor depths from world-size preset topology metadata.

#### Scenario: Preset controls boundary depths
- **WHEN** a new world is created with `small`, `medium`, or `large` size preset
- **THEN** `bedrock_start_depth` and `bedrock_hard_floor_depth` are resolved from that preset
- **AND** the resolved depths are deterministic for the resulting world metadata

### Requirement: Bedrock Zone SHALL Use Two-Phase Structure
The deep boundary SHALL consist of a bedrock transition band followed by a hard floor zone.

#### Scenario: Transition precedes hard floor
- **WHEN** generation enters deep boundary depths
- **THEN** tiles pass through a transition band before reaching hard floor constraints
- **AND** hard floor rules are stricter than transition band rules

### Requirement: Bedrock-Liquid Interaction SHALL Preserve Upward Containment
The boundary rules SHALL allow lava pools above the bedrock floor while preventing downward liquid propagation through the bedrock zone.

#### Scenario: Lava remains above floor
- **WHEN** lava is generated or settled near bedrock boundary
- **THEN** lava may remain in valid cavities above hard floor
- **AND** liquid propagation does not continue downward through bedrock floor constraints
