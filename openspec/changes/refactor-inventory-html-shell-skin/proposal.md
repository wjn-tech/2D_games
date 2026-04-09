# Change: Refactor Inventory HTML Shell Skin

## Why
The project already has a functional Godot-native inventory window, but a new art direction has been delivered in the attached inventory_ui project. The requested outcome is a shell replacement only: keep all inventory-related gameplay logic exactly as-is and replace only the visual presentation architecture through an embedded HTML shell.

## What Changes
- Scope this change to InventoryWindow only.
- Introduce an embedded HTML shell for inventory visuals using WebView, with mandatory native fallback.
- Use inventory_ui/src/app/page.tsx as the single visual baseline.
- Keep Godot as the authoritative state and logic executor for all inventory actions.
- Preserve existing localization and UI text behavior.
- Define a static build pipeline that exports HTML/CSS/JS from inventory_ui and packages assets into ui/web/inventory_shell.
- Target Windows desktop first (WebView2 runtime path), with explicit fallback behavior when unavailable.

## Impact
- Affected specs: inventory-html-shell
- Related changes:
  - integrate-html-ui-beautification-bridge
  - ui-inventory-overhaul
- Affected code (apply stage):
  - src/ui/inventory/inventory_ui.gd
  - scenes/ui/InventoryWindow.tscn
  - src/ui/ui_manager.gd
  - src/core/game_manager.gd
  - ui/web/inventory_shell/index.html
  - inventory_ui/* (build and asset export flow)
