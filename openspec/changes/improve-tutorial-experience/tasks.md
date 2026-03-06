# Tasks

1.  **Opening Cinematic**
    -   [x] Implement initial `Camera.shake` on start.
    -   [x] Add `CanvasModulate` or `CanvasLayer` flicker (red alert).

2.  **Movement Verification**
    -   [x] Update `Phase.MOVEMENT` logic: Track `start_pos`.
    -   [x] Only call `_check_step("move")` when `distance_moved > 50`.

3.  **Inventory Guidance**
    -   [x] Modify `InventoryUI` to expose `get_slot_global_position(index)`.
    -   [x] Implement `GhostMouse` in `OverlayManager`.
    -   [x] Find correct `InventorySlot` and `HotbarSlot` positions.
    -   [x] Animate mouse dragging item to hotbar.

4.  **Wand Editor Flow**
    -   [x] Modify `WandEditor` to expose `get_slot_global_position(item_id)` and `get_grid_cell_global_position(x, y)`.
    -   [x] Step 1: Force "Open Editor" (K).
    -   [x] Step 2: Show ghost mouse dragging `Generator` -> `Grid(1,1)`.
    -   [x] Step 3: Show ghost mouse dragging `Projectile` -> `Grid(3,1)`.
    -   [x] Step 4: Show ghost mouse connecting `Generator(Output)` -> `Projectile(Input)`.
    -   [x] Clear existing logic on editor open if in "Tutorial Mode".

5.  **Transition**
    -   [x] Implement `_on_wall_broken` -> `Crash Sequence`.
    -   [x] Fade -> Teleport -> Fade.
    -   [x] Clean up tutorial scene.

6.  **Cleanup**
    -   [x] Ensure ghost mouse is removed when steps complete.
    -   [x] Remove tutorial wand from inventory after tutorial (optional, leaving starter item is usually better).
