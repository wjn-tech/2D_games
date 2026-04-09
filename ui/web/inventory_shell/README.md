# Inventory HTML Shell

## Source of truth
- Visual shell source: `inventory_ui/public/inventory_shell/index.html`
- Runtime shell target: `ui/web/inventory_shell/index.html`

## Export pipeline
- Windows PowerShell:
  - `./inventory_ui/.zscripts/export-inventory-shell.ps1`
- Bash:
  - `bash ./inventory_ui/.zscripts/export-inventory-shell.sh`

Both scripts copy the static shell into the runtime folder used by Godot WebView.

## Runtime fallback contract
- If `ui/web/inventory_shell/index.html` is missing, `InventoryUI` falls back to native Godot rendering.
- If WebView is unavailable, `InventoryUI` falls back to native Godot rendering.
- If bridge runtime reports an error, `InventoryUI` falls back to native Godot rendering.

## Implementation notes
- Inventory and crafting both run in the HTML shell; crafting is no longer delegated to the old native crafting tab.
- Item icons are sent from Godot as texture-derived `data:image/png;base64,...` payloads.
- AtlasTexture icons are cropped to their atlas region before encoding, to match native slot visuals.

## Acceptance checklist
- Open inventory from gameplay hotkey and HUD button.
- Verify drag/swap between backpack and hotbar from HTML shell.
- Verify drop and trash actions mutate the same inventory data as native logic.
- Verify crafting tab lists recipes, shows ingredient ownership, and crafts directly in HTML shell.
- Verify save/load keeps inventory data parity.
