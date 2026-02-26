# Design: Arcane-Style Menu

## Visual Pillars
1.  **Openness**: No visible borders or background plates for the main menu list. The background art (shader) should breathe.
2.  **Typography-First**: Buttons are defined by their text, not their container. 
3.  **Hierarchy**: 
    -   **Primary Action (Start/Continue)**: Larger font, brighter color, perhaps a distinct icon.
    -   **Secondary Actions (Options/Exit)**: Smaller, slightly more transparent or muted color.
4.  **Micro-Interactions**: Hovering shouldn't just change color; it should feel "alive" (e.g., slight scale up, glow intensity increase, letter spacing expansion).

## Technical Implementation
### Theme & StyleBoxes
-   Create a specific `Theme` for the Main Menu (`res://ui/theme/main_menu_theme.tres`).
-   Inside this theme:
    -   `Button/styles/normal`: `StyleBoxEmpty` (or very subtle transparent texture).
    -   `Button/styles/hover`: `StyleBoxTexture` or `StyleBoxFlat` with a very subtle glow/underline, OR rely purely on script-based Tweening for visual feedback.
    -   `Label`: Use the custom font with a shadow/outline for contrast.

### Scene Structure (`MainMenu.tscn`)
-   Node Hierarchy:
    ```
    Control (Root)
      ColorRect (Shader Background)
      CenterContainer (Full/Half Screen)
        VBoxContainer (Menu Items)
           Label (Title - already has shader)
           Control (Spacer)
           Button (Start - "Primary" style)
           Button (Continue - "Secondary" style)
           Button (Options - "Secondary" style)
           Button (Exit - "Secondary" style)
    ```
-   **Alignment**: The `VBoxContainer` should be centered horizontally.

### Readability Solutions
To solve the risk of low contrast:
-   **Global Vignette**: Add a `TextureRect` with a radial gradient (transparent center, dark corners) over the background but behind the UI.
-   **Text Shadows**: Enforce strong shadows (offset 2px, black, 0.5 alpha) on all text items via the Theme.
