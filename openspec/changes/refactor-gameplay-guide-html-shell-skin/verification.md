# Verification: refactor-gameplay-guide-html-shell-skin

## Build/Validation Checks
- `openspec validate refactor-gameplay-guide-html-shell-skin --strict` passed.
- Static diagnostics passed for:
  - `src/ui/guide/gameplay_guide_window.gd`
  - `ui/web/gameplay_guide_shell/index.html`

## Contract Verification
- Logic parity:
  - Existing page build pipeline remains in Godot (`_build_catalog_and_pages`).
  - Existing page selection and navigation handlers remain authoritative (`_select_page`, `_on_prev_pressed`, `_on_next_pressed`).
- Content parity:
  - Shell receives page/catlog snapshots from Godot only.
  - No alternate guide data source is introduced.
- Bridge boundary:
  - Shell emits intent-only IPC messages.
  - Godot validates and applies transitions.

## Fallback Verification Matrix
- WebView class missing -> native fallback path present.
- WebView instantiate failure -> native fallback path present.
- Shell resource missing -> native fallback path present.
- Bridge readiness timeout -> watchdog fallback path present.
- Runtime post_message unavailable -> native fallback path present.
- Bridge error message -> native fallback path present.

## Scope Guard Verification
- HUD entry flow unchanged.
- Guide data model (`GuideSectionData`) unchanged.
- Guide semantics and chapter hierarchy unchanged.
- Only guide shell rendering architecture replaced.

## Visual Refresh Verification (2026-04-09)
- Updated shell file validated with static diagnostics:
  - `ui/web/gameplay_guide_shell/index.html` no errors.
- Confirmed protocol compatibility is preserved:
  - Shell handshake still uses `guide_ready` + `guide_request_state`.
  - Inbound payload remains `guide_state`.
  - Outbound intent messages remain `guide_select_page`, `guide_prev_page`, `guide_next_page`, `guide_close`.
- Confirmed logic/content boundary is preserved:
  - Structured visual blocks are derived from existing Godot text payload rendering only.
  - No new guide data source, no page-order mutation, no navigation rule changes.

## Layout Parity Pass-2 Verification (2026-04-09)
- Shell structure verification:
  - Confirmed centered handbook frame + explicit left-nav/right-content split are present in `ui/web/gameplay_guide_shell/index.html`.
  - Confirmed left rail width and pixel sidebar interaction model match handbook-style navigation (`hover/active` left-border emphasis).
- Runtime compatibility verification:
  - Confirmed no bridge event additions/removals; handshake and intent events remain unchanged.
  - Confirmed page navigation still flows through existing Godot-side authority via page index intents.
- Diagnostics verification:
  - `ui/web/gameplay_guide_shell/index.html` static diagnostics passed (No errors).

## Layout Lock Fix Verification (2026-04-09)
- Verified `ui/web/gameplay_guide_shell/index.html` now uses explicit grid-based two-column layout (`sidebar + content`) instead of stack-prone flex fallback.
- Verified responsive rules no longer switch body to top/bottom stacking; narrow widths still keep left/right split with reduced sidebar width.
- Static diagnostics re-run: `ui/web/gameplay_guide_shell/index.html` No errors.

## BBCode Rendering Fix Verification (2026-04-09)
- Fixed parser handling for BBCode key-value lines in guide content:
  - Supports `[b]键：[/b] 值` without leaking raw `[b]` / `[/b]` markers into rendered text.
  - Supports standalone BBCode heading rows like `[b]补充说明：[/b]`.
- Static diagnostics re-run: `ui/web/gameplay_guide_shell/index.html` No errors.

## Guide Resource Parse-Order Fix Verification (2026-04-09)
- Root-cause validation:
  - Confirmed parse errors were triggered on `SubResource(...)` references in guide `.tres` files where `[resource]` appeared before `[sub_resource]` declarations.
- Structural fix verification:
  - Reordered declarations in all affected guide files so the first `[sub_resource]` line appears before `[resource]`.
  - Verified files: `data/guide/world.tres`, `data/guide/npc_interaction.tres`, `data/guide/inheritance.tres`, `data/guide/magic.tres`, `data/guide/magic_building_guide.tres`, `data/guide/combat.tres`, `data/guide/movement.tres`, `data/guide/inventory.tres`.
- Consistency check:
  - Ran workspace check to assert no `.tres` in `data/guide` still has `[resource]` before `[sub_resource]`.
  - Result: `OK: all guide tres files declare sub_resource before resource.`

## Subsections Nil-Guard Fix Verification (2026-04-09)
- Root-cause validation:
  - Confirmed `section.get("subsections")` may return `Nil` in fallback branch, causing `Nil -> Array` assignment error in `GameplayGuideWindow`.
- Code fix verification:
  - Added guarded assignment pattern (`if maybe_subsections is Array`) before writing to `raw_subsections: Array`.
  - Verified files: `src/ui/guide/gameplay_guide_window.gd`, `guide/upload/gameplay_guide_window.gd`.
- Diagnostics verification:
  - Static diagnostics passed for both files with no errors.

## Guide `<null>` Catalog Fix Verification (2026-04-09)
- Root-cause validation:
  - Confirmed direct `str(get(...))` on null properties could render literal `<null>` in section/page titles and overview text.
- Script-side fix verification:
  - Replaced direct null-to-string conversions with guarded accessors (`_safe_get_string`, `_safe_get_array`) in runtime and upload script copies.
  - Verified files:
    - `src/ui/guide/gameplay_guide_window.gd`
    - `guide/upload/gameplay_guide_window.gd`
- Resource-side fix verification:
  - Confirmed each guide resource now declares explicit script bindings for section/subsection resources through `ExtResource` and `script = ExtResource(...)`.
  - Verified files: `data/guide/world.tres`, `data/guide/npc_interaction.tres`, `data/guide/inheritance.tres`, `data/guide/magic.tres`, `data/guide/magic_building_guide.tres`, `data/guide/combat.tres`, `data/guide/movement.tres`, `data/guide/inventory.tres`.
- Diagnostics verification:
  - Static diagnostics re-run on the above scripts/resources: No errors found.
