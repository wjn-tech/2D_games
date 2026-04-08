## ADDED Requirements

### Requirement: Compact Storage Loader SHALL Resolve Chunks Through Deterministic Tiered Fallback
The system SHALL resolve chunk load requests through deterministic fallback tiers: compact artifact first, legacy artifact second, regeneration last.

#### Scenario: Compact artifact hit serves chunk data
- **WHEN** a chunk request has a valid compact artifact entry matching current world identity and schema
- **THEN** the loader materializes chunk cells from compact artifact payload
- **AND** fallback tiers are not executed for that chunk

#### Scenario: Compact miss falls back to legacy reader
- **WHEN** compact artifact lookup misses for a chunk
- **THEN** the loader attempts legacy precomputed artifact reader before regeneration
- **AND** if legacy reader succeeds, chunk materializes without running full regeneration pipeline

#### Scenario: Final fallback regenerates deterministically
- **WHEN** both compact and legacy artifact readers fail or are unavailable
- **THEN** the loader regenerates chunk content deterministically from seed and authoritative deltas
- **AND** gameplay state remains loadable without hard failure

### Requirement: Compact Artifact Decode SHALL Enforce Identity and Integrity Validation
The system SHALL validate compact artifact identity and payload integrity before decode and MUST reject invalid artifacts safely.

#### Scenario: Identity mismatch invalidates compact entry
- **WHEN** compact artifact identity differs from runtime world identity or schema version
- **THEN** loader rejects compact entry for that chunk
- **AND** loader continues with deterministic fallback sequence

#### Scenario: Corrupted payload is quarantined and skipped
- **WHEN** compact artifact decode fails integrity checks
- **THEN** artifact is marked invalid for current session and tagged for quarantine telemetry
- **AND** loader continues with fallback without crash

### Requirement: Loading Pipeline SHALL Preserve Bounded Runtime Behavior and Observability
The system SHALL execute compact loading within configured runtime budgets and MUST emit branch-level telemetry for operations and troubleshooting.

#### Scenario: Branch telemetry is emitted per chunk resolution
- **WHEN** a chunk load is resolved
- **THEN** telemetry records include selected branch (`compact`, `legacy`, or `regenerate`) and reason code
- **AND** records include at least chunk coordinate and elapsed load cost

#### Scenario: Startup preload budget remains bounded
- **WHEN** startup preload processes chunk loads through compact pipeline
- **THEN** per-frame/per-batch budget policies are enforced
- **AND** budget pressure does not bypass fallback correctness guarantees

### Requirement: Loader SHALL Use Canonical Coordinates Before Storage Lookup
The system SHALL canonicalize chunk coordinates according to topology rules before compact or legacy storage lookups.

#### Scenario: Wrapped topology lookup remains single-key consistent
- **WHEN** equivalent wrapped/display chunk coordinates reference the same logical chunk
- **THEN** loader resolves both requests to one canonical storage key
- **AND** duplicate logical chunk materialization does not occur