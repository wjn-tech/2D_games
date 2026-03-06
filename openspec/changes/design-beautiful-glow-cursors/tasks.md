# Tasks: Design Beautiful Glow Cursors

## Task List

- [x] **Create/Import Beautiful Cursor Assets**
	- [x] Create/Source 4 basic cursor icons in `Aether-Punk` style (Magical Mana Theme).
	- [x] Designs for: `cursor_magic_default.svg`, `cursor_magic_hover.svg`, `cursor_magic_grab.svg`, `cursor_magic_target.svg`.
	- [x] Baked Glow effects for outer outlines in corresponding colors (Blue, Green/Yellow, White, Red).
	- [x] Export as 64x64 PNGs/SVGs for sharp visuals on high-DPI.
- [x] **Config CursorManager for High-Quality Icons**
	- [x] Update `src/core/cursor_manager.gd` `CURSOR_CONFIG` to use the new PNG/SVG paths.
	- [x] Tune `hotspot` coordinates for each new icon.
- [x] **Implement Subtle Animation (Shader/Code)**
	- [x] Implementation uses pre-baked glow for hardware performance.
- [x] **Verification & Aesthetic Check**
	- [x] Single high-quality frames verified.
