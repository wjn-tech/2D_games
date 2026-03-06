# Solution Architecture: Tutorial Overlay & Guidance

This design expands the previous `TutorialOverlay` into a comprehensive system (`OverlayManager`) capable of rendering all interaction cues.

## Components
1.  **OverlayManager (CanvasLayer)**
    -   Holds references to special UI scenes (`InputPrompt`, `GhostCursor`, `HighlightMask`).
    -   Tracks active tutorial state (e.g., `Phase 1: Movement`).
    -   Handles "Completion Callbacks" from the `TutorialSequenceManager`.

2.  **Input Prompt System** (`InputPrompt.tscn`)
    -   Displays a key/mouse icon (W, A, S, D, I, K, MouseLeft).
    -   **Animation**: Presses down when the user presses the physical key.
    -   **Fade Logic**: Fades out after successful usage (e.g., if the task is "Move Forward", pressing 'W' triggers fade).

3.  **Ghost Interaction System** (`GhostCursor.tscn`)
    -   **Drag**: Animates a cursor picking up an item (icon) from `SourceRect` and dropping it at `TargetRect`.
    -   **Click**: Animates a cursor moving to `TargetRect` and clicking (visual ripple).
    -   **Loop**: Repeats every 2 seconds until the user interacts.

4.  **Highlight Mask** (`ColorRect` with Shader)
    -   Dims the screen (alpha 0.5 black).
    -   Punches "holes" (circles/rects) around specific `Control` nodes passed by the tutorial logic.
    -   Ensures focus is *only* on the relevant UI element (e.g., Hotbar Slot 1).

## Data Flow
-   **TutorialSequenceManager**: "Okay, now we need to move."
    -   Calls `OverlayManager.show_input_prompt(["W", "A", "S", "D"], "Move around")`.
-   **Player**: Presses 'W'.
-   **InputPrompt**: Detects input -> Animates press -> Fades out 'W'.
-   **TutorialSequenceManager**: Detects player position change -> Calls `OverlayManager.clear_prompts()` -> Advances step.

## Integration
-   **WandEditor**: As per previous proposal, exposes `get_grid_rect()`.
-   **InventoryUI**: Exposes `get_slot_rect(index)`.
-   **HotbarUI**: Exposes `get_slot_rect(index)`.

## Visual Style
-   **Color**: High-contrast Gold/Yellow for critical actions.
-   **Theme**: "Holographic / Augmented Reality" style to fit the "Ship AI / HUD" narrative.
