# HUD Redesign V2 Proposal

## Summary
Refactor the HUD to address critical issues in visual compatibility, information hierarchy, and user interaction. The new design targets a unified "pixel-art compliant" aesthetic (or at least consistent theming), improved readability of vital stats (HP, Time), and better feedback for player actions.

## Background
The current HUD is functional but described as a "rough prototype." Key feedback points:
- **Visuals**: Flat styles clash with pixel art; inconsistent colors/icons.
- **Hierarchy**: Vital info (HP) is weak; "wall of text" for stats; cluttered layout.
- **Interaction**: No feedback on hotbar/buttons; static keys; missing animations.
- **Immersion**: UI feels like a separate layer rather than part of the game world.

## Goals
1.  **Visual Overhaul**: align UI style with game theme (pixel art / unified palette) using programmatic `StyleBox`.
2.  **Clear Hierarchy**: Prioritize HP/Mana/Time; group secondary stats (Age, Wealth, Attributes) neatly without hiding them.
3.  **Enhanced Interaction**: Add feedback (hover, click, selection) and animations.
4.  **Immersion**: mitigate "UI noise" with better backgrounds/transparency handling.

## Scope
- **Modified**: `HUD.tscn`, `hud.gd`
- **Modified**: Sub-components like `AttributeDisplay`, `WorldInfoUI`.
- **Added**: New assets/styles for HUD elements (simple programmatic styles or placeholders for now).
- **Excluded**: Deep refactoring of the underlying data systems (PlayerData, Inventory). We focus on *presentation*.

## Risks
- **Asset Dependency**: We may need new sprites/textures. We will use programmatic `StyleBoxFlat` or simple placeholders if assets are missing.
- **Performance**: Excessive animations/blur could impact low-end. Will act conservatively.
