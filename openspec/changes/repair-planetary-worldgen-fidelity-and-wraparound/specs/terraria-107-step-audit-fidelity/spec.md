## ADDED Requirements

### Requirement: 107-Step Mapping SHALL Include Behavior-Level Audit
The system SHALL audit mapped Terraria step compatibility at behavior level, not only step catalog bookkeeping.

#### Scenario: Step is marked implemented/adapted but has no terrain effect
- **GIVEN** a step is reported as implemented or adapted in the compatibility catalog
- **WHEN** behavior audit probes the linked execution hook
- **THEN** the step fails validation if no observable terrain/material/liquid outcome exists.

### Requirement: Intermix and Liquid Related Steps SHALL Be Explicitly Audited
The system SHALL provide explicit audit outputs for steps linked to material intermix and liquid placement/settle behavior.

#### Scenario: Intermix step audit output exists
- **GIVEN** world generation completes for a seed
- **WHEN** compatibility audit metrics are generated
- **THEN** audit output includes pass/fail evidence for dirt-in-stone and stone-in-dirt behavior.

#### Scenario: Liquid step audit output exists
- **GIVEN** world generation completes for a seed with liquid passes enabled
- **WHEN** compatibility audit metrics are generated
- **THEN** audit output includes pass/fail evidence for underground liquid presence after settle/cleanup.

### Requirement: Skip/Adapt Decisions SHALL Preserve Traceability
The system SHALL preserve traceability from each skipped/adapted step to an explicit reason and substitution note.

#### Scenario: Catalog trace for skipped step
- **GIVEN** at least one step is marked skipped
- **WHEN** reading compatibility catalog entries
- **THEN** each skipped entry includes an allowed skip reason and compatibility note
- **AND** validation fails when required trace fields are missing.