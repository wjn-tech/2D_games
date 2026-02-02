# Proposal: Fix ESC Key Handling and HUD Visibility

## 1. Problem Statement
The current implementation of the ESC key (ui_cancel) causes the HUD to disappear and the input handling to become unresponsive after multiple presses. This is due to:
- `UIManager.close_all_windows()` hiding the `HUD` because it is tracked as an active window.
- Redundant state transitions and UI calls in `GameManager` when toggling pause.
- Potential race conditions in `UIManager` when closing multiple windows with animations.

## 2. Proposed Solution
- **UIManager Refinement**: Modify `close_all_windows()` to only target windows that block input (transient windows), leaving persistent UI like the HUD untouched.
- **GameManager Refactoring**: Simplify the ESC key logic to clearly distinguish between "closing a window" and "toggling pause".
- **State Management**: Ensure that transitioning to `PLAYING` state correctly restores the HUD visibility if it was somehow hidden.

## 3. Scope
- **In-Scope**:
    - `src/ui/ui_manager.gd`: Update `close_all_windows` and `close_window` logic.
    - `src/core/game_manager.gd`: Refactor `_input` and `change_state` logic for `PLAYING` and `PAUSED`.
- **Out-of-Scope**:
    - Adding new UI features.
    - Changing the design of the Pause Menu or HUD.

## 4. Impact
- **User Experience**: ESC will reliably close windows or toggle the pause menu without breaking the HUD.
- **Stability**: Prevents UI state from getting out of sync with the game state.
