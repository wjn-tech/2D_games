# Spec: Hierarchy

## MODIFIED Requirements

#### Scenario: Information Grouping
- **Given** the HUD layout
- **Then** elements must be grouped by function:
    - **Top-Left**: Combat Status (HP, Mana, Buffs).
    - **Top-Right**: World Info (Map, Time, Weather, Quest Tracker).
    - **Bottom-Center**: Action (Hotbar).
    - **Side/Bottom-Right**: System/Utility (Menus, Help).
- **And** "floater" elements (like loose labels) should be contained within these groups.

#### Scenario: Quest List placement
- **Given** the Quest List
- **Then** it should appear below the World Info (Top-Right), aligned to the right.
- **And** entries should have a background or text shadow for readability.

#### Scenario: Secondary Stats Presentation
- **Given** stats like "Wealth", "Age", or "Attributes"
- **Then** these must remain visible on the HUD (per user request).
- **But** they should be visually distinct (smaller/grouped) from combat stats to avoid clutter.

