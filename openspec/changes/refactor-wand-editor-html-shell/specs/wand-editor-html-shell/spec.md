# Spec: Wand Editor HTML Shell (Sample Style Transplant, Logic-Preserved)

## ADDED Requirements

### Requirement: Sample Art Style Full Transplant
The system SHALL transplant the sample project's art style into the embedded Wand Editor shell and restore the target visual effect to a near-equivalent level.

#### Scenario: Render target style characteristics
- **WHEN** the user opens Wand Editor in embedded shell mode
- **THEN** the shell SHALL present the sample style characteristics, including deep-space layered background, pixel-grid atmosphere, scanline/CRT texture, luminous panel borders, and pixel-style interactive feedback
- **AND** style transplantation SHALL not introduce new gameplay-facing behavior.

### Requirement: Existing Layout Ratio Preservation
The system SHALL preserve the existing project's layout ratio strategy while applying the transplanted sample theme.

#### Scenario: Keep proportion baseline
- **WHEN** the transplanted shell is rendered
- **THEN** the left library, center workspace, right detail panel, and top action bar SHALL follow the existing project ratio baseline
- **AND** theme migration SHALL not force a sample-project ratio override.

### Requirement: Logic-First Conflict Resolution
The system MUST preserve all existing wand programming logic, and any conflict between sample style implementation and existing logic MUST be resolved in favor of existing logic.

#### Scenario: Conflict between style behavior and current logic
- **WHEN** a style-level interaction pattern conflicts with current editor behavior
- **THEN** the runtime MUST keep current logic behavior unchanged
- **AND** the style implementation MUST adapt without altering logic semantics.

#### Scenario: Compile-save-test path unchanged
- **WHEN** the user triggers compile-related actions through the embedded shell
- **THEN** the engine SHALL execute the existing Godot compile/save/test pathways
- **AND** resulting wand data and simulation outcomes SHALL match native editor results.

### Requirement: Interaction and Copy Parity
The system SHALL keep interaction semantics and Chinese copy byte-for-byte consistent with the approved baseline.

#### Scenario: Interaction parity
- **WHEN** the user performs node editing interactions (drag, connect, zoom, pan, delete, escape cancel, mode switch)
- **THEN** each interaction SHALL produce baseline-equivalent results.

#### Scenario: Chinese copy parity
- **WHEN** the embedded shell is compared against the approved copy baseline
- **THEN** all Chinese UI strings SHALL remain byte-for-byte identical.

### Requirement: Embedded Bridge and Safe Fallback
The system SHALL keep Godot as the authoritative state source for embedded shell synchronization, and MUST fall back to native editor mode on unrecoverable embedding failures.

#### Scenario: Bidirectional sync with authority boundary
- **WHEN** shell-side edits occur
- **THEN** the shell SHALL emit structured intent messages to Godot
- **AND** Godot SHALL validate and apply them via existing handlers before publishing updated state.

#### Scenario: Fallback on embedding failure
- **WHEN** WebView initialization fails, shell resources are missing, or bridge errors become unrecoverable
- **THEN** Wand Editor MUST switch to native mode automatically
- **AND** wand editing state MUST remain recoverable.
