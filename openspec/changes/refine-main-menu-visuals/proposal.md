# Refine Main Menu Visuals

## Summary
Overhaul the Main Menu UI to match the "Arcane" style aesthetic: minimalist, hierarchical, and immersive. This involves removing heavy container backgrounds, centering the layout, and using typography and subtle animations to create a premium feel.

## Motivation
The current Main Menu uses default Godot UI styling with heavy, dark panel backgrounds that feel "boxy" and dated. The desired "Arcane" style is cleaner, more modern, and better fits the high-quality aspiration of the game.

## Details
-   **De-boxing**: Remove `PanelContainer` background styles to leave text floating directly on the animated background.
-   **Hierarchy**: Differentiate the "Start Game" button (Primary) from "Continue", "Options", "Exit" (Secondary) using size, color, or opacity.
-   **Layout**: Center-align the menu items and increase spacing for a more cinematic look.
-   **Feedback**: Add subtle scaling or brightness shifts on hover (using Tweens or Shader logic) instead of simple color swaps.

## Risk
-   **Readability**: Removing backgrounds might reduce text contrast against the animated shader background. We may need a subtle gradient vignette or shadow behind the text specifically, rather than a box.
-   **Implementation**: Requires careful tweaking of `Theme` resources and `StyleBox` properties.
