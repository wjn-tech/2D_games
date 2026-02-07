# Proposal: Implement Tabbed Settings Menu

## Goal
Create a comprehensive, tabbed settings interface inspired by Noita-like pixel art aesthetics, allowing players to configure General, Graphics, Audio, and Input preferences.

## Context
Currently, the `MainMenu` has a "Settings" button that does nothing. There is no central system for managing game configuration (resolution, volume, keybindings) or preserving these settings between sessions.

## Solution
We will implement a `SettingsManager` autoload to handle `ConfigFile` persistence and a `SettingsWindow` UI scene.
The UI will feature:
1.  **Tabbed Structure**: General, Graphics, Audio, Input.
2.  **Pixel Art Aesthetic**: Dark theme with gold/orange accents.
3.  **Key Rebinding**: A robust input mapping list.
4.  **Visual Settings**: Toggles for pixel-perfect scaling, particles, etc.

## Risks
*   **Input Mapping Complexity**: Handling input mapping for Keyboard vs Mouse vs Controller can be complex in Godot. We will start with standard `InputMap` integration.
*   **UI Scalability**: Ensuring the complex list of keys fits on smaller screens or scales correctly.

## Success Criteria
*   Clicking "Settings" in Main Menu opens the new window.
*   Settings (Volume, Fullscreen) are applied immediately and saved to disk.
*   Keybindings can be remapped and persist after restart.
