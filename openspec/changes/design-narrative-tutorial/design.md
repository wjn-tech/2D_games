# Narrative Tutorial Design

## Architecture

1.  **Scene Breakdown (	utorial_spaceship.tscn)**
    *   A static, confined room acting as the interior of the starship.
    *   A player spawn point with a forced "locked" state.
    *   An animated NPC ("Court Mage") who initiates dialogue.
    *   Camera2D with logic for screen shakes.
    *   CanvasLayer with a pure black ColorRect for fade-in/fade-out transitions.
    *   TutorialSequenceManager script attached to the root, which orchestrates the event timeline.

2.  **State Machine / Timeline**
    *   **Phase 1: Exposition:** Player spawns; movement input is locked. The Court Mage starts the dialogue automatically. Skip listener is active (ui_cancel).
    *   **Phase 2: Dispensation & Rumbles:** Minor shakes. The Dialogue system emits a signal to give the player basic wand components and raw materials for crafting.
    *   **Phase 3: Magic Interruption:** Dialogue pauses. UIManager.open_window("WandEditor", ...) is called. The TutorialSequenceManager intercepts the wand_editor_closed signal and checks if a valid spell exists. If invalid, the UI re-opens or shows a warning. If valid, dialogue resumes.
    *   **Phase 4: Crafting Interruption:** Dialogue pauses. UIManager.open_window("Inventory", ...) is called. Player must synthesize an item (optional validation). Signal inventory_closed resumes dialogue.
    *   **Phase 5: The Crash:** Dialogue ends abruptly (or player skipped). Screen shake magnitude spikes. Screen fades to black.
    *   **Phase 6: Transition:** get_tree().change_scene_to_file("res://scenes/main.tscn").

3.  **Core System Extensions**
    *   **Dialogue Engine**: Must parse tokens like [emit=give_items] or [emit=show_magic] and broadcast them globally or to a localized sequence manager.
    *   **Wand Editor Hook**: Expose a quick validation check is_wand_valid() to external managers.
