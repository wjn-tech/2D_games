# Proposal: Polish Settings Window Style

## Context
The user wants the `SettingsWindow` to match the "Arcane/Sci-Fi" aesthetic of the `MainMenu`. Currently, it uses a generic `glass_theme.tres`.

## Objectives
1.  **Visual Consistency**: Apply the Gold/Cyan color scheme and futuristic/arcane fonts.
2.  **Atmosphere**: Use a semi-transparent dark background (dimmer) instead of a solid color, allowing the Main Menu's nebula to bleed through (or provide its own if needed).
3.  **UI Elements**:
    *   Update the `MainContainer` to use a high-tech border/panel style (Gold borders, dark glass fill).
    *   Update Buttons to use `ui_button_hover.gd` for hover effects.
    *   Update Tabs to look like sci-fi toggles or navigation tabs.
4.  **Polish**: Add entrance animations (fade in + scale up).

## Implementation Plan

### 1. Update `SettingsWindow.tscn`
*   Change `theme` to `res://ui/theme/main_menu_theme.tres`.
*   Replace `BackgroundColor` (ColorRect) with a dark semi-transparent overlay (e.g., `Color(0, 0, 0, 0.7)`).
*   Update `MainContainer`'s `PanelContainer` style:
    *   Use a `StyleBoxFlat` with:
        *   `bg_color`: `Color(0.05, 0.05, 0.08, 0.95)` (Dark blue-black)
        *   `border_color`: `Color(0.4, 0.8, 1.0, 0.6)` (Cyan/Gold mix)
        *   `border_width`: 2px
        *   `corner_radius`: 8px
        *   `shadow`: Cyan glow
*   Add a header label "SETTINGS" with the Gold Gradient shader (similar to Main Menu title but smaller).

### 2. Update `settings_window.gd`
*   Add `_ready()` logic to attach `ui_button_hover.gd` effects to all buttons (Apply, Reset, Close).
*   Add `custom_minimum_size` to buttons to match the Main Menu style.
*   Implement an entrance animation in `_ready()`:
    *   Start with `modulate:a = 0` and `scale = 0.9`.
    *   Tween to `modulate:a = 1` and `scale = 1.0`.

### 3. Update Panels (General, Graphics, Audio, Input)
*   Ensure they inherit the theme.
*   Check if they need specific layout adjustments (e.g., larger fonts for headers).

## File Changes
1.  `scenes/ui/settings/SettingsWindow.tscn`
2.  `scenes/ui/settings/settings_window.gd`
