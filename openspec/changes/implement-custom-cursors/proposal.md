# Proposal: Implement Custom Dynamic Cursors

## Problem Context
Currently, the game uses the default system mouse cursor. Modern games often use custom, context-aware cursors to improve immersion and provide visual feedback to the player (e.g., a "grab" cursor over items, a "targeted" cursor over enemies, or a "wait" cursor during loading).

## Proposed Solution
Introduce a centralized `CursorManager` (as a component of `UIManager` or a separate Autoload) that handles the definition and switching of custom mouse cursors based on game state, UI focus, and world interactions.

### Key Features:
- **Centralized Cursor Registry**: Define different cursor types (ARROW, HAND, TARGET, GRAB, WAIT) with their respective textures and hotspots.
- **Context Sensitivity**: Automatically change the cursor when hovering over interactive world objects (NPCs, Items) or specific UI elements.
- **Input Neutrality**: The system should not interfere with existing input logic but enhance the visual representation.
- **Theming Support**: Use the existing UI theme/palette for cursor design consistency.

## Performance & Security
- Cursor textures will be small (e.g., 32x32 or 64x64) to minimize memory impact.
- Software-side cursor logic is used via `Input.set_custom_mouse_cursor()` to ensure compatibility and low overhead.

## Architecture & Design
- **Autoload/Singleton**: `CursorManager` will be an Autoload to persist across scenes.
- **Resource-based**: Cursor definitions will be stored as a custom Resource or within the main UI Theme.
- **Integration**: `UIManager` will notify `CursorManager` when UI windows are opened/closed to reset or shift cursor context.
