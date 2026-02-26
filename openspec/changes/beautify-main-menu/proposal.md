# Beautify Main Menu with Modern Effects

## Change Summary
Refactor the main menu experience to incorporate modern visual effects (glassmorphism panels, gradient text, floating particles) and consistent iconography, aligning with the `startmenu` example project's aesthetic.

## Feature Overview
- **Visuals:** Implement glassmorphism UI panels, glowing borders, and gradient text titles.
- **Effects:** Add floating rune particles, magic circles, and dynamic background enhancements.
- **Icons:** Integrate Lucide-style SVG icons for all menu buttons.
- **Scope:** Apply the new theme to Main Menu, Settings, Load Game, and other sub-menus.

## Motivation
The current menu (`MainMenu.tscn`) is functional but lacks the polished, magical atmosphere desired for the game's theme. The user specifically referenced a React/shadcn-based example with advanced visual effects that should be replicated in Godot.

## Proposed Changes
1.  **Theme Overhaul:** Create a new `glass_theme.tres` with custom `StyleBoxFlat` resources for blur/transparency.
2.  **Visual Components:**
    - `GradientLabel`: A custom component for text with gradient shaders or `TextureRect` masking.
    - `MagicParticleSystem`: A `GPUParticles2D` setup for floating runes/sparkles.
    - `GlassPanel`: A container with blur shader/texture.
3.  **Icon Integration:** Download and import a set of Lucide-style SVG icons (Sword, Scroll, Settings, etc.).
4.  **Menu Refactor:** Update `MainMenu.tscn` to use the new components while maintaining the center layout. Refactor sub-menus to match.

## Risk Assessment
- **Performance:** Excessive use of transparency/blur shaders may impact low-end devices. Will include quality settings.
- **Complexity:** Replicating CSS/Framer Motion effects in Godot requires custom shaders/tweens.
- **Compatibility:** Ensure new shaders work on target platforms (GLES3/Vulkan).

