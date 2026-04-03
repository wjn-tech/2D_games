## ADDED Requirements

### Requirement: Precomputed Payload Persistence SHALL Use Compact Compressed Storage Contract
The system SHALL persist precomputed payloads using compact compressed on-disk representation and MUST avoid unbounded high-overhead canonical formats for long-term cache storage.

#### Scenario: Precomputed write produces compact artifact format
- **WHEN** a precomputed chunk artifact is written
- **THEN** payload is encoded in the configured compact compressed format
- **AND** artifact metadata includes schema/version identifiers required for future compatibility checks

#### Scenario: Compact artifacts remain readable for startup preload
- **WHEN** startup preload consumes cached artifacts
- **THEN** cached payloads decode deterministically into runtime chunk cells
- **AND** decode failures fall back to regeneration without corrupting authoritative save state

### Requirement: Authoritative Save Footprint SHALL Exclude Mandatory Full-World Precompute Payloads
Authoritative save files SHALL persist only durable world state and deltas, and MUST NOT require full-world precompute payloads to preserve gameplay continuity.

#### Scenario: Save-load continuity without precomputed cache
- **WHEN** a save slot is loaded with empty precomputed cache
- **THEN** world state is reconstructed from seed + durable deltas
- **AND** gameplay continuity is preserved without requiring legacy precomputed artifacts

#### Scenario: Slot lifecycle cleanup does not leave unmanaged precompute growth
- **WHEN** save slots are removed or replaced
- **THEN** related cache ownership references are updated
- **AND** unmanaged precomputed growth is prevented by lifecycle governance

### Requirement: Storage Diagnostics SHALL Report Tiered Footprint and Eviction Outcomes
The system SHALL provide diagnostics for storage footprint by persistence tier and MUST include eviction outcomes for operational observability.

#### Scenario: Diagnostics expose tier breakdown
- **WHEN** storage diagnostics are requested
- **THEN** response includes at least authoritative-bytes, precompute-cache-bytes, and total-bytes
- **AND** includes per-world cache usage summaries

#### Scenario: Eviction telemetry is queryable
- **WHEN** eviction events occur
- **THEN** event records include world identity, bytes reclaimed, trigger condition, and policy branch
- **AND** recent eviction history is available for troubleshooting