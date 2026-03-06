# Proposal: Improve Tutorial Immersion and Interactivity

## Summary
Refine the tutorial sequence to provide a more immersive, interactive learning experience. This change addresses issues with movement feedback, UI guidance (ghost cursor), logic editing flow (generator -> projectile), and opening cinematics. It ensures the player performs meaningful actions rather than just triggering detection flags.

## Motivation
Current tutorial issues reported by users:
1.  **Movement**: Player input is detected but character doesn't move meaningfully before the step completes.
2.  **Inventory**: Lack of visual guidance (ghost mouse) for dragging items.
3.  **Wand Programming**:
    -   Starts before UI is fully open.
    -   Circuit board contains pre-existing connections (logic state not reset).
    -   Teaches Trigger -> Projectile instead of Generator -> Projectile (logical progression).
    -   Ghost cursor positions are misaligned.
4.  **Opening**: Lack of tension (crash sequence feels flat).
5.  **Transition**: Abrupt end without a smooth transition or cutscene.

## Proposed Solution
1.  **Opening Cinematic**: Add screen shake and red alert overlay cues before the first dialogue.
2.  **Movement Verification**: Require the player to move a minimum distance (e.g., 50 pixels) or reach a specific marker before completing the "Move" step.
3.  **Inventory Guidance**: Implement a "Ghost Mouse" animation system that overlays the UI, demonstrating the drag-and-drop action from backpack to hotbar.
4.  **Wand Editor Flow**:
    -   Force the player to open the editor (Press K) and see the empty grid.
    -   **Reset the tutorial wand**: Ensure the logic board is completely empty when the lesson starts.
    -   **New Logic Sequence**: Teach "Generator (Mana Source)" -> "Projectile" connection.
    -   **Visual Guidance**: Show the ghost mouse dragging the specific components from the palette to the grid, then drawing the connection.
5.  **Polished Transition**: Add a fade-out/fade-in sequence with a "Crash" sound effect and a short delay before spawning in the main world.

## Risks & Mitigation
-   **Risk**: Hardcoded UI positions for ghost mouse might break if UI layout changes.
    -   **Mitigation**: Use dynamic position lookup (getNode position + offset) instead of hardcoded coordinates.
-   **Risk**: Resetting the wand might traverse to the player's actual inventory if specific item IDs are used.
    -   **Mitigation**: Use a specific "Tutorial Wand" instance or ensure the reset only applies during the tutorial phase.
