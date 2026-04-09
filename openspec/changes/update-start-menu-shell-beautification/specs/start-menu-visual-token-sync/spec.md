## ADDED Requirements

### Requirement: Start Menu Visuals SHALL Be Driven by Shell Tokens
The system SHALL source start-menu visual parameters from shell token definitions under `assets/ui/start_menu_shell/`.

#### Scenario: Shell tokens available
- **WHEN** valid start-menu shell tokens are present
- **THEN** menu colors, spacing, typography, and motion timing are applied from those tokens.

#### Scenario: Token update iteration
- **WHEN** token values are changed between builds
- **THEN** start-menu visuals reflect the updated values without requiring gameplay logic changes.

### Requirement: Token Application MUST Have Deterministic Fallback
The system MUST apply deterministic fallback values for missing or invalid token entries.

#### Scenario: Missing token entry
- **WHEN** a required token key is absent
- **THEN** a predefined fallback value is used and menu rendering continues.

#### Scenario: Type mismatch token entry
- **WHEN** a token key exists with an incompatible type
- **THEN** that key is ignored and replaced by fallback while the rest of the token set remains active.

### Requirement: Shell Language Consistency SHALL Be Maintained Across Entry Flow
The system SHALL keep shell-language consistency between start menu and start-game loading overlay.

#### Scenario: Transition from start menu to loading overlay
- **WHEN** player starts a new game or loads a save from the start menu
- **THEN** the loading overlay preserves compatible shell-language cues (accent color family, border language, status tone).