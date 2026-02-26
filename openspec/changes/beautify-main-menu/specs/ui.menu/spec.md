# Beautify Main Menu Spec

## ADDED Requirements

### Requirement: Visual Theme
The main menu MUST adopt an "Arcane" glassmorphism theme with semi-transparent, blurred panels and gradient text.

#### Scenario: Visual Effects
- **Given** the user views the main menu,
- **When** the menu loads,
- **Then** the background panel SHOULD be semi-transparent with a blur effect.
- **And** the title text SHOULD display a vertical gradient (e.g. White -> Purple).
- **And** the background SHOULD include dynamic particles (sparkles, runes) and rotating magic circles.

#### Scenario: Button Animations
- **Given** the user hovers over a menu button,
- **Then** the button MUST animate scale (e.g. 1.1x) and increase glow intensity.

### Requirement: Iconography
The menu buttons MUST use open-source SVG line icons (e.g. Lucide style) for visual clarity.

#### Scenario: Icon Usage
- **Start Game** button SHOULD feature a Sword icon.
- **Load Game** button SHOULD feature a Scroll icon.
- **Settings** button SHOULD feature a Gear icon.
- **Exit** button SHOULD feature a Door/Log-out icon.
- All icons MUST be scalable SVG format.

### Requirement: Layout & Responsiveness
The menu layout MUST remain centered but adopt responsive container behavior.

#### Scenario: Positioning
- **Given** the screen resolution changes,
- **Then** the menu buttons (Start, Load, Settings, Exit) MUST remain vertically centered in the viewport.
- **And** the container width MUST adjust but maintain a minimum width (e.g. 300px).

### Requirement: Sub-Menu Consistency
All sub-menus (Settings, Load Game, etc.) MUST share the same visual theme as the main menu.

#### Scenario: Consistent Look
- **Given** the user opens the Settings or Load Game menu,
- **Then** the window MUST use the same glass panel style and gradient headers as the main menu.

### Requirement: Performance Settings
Expensive visual effects MUST be toggleable via settings.

#### Scenario: Low Quality Setting
- **Given** the "Menu Visual Quality" setting is set to Low,
- **Then** the blur shader and high particle count effects SHOULD be disabled or reduced.

