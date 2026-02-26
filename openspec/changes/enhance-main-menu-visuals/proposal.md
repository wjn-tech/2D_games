# Enhance Main Menu Visual Impact

## Summary
Significantly increase the visual weight and scale of the Main Menu buttons ("Start Game", etc.) to create a more "grand" and cinematic atmosphere. This includes larger typography, wider letter spacing, and more dramatic hover effects.

## Motivation
The user feedback indicates the current buttons feel "too small" and lack the necessary "grandeur" for a game titled "Star Ocean Journey" (星海之旅). The goal is to make the menu feel powerful and expansive.

## Details
-   **Scale**: Increase font sizes significantly (Title to ~120px, Start Button to ~48px, others to ~36px).
-   **Spacing**: Increase vertical separation between buttons to fill more screen space comfortably.
-   **Typography**: Enable uppercase (if font supports) or wide tracking/letter-spacing for a cinematic look.
-   **Visual Effects**:
    -   Add a subtle "glow" or "outline" shader to the active button.
    -   Implement a stronger "Scale Up" tween on hover (e.g., 1.2x with elastic bounce).
    -   Use HDR colors (values > 1.0) on hover to create a blooming glow effect without complex shaders.

## Risk
-   **Screen Real Estate**: Larger elements might crowd the screen on lower resolutions. We rely on the `menu_effects.gd` resolution handling to keep centering correct.
-   **Icon Quality**: Scaling up icons might reveal resolution issues if SVGs aren't re-rasterized correctly (but Godot handles SVGs well).
