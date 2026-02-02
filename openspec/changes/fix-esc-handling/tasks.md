# Tasks: Fix ESC Key Handling

## Phase 1: UIManager Updates
- [x] **Task 1.1**: Update `close_all_windows` in `src/ui/ui_manager.gd`.
    - Add `only_blocking` parameter (default `true`).
    - Only close windows that are in `blocking_windows` if `only_blocking` is true.
- [x] **Task 1.2**: Fix `is_ui_focused` update in `close_window`.
    - Ensure it correctly checks `blocking_windows.is_empty()`.

## Phase 2: GameManager Updates
- [x] **Task 2.1**: Refactor `_input` in `src/core/game_manager.gd`.
    - Implement the new ESC logic: close windows first, then toggle pause.
- [x] **Task 2.2**: Clean up `change_state` for `PLAYING` and `PAUSED`.
    - Avoid redundant `close_all_windows` calls if possible, or ensure they don't hide the HUD.

## Phase 3: Validation
- [x] **Task 3.1**: Verify ESC closes Inventory without pausing.
- [x] **Task 3.2**: Verify ESC toggles Pause Menu when no other windows are open.
- [x] **Task 3.3**: Verify HUD remains visible throughout these transitions.
