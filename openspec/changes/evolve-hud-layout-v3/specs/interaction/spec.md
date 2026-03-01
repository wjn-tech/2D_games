## ADDED Requirements

### Requirement: Toggle Attribute Panel
The attribute panel (character sheet) MUST be toggleable by a specific key press, rather than being persistently visible or hidden.

#### Scenario: Toggling the Character Sheet
- **Given** the player is controlling the character
- **When** the player presses the `toggle_character_sheet` key (default "C")
- **Then** the Attribute/Stats panel should toggle its visibility (Open/Close)
- **And** the game usage should remain fluid (not a pause menu, unless specified otherwise)

### Requirement: Visual Feedback
The HUD MUST provide immediate visual feedback when status values change, such as health or mana, to alert the player.

#### Scenario: Visual Feedback on Stat Update
- **Given** the player takes damage
- **When** the health value decreases
- **Then** the health bar visual should update immediately
- **And** (Nice to have) a "shake" or flash effect should occur on the bar container
