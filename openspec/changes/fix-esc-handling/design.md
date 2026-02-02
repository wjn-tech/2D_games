# Design: ESC Key and UI Focus Management

## 1. UI Window Classification
We will distinguish between two types of UI elements:
- **Persistent UI (HUD)**: Opened with `blocks_input = false`. Should not be closed by "Close All" commands.
- **Transient Windows (Inventory, PauseMenu, etc.)**: Opened with `blocks_input = true`. These are the targets for ESC key closing.

## 2. UIManager Logic Changes
- `close_all_windows(only_blocking: bool = true)`: Add a parameter to filter which windows to close. By default, it will only close windows that are in the `blocking_windows` list.
- `is_ui_focused`: This should strictly reflect whether any window in `blocking_windows` is currently active.

## 3. GameManager Input Flow
The new ESC handling logic:
1. **Check for Blocking Windows**: If `UIManager.is_ui_focused` is true:
    - Call `UIManager.close_all_windows(true)`.
    - If the current state was `PAUSED`, transition to `PLAYING`.
    - If the current state was `PLAYING`, just return (window closed, game continues).
2. **Toggle Pause**: If no windows are blocking:
    - If `PLAYING` -> `PAUSED`.
    - If `PAUSED` -> `PLAYING`.

## 4. State Transition Refinement
- When entering `PLAYING` state:
    - Ensure `HUD` is visible.
    - Ensure `get_tree().paused = false`.
- When entering `PAUSED` state:
    - Ensure `PauseMenu` is opened.
    - Ensure `get_tree().paused = true`.
