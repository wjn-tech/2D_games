# Design: Tutorial Visual Guidance

## Core Components

### 1. `HighlightOverlay` (Scene)
A dedicated UI overlay managed by `UIManager` to draw attention to specific controls.

**Structure**:
- `CanvasLayer` (Layer 150 - Above specific UI windows)
- `ColorRect` (Full Screen, Dimming Color `Color(0, 0, 0, 0.4)`)
    - **Shader Material**: Uses a Signed Distance Field (SDF) or simple rectangle mask to cut a hole in the dimming layer at `target_rect`.
    - **Uniforms**: `rect_position`, `rect_size`, `corner_radius`, `softness`.
- `ReferenceRect` (Pulsing Border)
    - Positions itself to match `target_rect`.
    - Has an `AnimationPlayer` to pulse opacity/scale slightly.
- `Label` (Floating Hint)
    - Optional text ("Click here!", "Drag this!") positioned near `target_rect`.

### 2. `UIManager` Highlighting API
- `highlight_element(control: Control, message: String = "")`
    - Validates `control` is inside the tree and visible.
    - Instantiates/Shows `HighlightOverlay`.
    - Sets `HighlightOverlay.target = control`.
- `clear_highlight()`
    - Hides/frees `HighlightOverlay`.

### 3. Wand Editor Introspection
To highlight specific *internal* elements of the complex `WandEditor`, we need helper methods:
- `get_palette_button(item_id: String) -> Control`: Used to highlight the specific spell component (Trigger, Projectile) the user needs to drag.
- `get_logic_node(node_id: String) -> Control`: Used to highlight placed nodes for connecting.

## Interaction Flow

1.  **Tutorial Step Starts**: `TutorialSequenceManager` receives `<emit:highlight:trigger_item>` tag.
2.  **Lookup**: It calls `UIManager.find_element("wand_editor_palette_trigger")` (Requires a registry or specific lookup logic).
    - *Alternative*: `TutorialSequenceManager` has direct reference to `WandEditor` instance and calls `get_palette_button("trigger")`.
3.  **Active Highlight**: `UIManager` activates overlay.
    - `HighlightOverlay` cutting hole at button position.
    - "Drag to Grid" label appears.
4.  **User Action**: User successfully drags item.
5.  **Step Completes**: Logic detects change -> `EventBus.spell_logic_updated`.
6.  **Cleanup**: `TutorialSequenceManager` calls `clear_highlight()`.

## Assets
- **Shader**: `res://assets/shaders/ui/cutout_mask.gdshader` (New).
- **Icons**: Simple "Pointer Hand" or "Arrow" texture for the overlay.
