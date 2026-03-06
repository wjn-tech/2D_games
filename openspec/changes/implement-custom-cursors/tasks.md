# Tasks: Implement Custom Dynamic Cursors

## Task List

- [ ] **Define Cursor Assets & Resources**
	- [ ] Identify or create placeholder SVG/PNGs for basic cursors: Default Arrow, Hand (Hover), Grab (Drag), Target (Combat), Wait (Loading).
	- [ ] Create a `CursorTheme` Resource to map enumerations to textures and hotspots (pixel offsets).
- [ ] **Create CursorManager Autoload**
	- [ ] Implement `CursorManager.gd` as an Autoload.
	- [ ] Add `set_cursor(type: CursorType)` method using `Input.set_custom_mouse_cursor()`.
	- [ ] Implement state tracking to prevent flickering or redundant switches.
- [ ] **UI Integration**
	- [ ] Update `UIManager.gd` to reset cursor to default when all blocking windows are closed.
	- [ ] Add cursor override support for interactable UI elements (inventory slots, buttons).
- [ ] **World Interaction Integration**
	- [ ] Update interaction raycasts or hover logic to signal `CursorManager` when hovering over collectibles or NPCs.
- [ ] **Verification & Polishing**
	- [ ] Verify cursor visibility and scaling on different resolutions.
	- [ ] Check hotspot alignment (e.g., clicking with the tip of the arrow vs. center of the crosshair).
	- [ ] Test cursor behavior during high-latency or paused states.
