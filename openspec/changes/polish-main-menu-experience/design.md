# Design: Polish Main Menu Experience

## Visual Style
-   **Theme**: Sci-Fi, Deep Space, Ethereal.
-   **Palette**:
    -   **Background**: Deep Space Blue (`#050814`) to void.
    -   **Primary Text**: White / Pale Cyan (`#E0F7FA`).
    -   **Accent (Active/Hover)**: Neon Cyan (`#00E5FF`) or Holo Blue.
    -   **Call to Action ("Start Game")**: Gold/Amber (`#FFD700`) or distinct bright accent to separate from other options.
    -   **Icons**: Tinted to match text or accent color (No pure black).

## Layout & Hierarchy
-   **Alignment**: Improve center alignment. Ensure icons in buttons are properly spaced and aligned with text.
-   **Spacing**: Increase vertical spacing between Title and Start Game button to create a clear "hero" area.
-   **Connection**: Use a subtle vertical line or particle stream to visually connect the Title to the menu options, grounding them.

## Atmosphere & VFX
-   **Nebula**: A large `TextureRect` or `ColorRect` with a shader behind the stars. It should have slow, undulating motion (noise texture scrolling).
-   **Particles**: Keep existing stars but ensure they have varying depth (parallax or scale variability).

## Motion Design
-   **Entrance (On Ready)**:
    -   Sequence:
        1.  Background fades in.
        2.  Title fades in and slides down slightly.
        3.  Menu buttons fade in and slide up, staggered by 0.1s.
-   **Hover**:
    -   Current scale effect is good (1.2x).
    -   Add: Brightness/Glow increase (Modulate > 1.0 or Shader).
    -   Add: Sound effect (optional, if SFX system exists).
