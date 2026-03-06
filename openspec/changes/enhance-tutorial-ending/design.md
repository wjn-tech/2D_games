# Design: Tutorial Ending Sequence

This document outlines the technical approach for implementing the seamless tutorial crash sequence.

## Architecture

### 1. Tutorial Sequence Manager
The existing `TutorialSequenceManager` (in `scenes/tutorial/tutorial_sequence_manager.gd`) will be expanded to handle the new `CRASH_SEQUENCE` logic. Instead of spawning a `CinematicOverlay`, it will directly manipulate the game state:
-   **Ship Destruction:** It will iterate through `TutorialSpaceship` children (Sprites, TileMaps) and hide/queue_free them.
-   **VFX Spawning:** Specifically instantiates debris/explosion particles.
-   **Player Control:** Disables input but enables gravity/physics for the fall.

### 2. Main Scene Integration
The tutorial currently runs as an instance inside `Main.tscn`. This allows us to avoid scene reloading.
-   When `GameManager.is_new_game` is true, `Spaceship2` is visible at `(0, -50000)`.
-   When crash happens, `Spaceship2` visuals are hidden.
-   The player (RigidBody/CharacterBody) falls freely.
-   Since -50,000 units is a significant distance, we may need to:
    -   **Option A:** Let physics handle it (long fall time).
    -   **Option B (Preferred):** Teleport player closer to ground `(0, -2000)` and apply high downward velocity to simulate terminal velocity quickly. Or use `Time.time_scale` effects.
    -   We will likely teleport player for pacing reasons.

### 3. Visual FX
-   **Debris:** Simple Sprite2D/CPUParticles2D prefabs.
-   **Wind Lines:** A screen-space shader or attached Line2D trails.
-   **Mage Shield:** A customized `CPUParticles2D` emitting blue aura, attached to the player node.

### 4. Wake Up Logic
Instead of a separate cutscene, the "Wake Up" is handled by `TutorialSequenceManager` manipulating the `Player` node directly:
-   Set `rotation_degrees = -90`.
-   Wait for timer.
-   Tween `rotation_degrees` to `0`.
-   Enable input.
-   Verify ground collision (ensure player doesn't fall through world).

## Data Flow
`TutorialSequenceManager` -> `Crash State` -> `VFX Spawn` -> `Player Physics/Transform` -> `Fade/Wake Up` -> `End Tutorial`.

## Dependencies
-   `res://scenes/vfx/` assets (explosions, debris).
-   `Player` scene structure (assumes Sprite/AnimationPlayer availability).
-   `Main` scene layout (ground expected at y=0).
