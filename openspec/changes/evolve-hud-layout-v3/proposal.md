# Proposal: Modern RPG HUD Evolution (V3)

This proposal outlines the plan to evolve the game's Heads-Up Display (HUD) from the current functional V2 prototype to a polished "Modern RPG" style (V3), incorporating specific user feedback regarding layout and behavior.

## Problem Statement

The current HUD (V2) is functional but lacks the visual polish and specific behavioral traits desired for the final game experience. Key gaps include:
- **Visuals:** Pure programmatic styling lacks the depth and "embedded" feel of modern RPG interfaces.
- **Layout:** Elements are functional but need specific anchoring preferences (Top-Left Status).
- **Behavior:** The Attribute Panel currently clutters the screen and needs to be toggled on demand.
- **Interaction:** The Hotbar needs to function as a unified item/skill row (Minecraft-style).

## Proposed Solution

We will implement a V3 HUD with the following characteristics:

1.  **Refined Status Widget (Top-Left):**
    - Retain the Top-Left position.
    - Enhance visuals with thicker bars, clearer borders, and integrate existing icons (`icon_mana.svg`, etc.).
    - Add "Shake" or flash effects on damage/use for feedback.

2.  **Toggleable Attribute Panel:**
    - Move the `CharacterStatsWidget` to a hidden-by-default state.
    - Implement an input action (default `I` or `C`) to toggle its visibility.
    - Style it as a pop-up modal/overlay rather than a persistent HUD element.

3.  **Unified Hotbar (Minecraft-style):**
    - Consolidate item usage and slot selection into a single row.
    - Ensure visual selection indicators are prominent.
    - (Future) Support drag-and-drop or swap logic if not already present.

4.  **Asset Integration:**
    - Utilize discovered assets in `assets/ui/icons/` (e.g., `icon_mana.svg`, `lucide/sword.svg`).
    - Procedurally generate or use placeholders for missing icons (HP) until dedicated assets are added.

## Architecture & Implementation

- **`HUD.gd`:** Will manage the visibility state of the Attribute Panel via input events.
- **`PlayerStatusWidget`:** Updated `_draw` or `StyleBox` configuration to match "Modern" aesthetic (gradients, borders).
- **`HotbarWidget`:** Refine slot rendering to be more robust and visually distinct.

This change focuses on "Look and Feel" and "User Experience" rather than core backend logic changes.
