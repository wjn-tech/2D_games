# Design: Settings System & UI

## Architecture

### 1. `SettingsManager` (Autoload)
Responsible for holding current config state and I/O operations.

*   **Path**: `user://settings.cfg`
*   **Structure**:
    *   `[General]`: 
        *   `language`: String (en, zh, etc.)
        *   `pause_on_lost_focus`: Bool
        *   `show_damage_numbers`: Bool
        *   `camera_shake`: Float (0.0 - 1.0)
    *   `[Graphics]`: 
        *   `window_mode`: Int (Windowed, Fullscreen, Borderless)
        *   `resolution`: Vector2i (or index)
        *   `vsync`: Bool
        *   `max_fps`: Int (30, 60, 120, 144, 0=Uncapped)
        *   `particles_quality`: Float (0.5 - 2.0 multiplier)
        *   `brightness`: Float (0.5 - 1.5)
        *   `contrast`: Float (0.8 - 1.2)
        *   `gamma`: Float (0.8 - 1.2)
    *   `[Audio]`: 
        *   `master_vol`, `music_vol`, `sfx_vol`, `ui_vol`: Float (0.0 - 1.0)
    *   `[Input]`: 
        *   Dictionary of action_name -> InputEventKey (serialized)
*   **Signals**: `settings_changed(section, key, value)`
*   **Methods**:
    *   `save_settings()` / `load_settings()`
    *   `apply_all()`
    *   `reset_section_defaults(section)`

### 2. `SettingsWindow` (UI Scene)
A specialized `CanvasLayer` designed for functional density.

*   **Layout**: `VBoxContainer` centered on screen.
    *   **Header**: Tab Bar (Custom Buttons: General, Graphics, Audio, Input).
    *   **Body**: `PanelContainer` with Gold Border style.
    *   **Content**: dynamic loading of sub-scenes or visibility toggle of VBoxes.
    *   **Footer**: "Apply", "Back", "Reset Defaults" buttons.

### 3. Sub-Panels
*   **InputPanel**: 
    *   `ScrollContainer` listing all actions.
    *   Each row: [Action Name] | [Primary Key] | [Secondary Key].
    *   Feature: "Press Key" popup with conflict detection.
*   **GraphicsPanel**:
    *   Includes a "Preview" area or applies generic post-processing immediately for Brightness/Contrast.
*   **AudioPanel**:
    *   Sliders with numeric feedback label.

## Visual Style
*   **Reference**: "Noita" style.
*   **Palette**: Dark Indigo/Black background (`#151520`), Text (`#dadada`), Accent Gold (`#d4af37`).
*   **Typography**: Pixel font, crisp, no anti-aliasing on text.

## Integration
*   `MainMenu` and `PauseMenu` will invoke `UIManager.open_window("SettingsWindow")`.
*   `WorldEnvironment`: Listens to brightness/contrast settings to adjust `Environment` adjustments.
