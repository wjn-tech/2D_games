## ADDED Requirements

### Requirement: Full-World Preload SHALL Execute in Deterministic Bounded Batches
Preload execution SHALL run in bounded deterministic batches with progress telemetry, rather than unbounded monolithic blocking work.

#### Scenario: Batch execution emits telemetry and progresses monotonically
- **WHEN** preload is running
- **THEN** telemetry records include batch index, processed chunk count, elapsed time, and remaining chunk count
- **AND** progress percentage is monotonically non-decreasing

#### Scenario: Batch policy remains deterministic for same seed/topology
- **WHEN** preload is rerun for the same seed and topology metadata
- **THEN** batch ordering over canonical chunk coordinates remains deterministic

### Requirement: Preload Sessions SHALL Support Checkpoint and Resume
The preload system SHALL persist checkpoint state so interrupted preload sessions can resume without restarting from zero.

#### Scenario: Resume continues from checkpoint
- **WHEN** preload is interrupted after partial completion
- **AND** startup is retried for the same world identity
- **THEN** preload resumes from persisted checkpoint
- **AND** already completed chunks are not regenerated unnecessarily

#### Scenario: Checkpoint invalidates on world identity mismatch
- **WHEN** seed or topology metadata differs from checkpoint identity
- **THEN** old checkpoint is not reused
- **AND** preload starts with a fresh checkpoint context

### Requirement: Post-Preload Exploration SHALL Avoid First-Time Generation Spikes In-Domain
After startup handoff from a completed preload, traversing in-domain chunks SHALL load precomputed data instead of triggering first-time generation pipelines.

#### Scenario: In-domain traversal uses precomputed chunk artifacts
- **WHEN** player enters any chunk within completed preload domain
- **THEN** chunk load path resolves from precomputed persisted data
- **AND** no first-time generation stage is required for that chunk

#### Scenario: Readiness verification surfaces violations
- **WHEN** runtime telemetry detects first-time generation for an in-domain chunk after preload completion
- **THEN** system records a readiness violation event tagged with chunk coordinate and cause
