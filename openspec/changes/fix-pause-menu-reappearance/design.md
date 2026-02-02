# Design: UI Lifecycle and Reuse Management

## 1. Window Reuse Flow
When `open_window` is called for a window that is already in `active_windows`:
1. Set `visible = true`.
2. Set `process_mode = Node.PROCESS_MODE_ALWAYS`.
3. If `blocks_input` is true:
    - Add to `blocking_windows` if not already present.
    - Set `is_ui_focused = true`.
4. Emit `window_opened(window_name)`.
5. Play open animation.

## 2. Accurate "Pre-existing" Detection
Instead of using `find_child` which can find dynamically added nodes, we will:
- Check if the node's owner is the current scene root.
- Or, more simply, check if the window was instantiated from a scene path during the current session.
- For now, we will use a more specific check: only nodes that are children of the `UI` layer *and* were not added via `UIManager.open_window`'s instantiation logic should be considered pre-existing.
- Actually, the simplest way is to check if the node was already in the tree when `UIManager` first looked for it, or just explicitly list `MainMenu` and `HUD` as persistent if they are in the scene.

## 3. Signal Consistency
Every `open_window` call must result in a `window_opened` signal, and every `close_window` call must result in a `window_closed` signal, regardless of whether the node was freed or just hidden.
