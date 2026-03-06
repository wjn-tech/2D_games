# Narrative Tutorial Design

## Architecture

1.  **Scene Design**
    *   **Node Structure:** `SceneTree` -> `world (Node2D)` -> `TutorialSpaceship (Node2D)` (temporary).
    *   **Position**: Place the `TutorialSpaceship` far from the actual playable world origin (e.g., Vector2(0, -99999)).
    *   **Components**: Sprite/TileMap (spaceship visuals), Camera2D (for interior, priority=100), Player (spawned here initially), NPC ("Court Mage").
    *   **Manager**: `TutorialSequenceManager` script attached to `TutorialSpaceship`.

2.  **State Machine / Timeline**
    *   **Phase 1: Exposition:** Player starts at `TutorialSpaceship` pos. Input locked. Camera focused on ship. Mage speaks.
    *   **Phase 2: Dispensation & Rumbles:** Minor shakes. Give items/spells via signals.
    *   **Phase 3: Magic Interruption:** Open WandEditor. Wait for `wand_editor_closed` + `is_wand_valid()`.
    *   **Phase 4: Crafting Interruption:** Open Inventory. Wait for `inventory_closed`.
    *   **Phase 5: The Crash:** Dialogue ends. Intense shakes. `FadeOverlay` (CanvasLayer) tweens alpha to 1.0 (Black/White).
    *   **Phase 6: Transition (Crucial Step):**
        *   While faded out:
        *   Set player position to actual spawn point (Vector2(0, 0)).
        *   Disable/QueueFree `TutorialSpaceship`.
        *   Disable tutorial camera (world camera takes over).
        *   Unlock player input.
        *   Tween `FadeOverlay` alpha to 0.0.

3.  **Core System Extensions**
    *   **Dialogue Engine**: Support `[emit=give_items]` tags.
    *   **Wand Editor**: Expose `is_wand_valid()` to verify tutorial progress.
    *   **World Startup**: Check `GameGlobal.is_new_game` to decide whether to spawn at Ship or World.

## Alternative: Overlay Approach
Instead of a physical location, use a pure UI (`CanvasLayer`) approach if interactions are purely dialogue/menu based. However, **physical location** is better for immersion (screen shake, wandering NPC, player sprite visibility).
