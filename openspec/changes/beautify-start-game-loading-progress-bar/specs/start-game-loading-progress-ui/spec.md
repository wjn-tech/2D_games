## ADDED Requirements

### Requirement: Start Game Loading Overlay SHALL Be Visually Enhanced
The system SHALL present a beautified loading overlay for start-game and load-game transitions while keeping existing loading semantics unchanged.

#### Scenario: Start new game transition
- **WHEN** the player triggers a new game from the start menu
- **THEN** a themed loading overlay is shown with title, stage text, status text, and a visible progress bar.

#### Scenario: Load save transition
- **WHEN** the player triggers loading an existing save
- **THEN** the same themed loading overlay is used with consistent layout and visual style.

### Requirement: Progress Display MUST Remain Monotonic and Readable
The loading progress display MUST stay monotonic and readable during startup stage updates.

#### Scenario: Stage updates across startup pipeline
- **WHEN** startup progress updates are emitted from multiple stages
- **THEN** displayed percentage does not move backward and text remains legible.

### Requirement: Failure State SHALL Be Explicit and Recoverable
The loading UI SHALL provide explicit failure feedback and keep recovery messaging visible.

#### Scenario: Startup failure path
- **WHEN** startup fails and failure handler is invoked
- **THEN** the overlay shows a high-contrast error state and displays a return-to-menu hint.

### Requirement: Shell Asset Integration MUST Support Fallback
The loading UI MUST support shell-asset integration from `assets/ui/start_menu_shell/` with deterministic fallback when assets are unavailable.

#### Scenario: Shell assets available
- **WHEN** required shell visual assets are present
- **THEN** the loading overlay applies those assets to the progress bar theme.

#### Scenario: Shell assets missing
- **WHEN** shell assets are missing or invalid
- **THEN** the loading overlay falls back to built-in Godot styles without blocking startup flow.
