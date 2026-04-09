# start_menu_shell

This folder stores shell-level visual tokens used by start-game loading UI.

- `loading_theme.json`: Theme tokens consumed by `UIManager` loading overlay.
- `menu_theme.json`: Theme tokens consumed by `MainMenu` shell layout (header/body/footer, typography, and button hierarchy).

Fallback behavior:
- If `loading_theme.json` is missing or invalid, loading UI automatically uses built-in Godot styles.
- If `menu_theme.json` is missing or invalid, start menu automatically falls back to built-in scene styles.
