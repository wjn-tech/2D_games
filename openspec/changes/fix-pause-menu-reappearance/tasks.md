# Tasks: Fix Pause Menu Reappearance

## Phase 1: UIManager Logic Fixes
- [x] **Task 1.1**: Update `open_window` in `src/ui/ui_manager.gd`.
    - Move the `blocking_windows` and signal logic into a shared block or ensure it's called during reuse.
- [x] **Task 1.2**: Update `close_window` in `src/ui/ui_manager.gd`.
    - Fix the `is_pre_existing` check to be more accurate.
    - Ensure `active_windows.erase` is called for non-persistent windows.

## Phase 2: Validation
- [x] **Task 2.1**: Test ESC -> Pause -> ESC -> Resume -> ESC -> Pause sequence.
- [x] **Task 2.2**: Verify `is_ui_focused` state remains correct after multiple toggles.
