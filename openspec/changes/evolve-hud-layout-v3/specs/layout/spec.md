## MODIFIED Requirements

### Requirement: Status Bar Configuration
The status bars for Health and Mana MUST be positioned in the top-left corner and styled with specific visual indicators.

#### Scenario: Status Bar Placement
- **Given** the HUD is active
- **Then** the Player Status Widget (HP/Mana) must be anchored to the **Top-Left** of the screen
- **And** it must include icon indicators using project assets (e.g., `icon_mana.svg`)

### Requirement: Hotbar Configuration
The hotbar MUST be a single row of item slots located at the bottom of the screen, serving as the primary inventory interaction point.

#### Scenario: Hotbar Single Row
- **Given** the Hotbar is visible
- **Then** it should display a single horizontal row of item slots
- **And** the currently selected slot should be visually distinct (highlighted border)
- **And** it should serve as the primary item interaction interface (Minecraft-style)
