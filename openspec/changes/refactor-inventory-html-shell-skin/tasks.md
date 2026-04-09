## 1. Proposal Alignment
- [x] 1.1 Freeze scope to InventoryWindow only.
- [x] 1.2 Confirm shell replacement only (no gameplay logic refactor).
- [x] 1.3 Confirm Windows-first runtime target with native fallback.

## 2. HTML Shell Integration Plan
- [x] 2.1 Define InventoryWindow WebView lifecycle (open, hide, close, dispose).
- [x] 2.2 Define native fallback triggers (missing file, WebView unavailable, bridge errors).
- [x] 2.3 Define z-order and input focus behavior so gameplay input remains safe.

## 3. Logic Parity Contract
- [x] 3.1 Define Godot-authoritative data model for inventory state snapshots.
- [x] 3.2 Define bridge message contract for intent-only actions (move, use, drop, tab switch).
- [x] 3.3 Map each HTML intent to existing Godot logic entry points without changing behavior.
- [x] 3.4 Define parity checks for hotbar, crafting tab, trash slot, and close behavior.

## 4. Visual Skin Migration Plan
- [x] 4.1 Extract visual tokens and layout structure from inventory_ui/src/app/page.tsx.
- [x] 4.2 Specify non-functional style migration boundaries (color, typography, spacing, motion).
- [x] 4.3 Preserve existing localization and text source behavior.

## 5. Build and Packaging Plan
- [x] 5.1 Define static export pipeline from inventory_ui to ui/web/inventory_shell.
- [x] 5.2 Define packaging requirements for desktop export (resource presence checks).
- [x] 5.3 Define rollback path to native InventoryWindow when static assets are missing.

## 6. Validation
- [x] 6.1 Validate spec docs with openspec validate refactor-inventory-html-shell-skin --strict.
- [x] 6.2 Define acceptance checks for visual parity and logic parity.
- [x] 6.3 Define regression checks for save/load and inventory interactions.
