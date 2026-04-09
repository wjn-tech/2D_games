## ADDED Requirements

### Requirement: Start Menu SHALL Use a Shell-Based Visual Structure
The system SHALL render the start menu using a shell-based structure with explicit Header, Body, and Footer regions.

#### Scenario: Enter start menu from boot scene
- **WHEN** the game opens the start menu
- **THEN** the menu shows a shell layout with a visible header region, main action region, and footer status region.

#### Scenario: Primary action emphasis
- **WHEN** the start menu is visible
- **THEN** the start-game action is visually emphasized over secondary actions (load/settings/exit).

### Requirement: Interaction Feedback MUST Be Clear and Consistent
The start menu MUST provide consistent visual feedback for hover, focus, press, and disabled states.

#### Scenario: Pointer hover over menu action
- **WHEN** the pointer hovers a menu action
- **THEN** the action shows a deterministic highlight effect within the defined motion budget.

#### Scenario: Keyboard/controller navigation
- **WHEN** focus moves between actions by non-pointer input
- **THEN** focused action remains visually distinguishable and actionable.

### Requirement: Menu Usability MUST Survive Visual Asset Failure
The start menu MUST remain usable when shell visual assets are missing or invalid.

#### Scenario: Missing shell asset
- **WHEN** shell visual assets are unavailable
- **THEN** the menu falls back to built-in styles and still allows start/load/settings/exit operations.

#### Scenario: Invalid shell token value
- **WHEN** a token value is malformed or out of allowed range
- **THEN** that token is replaced by a safe fallback without blocking menu rendering.