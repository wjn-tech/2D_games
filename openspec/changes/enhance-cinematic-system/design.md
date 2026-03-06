# Design: Hybrid Cinematic System Architecture

## Overview
This design implements a `CinematicDirector` system responsible for seamless transitions between the **Terminal UI** (Scheme C) and the **Game World** (Scheme B).

## Proposed Components

### 1. `CinematicDirector.gd` (Singleton/Autoload)
The global coordinator for cutscenes.
*   **Action Queue**: `play_sequence(actions: Array)` managing sequential execution.
*   **State Management**: Locks player input, pauses/resumes physics if needed, manages Camera focus.
*   **Signal Dispatch**: Emits `step_completed` and `sequence_finished`.

### 2. `TerminalOverlay` (UI Scene)
A high-fidelity replacement for the generic `CinematicOverlay`.
*   **Visuals**: `ColorRect` + `CRTShader`, `TextureRect` (Vignette).
*   **Text**: `RetroLabel` with typewriter effect (blinking cursor, scrolling log).
*   **Effects**:
    *   `glitch()`: Momentary shader distortion.
    *   `set_scanline(intensity)`: Control CRT look.
    *   `boot_sequence()`: Pre-baked typing animation for "SYSTEM START...".

### 3. `InGameDirector` (Helper Logic)
A context-aware helper attached to the `MainCamera` or `GameManager`.
*   **Camera API**: `pan_to(target, duration, ease)`, `zoom_target(scale, duration)`, `shake(intensity, duration)`.
*   **World API**: `spawn_particle(vfx_scene, global_pos)`, `play_one_shot_anim(anim_player, anim_name)`.

## Sequence Flow: The "Crash Intro"

### Phase A: Terminal Boot
1.  **Director**: Calls `TerminalOverlay.show()`.
2.  **Terminal**: Typewriter text "SYSTEM INITIALIZING...".
3.  **Terminal**: Pause 0.5s.
4.  **Terminal**: Typewriter text "HULL INTEGRITY: 12% [CRITICAL]". Text color turns RED.
5.  **Audio**: Loop alarm klaxon.

### Phase B: The Glitch
1.  **Director**: Calls `TerminalOverlay.glitch(intensity=1.0, duration=0.8)`.
2.  **Director**: Simultaneously fades `TerminalOverlay.modulate.a` to 0.0.
3.  **World**: Reveal game world (already loaded).

### Phase C: World Reveal
1.  **Camera**: Currently zoomed at 2.0x on the burning Mana Drive (off-screen from player).
2.  **World**: Spawn `ExplosionVFX` at Mana Drive.
3.  **Camera**: Shake (High Intensity).
4.  **Camera**: Pan to Player (duration=2.0s, EaseOut).
5.  **Player**: Play animation `wake_up`.
6.  **Director**: Unlock Input. Intro Complete.

## Data Structure for Actions
The `CinematicDirector` will parse an array of Dictionary commands:
```gdscript
[
    {"type": "ui_text", "content": "SYSTEM FAILURE", "color": "red", "speed": 0.05},
    {"type": "ui_glitch", "duration": 0.5},
    {"type": "cam_pan", "target": Vector2(100, 200), "duration": 2.0},
    {"type": "world_vfx", "scene": "explosion.tscn", "pos": Vector2(50, 50)},
    {"type": "wait", "time": 1.0}
]
```
