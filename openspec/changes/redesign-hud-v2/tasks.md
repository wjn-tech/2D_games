# HUD Redesign V2 Tasks

## Preparation
- [x] Create/Update Theme resources (`HUDTheme.tres`) for unified fonts/colors.
- [x] Define color palette constants (HP Green, Mana Blue, Warning Red, etc.) in a shared UI config or Theme.

## Visual & Layout Refactor
- [x] **Background & Container**: Add styled panels with borders/backgrounds to separate UI from the game world.
    - [x] Create `HUDPanelContainer` style.
- [x] **Status Bar (Top Left)**: Move HP/Mana/Stamina to a prominent top-left position.
    - [x] Replace simple `AttributeDisplay` with dedicated `PlayerStatusWidget`.
    - [x] Add distinct progress bars for Health (Red/Green), Mana (Blue).
- [x] **Hotbar (Bottom Center)**: Style the hotbar.
    - [x] Add selection highlight (border/scale).
    - [x] Ensure slot icons are consistent or have proper placeholders.
- [x] **Mini-map & Game Info (Top Right)**: Group Time, Weather, and Map.
    - [x] Add border to Minimap.
    - [x] Format Time/Weather clearly below or beside map.
- [x] **Controls/Shortcuts (Bottom Right or Side)**:
    - [x] Style "H" and "I" buttons to look like keyboard keys or game icons.
    - [x] Add tooltips/visual feedback on press.

## Interaction & Animation
- [x] **Feedback**: Add `mouse_entered`/`mouse_exited` tweens for interactive elements (buttons, hotbar slots).
- [x] **Transitions**: Add simple `fade_in` / `slide_in` for panels when they appear (e.g., Quest log updates).
- [x] **Damage Feedback**: enhance `DamageOverlay` (flash red on hit).
- [x] **Button Response**: Visual click state for sidebar buttons.

## Hierarchy & Readability
- [x] **Stats Grouping**: Reorganize secondary stats (Age, Wealth, Attributes).
    - [x] Create a compact `CharacterStatsWidget`.
    - [x] Style it with a semi-transparent background to separate it from the game world.
    - [x] Ensure font size is smaller than HP/Mana but still legible (use outlines).
- [x] **Font & Text**: Enforce minimum font size and contrast shadows/outlines.

## Validation
- [x] Verify HUD scales correctly at different aspect ratios.
- [x] Verify all buttons are clickable and have feedback.
- [x] Verify HP updates visibly and instantly.
