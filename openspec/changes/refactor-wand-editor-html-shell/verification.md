# Verification: Wand Editor HTML Embedded Shell

## 1. Implementation Evidence

### 1.1 Logic Contract Freeze (Godot authoritative)
- Web shell only submits intents; Godot applies existing chains and re-syncs state.
- Evidence:
  - `src/ui/wand_editor/wand_editor.gd`
    - `_on_wand_web_ipc_message` routes intents to existing handlers (`wand_test`, `wand_save`, `wand_clear`, mode switch, selector open).
    - `_apply_web_graph_data` updates `current_wand.logic_nodes/logic_connections`, then reuses `logic_board.load_from_data(...)` and existing stats/event updates.
    - `_apply_web_visual_cells` writes `current_wand.visual_grid`, calls `normalize_grid()`, preview refresh, stats refresh.

### 1.2 Chinese Copy Baseline
- Refreshed `openspec/changes/refactor-wand-editor-html-shell/chinese-copy-after.txt` from `ui/web/wand_editor_shell/index.html` (UTF-8 extraction).
- Artifact now reflects deployed shell copy, including top bar actions, mode labels, compile/status strings.

### 1.3 Layout Ratio Baseline
- Godot emits ratio snapshot via `_collect_layout_ratio_snapshot()`.
- Web shell applies and clamps ratios in `applyLayoutRatios(...)` (`left/right/top` bounds) to keep existing structure proportions.

## 2. Sample-Style Art Transplant
- New shell file delivered: `ui/web/wand_editor_shell/index.html`.
- Included style tokens and effects aligned to requested sample direction:
  - Deep-space layered background + animated stars/meteors
  - Pixel borders + scanline/CRT overlay
  - Accent glow system and pixel control styling
- Existing logic layout skeleton preserved with top bar + left palette + center workspace + right detail panel.

## 3. Bridge Protocol and Conflict Rules

### 3.1 Godot -> Web
- Full state message: `wand_state_full`
  - Includes logic graph, visual cells, palettes, compile info, and layout ratios.
- Compatibility message: `wand_state` (minimal legacy payload).

### 3.2 Web -> Godot Intents
- Implemented intents: `wand_ready`, `wand_request_state`, `wand_set_active_tab`, `wand_set_name`, `wand_graph_changed`, `wand_visual_changed`, `wand_clear`, `wand_test`, `wand_save`, `wand_switch`, `wand_close`.
- Graph/visual edits use debounced sync (`scheduleGraphSync`, `scheduleVisualSync`) and flush before save/test.

### 3.3 Conflict Priority (Logic > Ratio > Theme)
- Logic priority enforced by making Godot authoritative and re-syncing from canonical state.
- Ratio priority enforced through ratio snapshot + clamped application.
- Theme is implemented inside those two constraints.

### 3.4 Failure and Recovery
- Native fallback retained when shell resource/WebView is unavailable:
  - Missing shell HTML
  - Missing WebView class
  - WebView instantiation failure
- Fallback paths are guarded in `_try_setup_web_editor_webview()` with warnings and native mode continuity.

## 4. Validation Status

### 4.1 Completed (static + integration structure)
- Diagnostics check passed for changed files:
  - `src/ui/wand_editor/wand_editor.gd`
  - `ui/web/wand_editor_shell/index.html`
- Protocol and intent routes are implemented end-to-end in code.

### 4.2 Pending (manual runtime parity)
- The following parity checks still require in-engine manual execution:
  - Drag, connect, zoom, pan, Delete/Backspace, Esc, mode switch
  - Test/Save/Switch wand full flow
  - Visual and logic output parity against native editor
  - Chinese copy diff strict check against acceptance baseline
  - Ratio parity snapshot verification under real window resize conditions

## 5. Conclusion
- Delivered: sample-style shell transplant + Godot/Web bidirectional bridge with logic-first contract.
- Remaining gate: runtime manual parity sign-off (section 4.2).
