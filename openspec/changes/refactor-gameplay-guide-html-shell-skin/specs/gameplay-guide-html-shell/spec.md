## ADDED Requirements

### Requirement: Gameplay Guide HTML Shell Scope
The system SHALL apply embedded HTML shell rendering to Gameplay Guide window only for this change.

#### Scenario: Open gameplay guide with shell available
- **WHEN** the player opens the gameplay guide and the shell runtime is available
- **THEN** the system SHALL render the gameplay guide with the embedded HTML shell
- **AND** this change SHALL NOT migrate unrelated windows.

#### Scenario: Scope guard for non-target windows
- **WHEN** the player opens non-guide windows
- **THEN** those windows SHALL continue using their existing implementation in this change.

### Requirement: Strict Logic and Content Parity
The system MUST preserve all existing gameplay guide logic and content behavior exactly as currently implemented.

#### Scenario: Catalog and page behavior parity
- **WHEN** the user selects catalog entries or uses previous/next page controls
- **THEN** page index transitions, indicator updates, and navigation boundaries SHALL match the native baseline behavior.

#### Scenario: Content source remains unchanged
- **WHEN** guide pages are rendered in the HTML shell
- **THEN** page title, path, and content SHALL come from the existing Godot-side guide content pipeline
- **AND** no alternate guide data source SHALL replace the canonical pipeline in this change.

#### Scenario: Spell compendium behavior parity
- **WHEN** spell compendium entries are displayed
- **THEN** spell listing, display-name resolution, and summary rendering SHALL match current gameplay guide behavior.

### Requirement: Handbook Style Transplant Without Semantic Drift
The system SHALL transplant the guide HandbookWindow visual style into the gameplay guide shell without changing guide semantics.

#### Scenario: Preserve visual theme baseline
- **WHEN** the gameplay guide shell is displayed
- **THEN** the shell SHALL present the pixel sci-fi visual language aligned with the reference HandbookWindow style baseline
- **AND** style adaptation SHALL NOT introduce semantic behavior changes.

#### Scenario: Preserve information architecture
- **WHEN** style transplant is applied
- **THEN** existing guide information architecture (catalog hierarchy and page-reading flow) SHALL remain unchanged.

### Requirement: WebView-first Runtime with Mandatory Native Fallback
The system SHALL prefer WebView shell runtime and MUST fallback to native gameplay guide rendering on unrecoverable shell failures.

#### Scenario: Initialization failure fallback
- **WHEN** WebView class initialization fails or shell resources are missing
- **THEN** the system MUST log diagnostics and switch to native gameplay guide rendering automatically.

#### Scenario: Runtime bridge failure fallback
- **WHEN** bridge communication becomes invalid while the guide window is open
- **THEN** the system MUST exit shell mode safely and continue in native gameplay guide mode
- **AND** guide usability MUST remain intact.

### Requirement: Desktop Acceptance Gate
The system SHALL enforce desktop runtime acceptance for this change, while allowing non-blocking degraded behavior on mobile targets.

#### Scenario: Desktop verification required
- **WHEN** the change is validated for release
- **THEN** desktop behavior parity and shell fallback scenarios SHALL pass required checks.

#### Scenario: Mobile degradation allowed
- **WHEN** the game runs on mobile targets without equivalent shell capability
- **THEN** the implementation MAY degrade to native guide rendering without blocking this change.
