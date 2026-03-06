# Design: Enhanced Cinematic (Brother Entrance)

## Introduction
This design outlines the detailed choreography for the "Enhanced Intro Cutscene." We will transform a static text sequence into an active, character-driven event using `CinematicDirector`.

## Scene Choreography

### 1. The Awakening (0s - 3s)
*   **Initial State**:
    *   **Player**: Lying down (Rotated -90 degrees, modulate alpha low for "fainting" effect or just prone sprite).
    *   **Brother (Court Mage)**: At "Control Console" (off-screen or far right).
    *   **Environment**: Ship interior, Alarm lights flashing Red.
*   **Action**: High Intensity Screen Shake + Fade In from Black.
    *   Use `CinematicOverlay` or `game_camera.shake(intensity)`.
    *   The "Terminal UI" glitches and fades out (already done).

### 2. The Rush (3s - 5s)
*   **Trigger**: Explosion sound (`SFX_BigBang`).
*   **Brother**: Runs from Console -> Player.
    *   Use `CinematicDirector.move_actor(court_mage, player.position + offset, duration=1.5)`.
    *   Play `Run` animation on Brother (if available) or simulate "frantic rush" via speed + shake.
*   **Camera**: Follows Brother (Pan from Console -> Player). A dynamic "follow shot."

### 3. The Help Up (5s - 7s)
*   **Brother**: Reaches Player. Kneels (simple scale Y tween: 1.0 -> 0.8 -> 1.0) or plays `Interact` animation.
*   **Player**: Stands up.
    *   Tween `rotation_degrees`: -90 -> 0.
    *   Tween `modulate:a`: 0.5 -> 1.0.
*   **Dialogue**: "By the Stars... you're finally awake!"
    *   Camera zooms in slightly (1.0 -> 1.2) for intimacy.

### 4. Handover (7s+)
*   **Action**: Brother hands over the Wand.
*   **Dialogue**: "Take this... it's our only chance."
*   **Transition**: UI unlocks, control returns to player.

## Technical Requirements (CinematicDirector)

### New Actions
To support this choreography, `CinematicDirector` needs expansion:

| Action | Parameters | Description |
| :--- | :--- | :--- |
| `move_actor` | `target: Node2D`, `destination: Vector2`, `duration: float` | Moves a node linearly to a point. |
| `rotate_actor` | `target: Node2D`, `angle: float`, `duration: float` | Rotates a node (for "lying down" -> "standing up"). |
| `scale_actor` | `target: Node2D`, `scale: Vector2`, `duration: float` | Scales a node (for "kneeling" or squash/stretch). |
| `set_property` | `target: Node2D`, `property: String`, `value: Any` | Generic property setter (e.g., visibility, modulation). |
| `play_sfx` | `stream: AudioStream` | Plays a one-shot sound effect. |

### Scene Refactoring
*   **TutorialSequenceManager**: `start_intro` needs to set up the actors' initial positions correctly (Player rotated, Brother far away) *before* the sequence starts.
*   **EnvironmentController**: Ensure it can trigger "Red Alert" lighting states on command.
