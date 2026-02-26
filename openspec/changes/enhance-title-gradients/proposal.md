# Proposal: Enhance Title Gradients

## Context
Current titles in the game (Settings, Main Menu) use simple horizontal two-stop gradients (`gradient_simple.gdshader`) or plain text. The user wants to improve the visual style to match the attached Next.js project's (`startmenu`) more elaborate four-stop vertical gradients with drop shadows and animations.

## Goals
- Create a reusable `gradient_vertical.gdshader` that supports:
    - Vertical gradients (top-to-bottom UV.y)
    - Four color stops (custom uniforms) to match the subtle depth of the React project.
    - Optional drop shadow / glow.
- Update `MainMenu.tscn` to use this new shader for its title `"2D Sandbox World"`, using the blue/pink colors requested.
- (Optionally) Apply to `SettingsWindow.tscn` later if needed, but scope is currently Main Menu.

## Design Decisions
- Keeping the existing "Blue/Pink" color scheme but applying a more complex gradient structure (Start -> Mid1 -> Mid2 -> End) will add depth.
- Using a shader rather than `LabelSettings`'s gradient allows for animated effects (like shimmering or pulsing) similar to the React project.
- The new shader `assets/ui/shaders/gradient_advanced.gdshader` will replace `gradient_simple.gdshader` where appropriate.

## Changes
1.  Add `assets/ui/shaders/gradient_advanced.gdshader`.
2.  Create `assets/ui/materials/title_gradient_mainmenu.tres` (ShaderMaterial instance).
3.  Update `MainMenu.tscn` title label to use this new material.

## Questions
- Should the `SettingsWindow` also receive this update immediately? (User indicated "mainmenu only" but previously mentioned "Settings interface style"). I will clarify this in the PR phase or assume a follow-up task.
