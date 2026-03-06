# Tasks: Enhance Intro Cutscene

## Phase 1: CinematicDirector Capabilities
- [ ] **Core Actions**: Implement `move_actor(target, destination, duration)`, `rotate_actor(target, angle, duration)`, and `scale_actor(target, scale, duration)` in `CinematicDirector.gd`.
- [ ] **Signal Action**: Implement `emit_signal(signal_name)` to trigger external events (like lights or scene scripts).
- [ ] **SFX Action**: Implement basic audio playback support if needed, or stick to `method` calls for now (prefer robust `play_sfx` if time permits).

## Phase 2: Scene Setup
- [ ] **Environment**: Create an "Alert" particle system (`scenes/vfx/alert_lights.tscn` or script in `TutorialSequenceManager`) to modulate environment color/light.
- [ ] **Player Visuals**: Ensure `Player` can be visually rotated/scaled without breaking physics (e.g., rotate `MinimalistEntity` or sprite, not the `CharacterBody2D`).

## Phase 3: Sequence Choreography (The "Start")
- [ ] **Update `start_intro`**:
    - [ ] Set `player.rotation` to `-90` (or similar) initially.
    - [ ] Position `CourtMage` far away.
    - [ ] Sequence:
        1.  **Terminal Glitch** (Existing).
        2.  **Explosion** -> Shake Screen.
        3.  **Brother Runs**: `move_actor(court_mage -> player)`.
        4.  **Interact**: `scale_actor(court_mage -> kneel)`, `rotate_actor(player -> 0)`.
        5.  **Dialogue**: Trigger `_start_dialogue_content`.

## Phase 4: Polish
- [ ] **Timings**: Adjust wait times for dramatic effect.
- [ ] **Camera**: Ensure smooth zoom/pan during the interaction.
- [ ] **Testing**: Verify "No Hanging" issue is resolved.
