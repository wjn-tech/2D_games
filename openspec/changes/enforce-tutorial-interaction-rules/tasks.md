# Tasks

1.  **Scene 1 & 2: Narrative & Assets**
    - [ ] Create `ActionRequirement` inner class in `TutorialSequenceManager`.
    - [ ] Create `CinematicOverlay.tscn` (CanvasLayer, TextureRect, Label).
    - [ ] Add function `_play_intro_cinematic()` to TSM using `CinematicOverlay`.
    - [ ] Update `dialogue_lines` with new tags (`<emit:objective:...>`).

2.  **Scene 3: Objective & Validation**
    - [ ] Create `ObjectiveTracker.tscn` (VBox, Label, TextureRect checkmark).
    - [ ] Add `ObjectiveTracker` instance to `HUD` scene.
    - [ ] Implement `EventBus` signals: `objective_updated(text)`, `objective_completed`.
    - [ ] Refactor `_check_step` in TSM to update `ObjectiveTracker`.
        - [ ] Case: `WAND_REPAIR` -> Updates text based on `wand.has_node`.

3.  **Scene 4: Dynamic Environment**
    - [ ] Create `Debris.tscn` (RigidBody2D or StaticBody2D with Sprite).
    - [ ] Create `Sparks.tscn` (GPUParticles2D).
    - [ ] Implement `EnvironmentController.trigger_destruction(phase)`:
        - [ ] Hardcode coordinates for "Wall Collapse" event.
        - [ ] `tilemap.set_cell` to remove wall.
        - [ ] `add_child` debris & particles.

4.  **Scene 5: Polish & Crash**
    - [ ] Add `Camera2D` shake method (if missing) to TSM.
    - [ ] Implement `_play_crash_cinematic()` reusing `CinematicOverlay`.
    - [ ] Verify `Phase.CRASH` transitions correctly to Main Game/Title.
