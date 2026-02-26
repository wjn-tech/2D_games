# Design: Grand Menu System

## Visual Language
-   **Keywords**: Monolithic, Ethereal, Expansive.
-   **Typography**: 
    -   Title: Huge, perhaps with a slow "breathing" scale effect.
    -   Buttons: Should feel like "monuments" or "pillars". Wide stance.
-   **Palette**: 
    -   Normal: Muted silver/grey (Color(0.7, 0.7, 0.8)).
    -   Hover: Bright starlight white/cyan (Color(1.2, 1.2, 1.5)) - using HDR values for Glow.

## Implementation Details

### Scene Changes (`MainMenu.tscn`)
-   **VBoxContainer**: Increase `separation` from 32 to 48 or 64.
-   **Buttons**:
    -   Font Size: Start (48px), Others (36px).
    -   `theme_override_constants/icon_max_width`: Increase to match new font scale.

### Theme Updates (`main_menu_theme.tres`)
-   **Styles**:
    -   `Hover`: Use a `StyleBoxEmpty` (or very subtle transparent texture). The focus will be entirely on the text scaling and glowing.
    -   **Letter Spacing**: Use `extra_spacing_char = 4` to make text wider and more "cinematic".

### Script Updates (`ui_button_hover.gd`)
-   **Tweening**:
    -   Increase scale factor to `1.2`.
    -   Add `letter_spacing` tween if possible (Godot 4 allows tweening `theme_override_constants/extra_spacing_char`?). *Note: Tweening theme constants can be tricky. Scale is safer.*
    -   **Color Glow**: Use HDR colors (e.g., `Color(1.5, 1.5, 2.0)`) to make the text bloom/glow intensely without a shader.

### New Assets
-   **None**: We will achieve the effect with standard Godot Control properties and Tweens.

## Execution Plan
1.  **Scale Up**: Modify `MainMenu.tscn` font sizes and spacing first to get the "bone structure" right.
2.  **Theme Polish**: Update `main_menu_theme.tres` to add character spacing and refined colors.
3.  **Effect Tune**: Tweak `ui_button_hover.gd` for punchier animations.
