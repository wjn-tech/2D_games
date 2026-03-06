# Tasks: Enhance Tutorial Ending

Track progress of the tutorial crash sequence implementation.

- [ ] **Tutorial Logic: Implement Space Crash**
  - [ ] Update `tutorial_sequence_manager.gd` `CRASH_SEQUENCE`.
  - [ ] Hide `TutorialSpaceship` geometry (walls/floor) instantly.
  - [ ] Hide `CourtMage` NPC (only shield VFX remains).
  - [ ] Maintain `Main.tscn` (do not reload scene) to preserve inventory.
  - [ ] Ensure fall sequence lasts 8-10 seconds for smoothness.

- [ ] **Visual Effects: Debris & Fall**
  - [ ] Create `ship_debris.tscn` (mechanical parts: metal/sparks, no magic).
  - [ ] Spawn debris bursts around player start position.
  - [ ] Add `visuals/vfx/falling_wind_lines.tscn` (Line2D/Particles2D).
  - [ ] Create "Court Mage Shield" `CPUParticles2D` (child of Player during fall).

- [ ] **Camera & Audio**
  - [ ] Implement camera shake and zoom-out during disintegration.
  - [ ] Implement camera "blur" effect (shader or `WorldEnvironment` tweaks) for atmospheric entry.
  - [ ] Add sound effects for explosion, wind rushing, and impact (placeholder logic if assets missing).

- [ ] **Player State: Falling & Waking Up**
  - [ ] Temporarily disable player input and gravity (or use custom gravity).
  - [ ] Rotate player sprite 90 degrees or use "tumble" animation during fall.
  - [ ] Implement "Wake Up" sequence:
    - [ ] Teleport player to ground spawn point (`(0, 0)` or verified safe zone).
    - [ ] Set player rotation to -90 (lying down).
    - [ ] Fade in from white/blur.
    - [ ] Tween rotation to 0 (standing up) after X seconds.
    - [ ] Enable input and HUD.
