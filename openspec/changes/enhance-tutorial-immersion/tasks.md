# Tasks

1.  **Refactor Scene 1 (The Awakening)**
    - [ ] Add `CryoPod` (simple `Sprite2D` + `Area2D` setup).
    - [ ] Create intro camera pan sequence (`Tween` based).
    - [ ] Implement `Event:WakeUp` to transition from black screen to gameplay.

2.  **Refactor Scene 2 (First Magic)**
    - [ ] Implement `Stardust` collection mechanism (Key: E).
    - [ ] Enable `RevealSpell` effect (Visual highlight on hidden enemies).

3.  **Refactor Scene 3 (Wand Repair)**
    - [ ] Adapt `TutorialSequenceManager` to trigger `Phase.EDITOR` after collecting Stardust.
    - [ ] Use existing `WandEditor` validation logic (Generator + Projectile).
    - [ ] Update dialogue to explain *repairing* the wand instead of crafting a shield.

4.  **Refactor Scene 4 (Combat & Escape)**
    - [ ] Implement `EnemyWave` spawner (triggered post-wand repair).
    - [ ] Script the `ChargeBeam` event as a "Super Spell" cast using the repaired wand.

5.  **Refactor Scene 5 (Crash)**
    - [ ] Enhance existing `_start_crash_sequence` with screen shake, fade-to-black, and new dialogue.

6.  **Cleanup**
    - [ ] Remove unused `Phase` logic from old tutorial if any.
    - [ ] Verify `OverlayManager` works with new steps.
