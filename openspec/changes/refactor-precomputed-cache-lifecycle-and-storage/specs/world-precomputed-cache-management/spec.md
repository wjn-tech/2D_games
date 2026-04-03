## ADDED Requirements

### Requirement: Precomputed Artifacts SHALL Be Disposable Cache, Not Authoritative Save State
The system SHALL classify precomputed world artifacts as disposable cache that MAY be safely deleted without losing durable gameplay progress.

#### Scenario: Cache purge preserves durable world state
- **WHEN** precomputed cache artifacts for a world are deleted
- **THEN** loading the same world reconstructs terrain deterministically from seed and authoritative deltas
- **AND** player edits, entities, and durable world mutations remain intact

#### Scenario: World abandonment allows cache disposal
- **WHEN** a world/session is abandoned or deleted by lifecycle policy
- **THEN** related precomputed cache ownership entries are eligible for cleanup
- **AND** no retained cache is required for save-slot integrity

### Requirement: Precomputed Cache Lifecycle SHALL Enforce Bounded Disk Usage
The system SHALL enforce configurable global and per-world disk budgets for precomputed cache and MUST evict entries deterministically when limits are exceeded.

#### Scenario: Global cap triggers deterministic eviction
- **WHEN** total precomputed cache bytes exceed configured global budget
- **THEN** the system evicts cache entries according to documented eviction order (LRU + stale-world priority)
- **AND** emits structured telemetry containing reclaimed bytes and eviction reason

#### Scenario: Per-world cap prevents single-world domination
- **WHEN** one world cache exceeds per-world budget
- **THEN** that world cache is trimmed before unrelated worlds are evicted
- **AND** post-eviction usage for that world is within configured cap

### Requirement: Cache Identity SHALL Include Schema Versioning and Invalidation Rules
Cache identity SHALL include topology identity, generator schema version, and cache storage schema version, and MUST invalidate incompatible artifacts.

#### Scenario: Schema mismatch invalidates cache reuse
- **WHEN** cached artifact schema version differs from runtime schema version
- **THEN** cache reuse is rejected for mismatched artifacts
- **AND** mismatched artifacts are marked for eviction or migration

#### Scenario: Identity mismatch starts fresh cache context
- **WHEN** seed/topology identity does not match cache identity
- **THEN** preload runs with a fresh cache context
- **AND** prior identity artifacts are not treated as valid hits for the current world