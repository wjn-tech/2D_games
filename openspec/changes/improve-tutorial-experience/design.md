# Design: Tutorial Immersion and Interactivity

## Overview
This design covers the implementation details for improving the tutorial sequence, focusing on user interaction verification, visual guidance systems, and cinematic atmosphere.

## System Components

### 1. Cinematic Opening
-   **Visuals**: Use `Camera.shake` and a flickering red overlay (CanvasLayer) to simulate a ship in distress.
-   **Timing**: Delay the first dialogue by 2-3 seconds to let the atmosphere sink in.

### 2. Interaction Verification
-   **Movement**:
    -   Track `player.global_position` at the start of the `MOVE` phase.
    -   Require `distance_to(start_pos) > 50` pixels before firing `_check_step("move")`.
-   **Inventory**:
    -   Implement a `GhostMouse` (Control node with Sprite) managed by `OverlayManager`.
    -   Use helper methods `InventoryUI.get_slot_global_position(0)` and `HotbarUI.get_slot_global_position(0)` for precise target coordinates.
    -   It should animate from `InventorySlot` -> to `HotbarSlot` repeatedly until the item is successfully moved.

### 3. Wand Programming Logic
-   **Flow**:
    1.  Ask player to open Wand Editor (K). Wait for `EventBus.wand_editor_opened`.
    2.  Check `current_wand` logic. If not empty, clear `logic_nodes` and `logic_connections` on the `WandData`.
    3.  **Step 1: Place Generator**:
        -   Use `WandEditor.get_palette_item_global_position("generator")` and `WandEditor.get_grid_cell_global_position(1, 1)` for targets.
        -   Show ghost mouse dragging "Mana Source" (Generator) to `Grid(1, 1)`.
        -   Wait for `nodes_changed` signal -> check if `generator` exists.
    4.  **Step 2: Place Projectile**:
        -   Highlight "Projectile" (e.g., Spark Bolt) in palette.
        -   Show ghost mouse dragging "Projectile" to `Grid(3, 1)`. (Leaving space for complexity later).
        -   Wait for `nodes_changed` signal -> check if `action_projectile` exists.
    5.  **Step 3: Connect**:
        -   Show ghost mouse dragging from `Output(Generator)` to `Input(Projectile)`.
        -   Wait for `nodes_changed` signal -> check for valid connection.
    6.  **Step 4: Close Editor**:
        -   Prompt user to close editor (K/Esc).

### 4. Transition
-   On wall break:
    -   Advance dialogue to "Too Late!".
    -   Play "Crash" sound.
    -   Flash white -> Fade to black over 2 seconds.
    -   Teleport player to spawn.
    -   Wait 1 second.
    -   Fade in.

## Implementation Details

### Scene Changes
-   **TutorialSequenceManager**: Update `_process` and `_on_editor_nodes_changed` to support new flow.
-   **OverlayManager**: Add `create_ghost_mouse()` and `animate_drag(from, to)` methods.
-   **WandEditor**: Expose `get_slot_position(item_id)` and `get_grid_position(cell_x, cell_y)` helper methods for accurate overlay positioning.

### Data
-   Update `wand_data` resources used in tutorial to ensure they start blank or are cleared.

## Trade-offs
-   Using specific grid coordinates (1,1) (3,1) assumes fixed cell size. If zoom changes, ghost positions might drift.
    -   *Decision*: Use `logic_board.get_screen_position(grid_pos)` to calculate dynamic screen coordinates.

