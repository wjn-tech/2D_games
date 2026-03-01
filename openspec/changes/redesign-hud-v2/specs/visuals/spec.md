# Spec: Visuals

## ADDED Requirements

#### Scenario: Unified Visual Theme
- **Given** the HUD is active
- **Then** all panel backgrounds must have a consistent dark, semi-transparent style (e.g., Color 0,0,0,0.7) with a border.
- **And** text must have a shadow or outline to ensure readability against bright game backgrounds.
- **And** pixel-art style fonts (if available) or clean sans-serif fonts should be used consistently.

#### Scenario: Status Bar Prominence
- **Given** the player has Health and Mana
- **Then** the Health bar must be the most visually distinct element (e.g., largest bar, distinct color Red/Green).
- **And** it must be positioned in the Top-Left corner (standard convention).
- **And** Mana/Stamina bars should be visually subordinate (smaller/thinner) below Health.

#### Scenario: Minimap Integration
- **Given** the Minimap is displayed
- **Then** it must use a **Square** border to align with the pixel-art aesthetic.
- **And** it must have a decorative border (programmatic StyleBox) that matches the UI theme.

## MODIFIED Requirements

#### Scenario: Attribute Display
- **Given** the player attributes (STR, INT, etc.)
- **Then** these should be displayed in a compact, organized format (e.g., a small grid or list) rather than a raw text string.
- **And** they should use icons or abbreviations to save space.

