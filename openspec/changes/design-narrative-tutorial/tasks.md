# Tasks: Narrative Tutorial Implementation

1. [ ] **Enhance Dialogue System**
   - Extend dialogue_window.gd or DialogueManager to parse embedded action tags (e.g., <emit:show_magic>).
   - Add Godot signals to the manager to broadcast these events to external listeners.

2. [ ] **Build Scene Foundation**
   - Create scenes/tutorial/tutorial_spaceship.tscn.
   - Add a static enclosed TileMap/Sprite layout for a starship interior.
   - Add a Player instance and a placeholder "Court Mage" NPC (scenes/npc/court_mage.tscn).

3. [ ] **Lock Player Input**
   - Integrate a state override or set_physics_process(false) mechanism in player.gd when a cinematic flag is enabled.
   - Trigger this lock via TutorialSequenceManager on _ready().

4. [ ] **Implement Screen FX Systems & Skip Mechanics**
   - Attach .gd script logic for camera shake parameterization (amplitude over time).
   - Add a CanvasLayer FadeOverlay for transitions.
   - Add an _input(event) listener for the ui_cancel (ESC) action that instantly jumps the internal state machine to the crash phase.

5. [ ] **Draft the Dialogue Tree & Dispensation**
   - Implement the dialogue describing the stolen magic kingdom.
   - Add the midpoint node <emit:give_items>.
   - Connect give_items in TutorialSequenceManager to populate InventoryManager with 1x Basic Wand, 1x Spark trigger, 1x Mod Node, and base wood/stone.

6. [ ] **Connect the UI Interruptions & Validation**
   - On <emit:show_magic>, open WandEditor via UIManager.
   - Override the WandEditor close button or _input block during tutorial mode. Check wand_data.is_valid() before permitting dialogue to resume.
   - On <emit:show_crafting>, open Inventory. Optional validation step for synthesizing an item.

7. [ ] **Implement the Crash Sequence**
   - On dialogue exhaust or SKIP action, hit start_crash_sequence().
   - Maximize camera shake amplitude. Play SFX.
   - Tween fade to black over 2.0 seconds.
   - Transition scene to scenes/main.tscn.

8. [ ] **Integrate with Main Menu Route**
   - Update start_menu.gd button logic. "New Game" routes to 	utorial_spaceship.tscn. "Load Game" routes to main.tscn.
