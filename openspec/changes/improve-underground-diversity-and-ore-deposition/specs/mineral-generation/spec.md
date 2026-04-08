## ADDED Requirements

### Requirement: Mineral Generation SHALL Use Deposit-First Placement
The mineral generation system SHALL generate ore using connected cluster-first deposit placement, not predominantly independent per-cell threshold replacement.

#### Scenario: Ore appears as connected bodies in representative samples
- **WHEN** representative underground chunks are generated for deterministic seeds
- **THEN** most ore placements belong to connected components larger than single isolated cells
- **AND** deposit-family identity is available for diagnostics

#### Scenario: Cluster-first morphology is the dominant ore shape
- **WHEN** representative ore distributions are inspected across supported depth bands
- **THEN** compact cluster-like connected bodies are the dominant visible ore morphology
- **AND** isolated single-cell speckles do not dominate perceived distribution

### Requirement: Mineral Generation SHALL Preserve Depth and Zone Affinity
The mineral generation system SHALL preserve mineral rarity and type affinity by depth and underground zone.

#### Scenario: Shallow and deep layers show different mineral expectations
- **WHEN** ore distributions are sampled across shallow, mid, and deep depth bands
- **THEN** each band exhibits the configured mineral family bias and rarity profile
- **AND** deep-only minerals do not dominate shallow bands

#### Scenario: Zone affinity modulates deposit families
- **WHEN** ore is generated in underground zones with different structural identities
- **THEN** cluster morphology parameters (size envelope, local compactness, and branch tendency) vary according to zone affinity
- **AND** variation remains deterministic for the same seed and coordinates

### Requirement: Mineral Generation SHALL Remain Seam-Continuous and Deterministic
The mineral generation system SHALL keep ore body continuity and determinism across chunk boundaries and reloads.

#### Scenario: Ore deposit crossing chunk seam stays coherent
- **WHEN** a deposit intersects a chunk boundary and adjacent chunks are generated independently
- **THEN** deposit geometry remains continuous across the seam
- **AND** reload/regeneration recreates the same deposit outcome for unchanged world state

### Requirement: Mineral Coherence SHALL Be Regression-Validated
The project SHALL include ore-quality validation checks that detect regression toward salt-and-pepper scatter.

#### Scenario: Validation rejects overly scattered ore patterns
- **WHEN** deterministic ore-distribution validation runs on representative seeds
- **THEN** it fails if connected-component, spacing, or seam-continuity metrics indicate predominantly scattered ore dots
- **AND** it reports which thresholds failed for triage.

### Requirement: New Deposit Rules SHALL Apply Without Forced Legacy Rewrite
Deposit-model upgrades SHALL keep existing saves compatible and SHALL NOT require mandatory retroactive full-world ore rewrite.

#### Scenario: Existing save remains compatible under deposit upgrade
- **WHEN** an existing save created before this change is loaded
- **THEN** it remains playable without forced ore backfill migration
- **AND** upgraded deposit rules apply to newly generated worlds/chunks only