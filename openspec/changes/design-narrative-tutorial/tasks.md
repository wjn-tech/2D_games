# Tasks: Narrative Tutorial Implementation

1. [ ] **Enhance Dialogue System**
   - Extend dialogue_window.gd to parse embedded action tags (e.g., <emit:show_magic>).
   - Add Godot signals for action callbacks.

2. [ ] **Implement Tutorial Scene Structure**
   - Refactor `scenes/tutorial/tutorial_spaceship.tscn` to be a standalone Node2D (not a full scene) that can plug into main.
   - Add a `TutorialSequenceManager` script to control flow.
   - Design the spaceship interior using `TileMapLayer` and decorative Sprites.
   - Place "Court Mage" NPC and player spawn point within this local space.

3. [ ] **Add Tutorial to Main Scene**
   - In `scenes/main.tscn`, instantiate `tutorial_spaceship.tscn` as a child node (initially hidden/far away or overlaid).
   - On `_ready()`, check `GameGlobal.is_new_game`. If true:
     - Activate `TutorialSpaceship`.
     - Disable main world rendering (or just move camera to ship).
     - Start tutorial sequence.
     - Else: Free/Disable `TutorialSpaceship`.

4. [ ] **Implement Screen FX Systems & Skip Mechanics**
   - Add simple camera shake logic to `tutorial_spaceship` camera.
   - Create a `FadeOverlay` (CanvasLayer + ColorRect) for the transition.
   - Add `_unhandled_input` listener for `ui_cancel` (ESC) to trigger the "Crash" sequence.

5. [ ] **Draft the Dialogue & Logic**
   - Script the "Court Mage" dialogue (Stolen Magic lore).
   - Implement `give_items` logic: 1x Basic Wand handle, 1x Spark spell, 1x Mod Node, wood/stone.

6. [ ] **Connect UI Validation**
   - On `<emit:show_magic>`, open `WandEditor`. Ideally block closing until `wand_data.is_valid()`.
   - On `<emit:show_crafting>`, open `Inventory`.

7. [ ] **Implement the Crash Sequence**
   - Maximize camera shake. Shake sound.
   - Tween `FadeOverlay` to Black (alpha 1.0) over 2.0s.
   - During black:
     - `player.global_position = world_spawn_point`
     - `tutorial_spaceship.queue_free()`
   - Tween `FadeOverlay` to Transparent (alpha 0.0).
   - Enable World Camera/Player control.

8. [ ] **Standardize Start Menu**
   - Update `start_menu.gd`: "New Game" sets `GameGlobal.is_new_game = true` and loads `main.tscn`.

