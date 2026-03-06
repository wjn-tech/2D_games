# Tasks: Hybrid Cinematic Implementation

## Phase 1: Core Systems
- [x] **CinematicDirector**: Create `src/systems/cinematic_director.gd` (Singleton).
    - [x] Implement `play_sequence(actions)` queue processor.
    - [x] Implement basic actions: `wait`, `call_method`, `signal`.
- [x] **Camera Controller**: Enhance `MainCamera` with cutscene API.
    - [x] `pan_to(pos, duration)`, `zoom(scale, duration)`, `shake(strength)`.

## Phase 2: Terminal UI (Scheme C)
- [x] **Shader**: Create `assets/shaders/crt_effect.gdshader` (Scanlines, curvature, aberration).
- [x] **UI Scene**: Create `scenes/ui/terminal_overlay.tscn`.
    - [x] Add `ColorRect` with CRT material.
    - [x] Add `RichTextLabel` for console output.
    - [x] Script `terminal_overlay.gd`: `type_text(str)`, `glitch()`, `clear()`.

## Phase 3: In-Engine Tools (Scheme B)
- [x] **VFX**: Create simple `sparks.tscn` or `smoke.tscn` if needed (or reuse existing).
- [x] **Player Anim**: Ensure `Player` has a `wake_up` or `idle_lying` animation state (or simulate with sprite rotation for MVP).

## Phase 4: Integration
- [x] **Tutorial Update**: Modify `scenes/tutorial/tutorial_sequence_manager.gd` to use `CinematicDirector`.
- [x] **Sequence Scripting**: Define the `INTRO_SEQUENCE` constant array with the full text/camera choreography.
- [x] **Testing**: Verify flow from "Boot" -> "Glitch" -> "Game" -> "Input Unlock".
