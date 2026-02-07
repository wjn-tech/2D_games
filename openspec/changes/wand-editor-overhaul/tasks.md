# Tasks: Wand Editor Overhaul

1.  [x] **Editor Core Fixes** (`src/ui/wand_editor/`)
    -   [x] Modify `logic_board.gd`: Enable scroll, zoom, drag. Remove "Board Center" offset logic.
    -   [x] Fix loading logic to use raw `position_offset` without "internal offset" calculations.
    -   [x] Implement "Hover Scale" effect on `GraphNode` in `logic_board.gd`.
2.  [x] **Component Library** (`src/ui/wand_editor/wand_editor.gd`)
    -   [x] Add `Trigger (Collision)`, `Trigger (Timer)` to palette.
    -   [x] Ensure `Source` (Generator) is present (already added in previous fix, verify).
3.  [x] **Visuals** (`src/systems/magic/projectiles/`)
    -   [x] Update `projectile_standard.tscn`: Replace Sprite with "Pure Color" geometric style.
    -   [x] Update `projectile_base.gd`: Apply visual modulation based on `element` (Fire=Red, Ice=Blue).
4.  [x] **Simulation** (`src/ui/wand_editor/`)
    -   [x] Create `preview_viewport.tscn` (Sandbox environment).
    -   [x] Add "Simulate" button to `wand_editor.tscn`.
    -   [x] Connect button to `SpellProcessor` execution within the sandbox.
