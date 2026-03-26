## ADDED Requirements

### Requirement: Streaming Stage Telemetry Attribution
The runtime SHALL expose per-stage telemetry for world streaming so that frame hitches can be attributed to specific chunk operations.

#### Scenario: Chunk stage timing is recorded
- **WHEN** a chunk request is processed in runtime streaming
- **THEN** timing records include at least critical-load, enrichment, tile-apply, and entity-instantiation stages
- **AND** each record includes chunk coordinate and stage identifier

#### Scenario: Budget breach is attributable
- **WHEN** any streaming stage exceeds its configured frame budget
- **THEN** the system records a structured breach event with stage, elapsed time, and chunk coordinate
- **AND** the event is queryable in a deterministic validation run

### Requirement: Frame Budgeted Streaming Execution
The runtime SHALL enforce frame-budgeted execution for chunk streaming to reduce walking-time stutter.

#### Scenario: Work is deferred when budget is exhausted
- **WHEN** frame-budget allowance is consumed during streaming work
- **THEN** remaining non-critical work is deferred to subsequent frames
- **AND** critical collision-ready terrain generation remains prioritized over enrichment work

#### Scenario: Backpressure protects frame stability
- **WHEN** pending streaming queues grow beyond steady-state thresholds
- **THEN** backpressure rules throttle lower-priority work
- **AND** the system avoids starvation of critical chunk requests
