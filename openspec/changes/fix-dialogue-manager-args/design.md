# Design: Fix DialogueManager open_window arguments

## Architectural Reasoning
The `UIManager` is designed to be a generic window manager that can instantiate windows from scene paths if they are not already present in the scene tree. The `DialogueManager` is a high-level system that uses the `UIManager` to display dialogue.

The fix is straightforward: provide the missing `scene_path` argument to `UIManager.open_window()`.

## Trade-offs
- **Hardcoding the path**: Hardcoding the path in `DialogueManager` is acceptable for now as it's a core UI component. In a more complex system, we might use a registry or a constant, but for a single fix, this is the most direct approach.

## Verification Plan
- **Manual Test**: Trigger a dialogue in-game (e.g., by interacting with an NPC) and verify that the dialogue window opens without errors.
- **Static Analysis**: Check for script errors in the Godot editor or via Pylance/GDScript LSP if available.
