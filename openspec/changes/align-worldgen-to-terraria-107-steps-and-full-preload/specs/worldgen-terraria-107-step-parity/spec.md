## ADDED Requirements

### Requirement: Terrain Generation SHALL Expose a Deterministic 107-Step Compatibility Catalog
The terrain generation system SHALL expose a deterministic catalog of 107 indexed Terraria-reference terrain steps, where each index is represented exactly once and mapped to project execution behavior.

#### Scenario: Catalog includes all indices without gaps
- **WHEN** compatibility catalog reporting is executed for a world seed
- **THEN** the catalog includes exactly 107 entries
- **AND** each entry has a unique `step_index`
- **AND** no index in the required range is missing

#### Scenario: Catalog is deterministic for the same world identity
- **WHEN** the catalog is generated multiple times for the same seed and topology metadata
- **THEN** entry ordering and per-step dispositions remain identical

### Requirement: Step Disposition SHALL Be Governed by Explicit Status and Skip Reason Rules
Each catalog entry SHALL declare a disposition status from `implemented`, `adapted`, or `skipped`; skipped entries SHALL include an allowed skip reason and compatibility note.

#### Scenario: Skipped steps contain required rationale fields
- **WHEN** any step entry has status `skipped`
- **THEN** the entry includes a `skip_reason`
- **AND** the `skip_reason` value is one of:
  - `NOT_TERRAIN_SCOPE`
  - `MISSING_PROJECT_SYSTEM`
  - `MISSING_ASSET_SET`
  - `ENGINE_OR_TOPOLOGY_CONSTRAINT`
- **AND** the entry includes a non-empty `compat_note`

#### Scenario: Non-skipped steps do not masquerade as skipped
- **WHEN** a step entry has status `implemented` or `adapted`
- **THEN** it provides execution mapping metadata
- **AND** it is counted as covered in alignment metrics

### Requirement: Alignment Reporting SHALL Quantify 107-Step Coverage
The system SHALL report 107-step alignment metrics separately from stage-family coverage.

#### Scenario: Alignment report includes disposition counts
- **WHEN** alignment metrics are queried
- **THEN** the report includes counts for `implemented`, `adapted`, and `skipped`
- **AND** the sum of these counts equals 107
- **AND** the report includes unresolved-entry count (must be zero for acceptance)

#### Scenario: Step-level report coexists with stage-family report
- **WHEN** both alignment reports are requested
- **THEN** stage-family metrics are still available
- **AND** 107-step metrics are available without replacing stage-family outputs
