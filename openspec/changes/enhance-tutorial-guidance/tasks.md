# Tasks: Enhance Tutorial Guidance

## Core Systems
- [x] Create `HighlightOverlay` scene (`scenes/ui/tutorial/highlight_overlay.tscn`).
    - [x] Root Control (Full Rect).
    - [x] `ColorRect` (Dimmer) with shader to cut out a transparent hole.
    - [x] `AnimationPlayer` (Simulated via code)
- [x] Add `highlight_element(control: Control, message: String = "")` to `UIManager`.
    - [x] Should instantiate/show `HighlightOverlay`.
    - [x] Should dynamically update the hole position/size to match `control.get_global_rect()`.
- [x] Add `clear_highlight()` to `UIManager`.

## Wand Editor Integration
- [x] Add method `WandEditor.get_palette_button_rect(item_id: String) -> Rect2`. (Added `get_palette_button_by_item_id`)
    - [x] Iterate `module_palette` and `palette_grid` to find button with matching item ID.
- [ ] Add method `WandLogicBoard.get_node_rect(node_id: String) -> Rect2`. (Skipped for now, palette is priority)
    - [ ] Find `GraphNode` with matching ID.

## Tutorial Sequence Updates
- [x] Update `TutorialSequenceManager` to support `<emit:highlight:item_id>` tags.
    - [x] Parse `highlight:inventory_slot_1` -> Highlight inventory slot.
    - [x] Parse `highlight:wand_editor_trigger` -> Highlight "Trigger" in palette.
    - [x] Parse `highlight:wand_editor_projectile` -> Highlight "Projectile" in palette.
- [x] Implement robust arrow positioning that tracks moving UI elements (if draggable). (Used HighlightOverlay instead)

## Visual Polish
- [x] Add a fast "Tooltip" or "Hint" popup that appears near the highlighted element with the instruction text (e.g. "Drag this!"). (Included in HighlightOverlay label)
