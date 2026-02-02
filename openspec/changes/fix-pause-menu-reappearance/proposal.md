# Proposal: Fix Pause Menu Reappearance Issue

## 1. Problem Statement
The Pause Menu only appears the first time the ESC key is pressed. Subsequent presses pause the game but fail to show the menu. This is caused by logic gaps in `UIManager.open_window` when reusing existing windows and a flawed "pre-existing" check in `close_window` that prevents dynamic windows from being properly destroyed.

## 2. Proposed Solution
- **Fix Window Reuse**: Update `UIManager.open_window` to ensure that when a window is reused (made visible again), it is correctly added back to `blocking_windows`, `is_ui_focused` is updated, and the `window_opened` signal is emitted.
- **Refine Deletion Logic**: Improve the `is_pre_existing` check in `close_window` to ensure that only windows that were truly part of the scene's initial structure are preserved, while dynamically instantiated windows like the Pause Menu are properly freed.
- **Animation Safety**: Ensure that visibility is set correctly even if animations are skipped or interrupted.

## 3. Scope
- **In-Scope**:
    - `src/ui/ui_manager.gd`: Refactor `open_window` and `close_window`.
- **Out-of-Scope**:
    - Changes to `GameManager` (unless necessary for signal handling).
    - Changes to the Pause Menu scene itself.

## 4. Impact
- **User Experience**: The Pause Menu will reliably appear every time the game is paused via ESC.
- **Code Quality**: Better management of UI lifecycle and focus states.
