# Tasks

- [x] **Refine Tutorial Manager**:
    -   Update `TutorialSequenceManager` with explicit phases in `_ready` or a `start_phase(enum)` method.
    -   Implement "Micro-Step Validation" (e.g., `_valid_step_inventory_opened`, `_valid_step_drag_started`).

- [x] **Create Guidance Assets**:
    -   `res://scenes/ui/tutorial/InputPrompt.tscn`: Displays a keyboard key icon (`W`, `I`, `K`) or mouse icon (`LeftClick`).
    -   `res://scenes/ui/tutorial/GhostCursor.tscn`: Minimal sprite animation for dragging items (cursor + faded icon).
    -   `res://scenes/ui/tutorial/HighlightMask.tscn`: Full-screen overlay with shader support for cutout circles/rects.

- [x] **Implement Phase 1: Movement**:
    -   Trigger `InputPrompt.show(["W", "A", "S", "D"])` on wake-up.
    -   Fade individual keys as they are pressed.
    -   Advance only when the player moves > 100 units.

- [x] **Implement Phase 2: Inventory & Equip**:
    -   Trigger `InputPrompt.show(["I"])` or highlight the HUD inventory button.
    -   Upon opening: Spotlight the **Backpack Slot 0** (Wand).
    -   Show **Ghost Drag**: Animation from Slot 0 -> Hotbar Slot 1.
    -   Highlight **Hotbar Slot 1**.
    -   Advance when `inventory_manager.get_equipped_item()` returns a Wand.

- [x] **Implement Phase 3: Wand Programming (Integrate Previous)**:
    -   Trigger `InputPrompt.show(["K"])` or highlight the Wand HUD button.
    -   Upon opening: Spotlight **Component Palette**.
    -   **Step 3a**: Highlight Trigger + Ghost Drag -> Grid (2, 2). Wait for `nodes_changed`.
    -   **Step 3b**: Highlight Projectile + Ghost Drag -> Grid (5, 2). Wait for `nodes_changed`.
    -   **Step 3c**: **Ghost Connection** (Trigger.Out -> Projectile.In). Wait for valid connection.
    -   Show "Configuration Validated" success banner.

- [x] **Implement Phase 4: Combat**:
    -   Spawn target dummy.
    -   Trigger `InputPrompt.show(["LeftClick"])` or `InputPrompt.show(["Space"])` near the player/crosshair.
    -   Highlight the target dummy with a red bracket/reticle.
    -   Advance when `target.destroyed` signal is emitted.

- [x] **Polish**:
    -   Add subtle sound effects for "Step Complete" and "Error".
    -   Ensure text prompts ("Drag here", "Press K") are localized strings.
