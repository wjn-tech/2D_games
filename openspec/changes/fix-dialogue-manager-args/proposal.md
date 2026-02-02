# Proposal: Fix DialogueManager open_window arguments

## 1. Problem Statement
The `DialogueManager` autoload calls `UIManager.open_window()` with only one argument (`window_name`), but the function signature in `UIManager` requires at least two arguments (`window_name` and `scene_path`). This causes a runtime error: `Too few arguments for "open_window()" call. Expected at least 2 but received 1.`

## 2. Proposed Solution
Update the `start_dialogue` function in `src/ui/dialogue_manager.gd` to provide the correct scene path for the `DialogueWindow`.

## 3. Scope
- `src/ui/dialogue_manager.gd`: Update the `open_window` call.

## 4. Dependencies
- `UIManager` autoload must be correctly configured (already exists).
- `res://scenes/ui/DialogueWindow.tscn` must exist (already exists).
