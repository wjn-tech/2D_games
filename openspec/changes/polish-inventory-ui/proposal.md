# Polish Inventory UI

This proposal outlines the changes required to modernize the Inventory UI, adopting an "Arcane/Sci-Fi" aesthetic inspired by shadcn/ui (Next.js example) and consistent with the project's new visual direction.

## Problem
The current inventory interface uses basic Godot Control nodes with flat colors (`StyleBoxFlat`), lacking visual hierarchy, feedback, and atmosphere. It does not match the polished "Main Menu" style.

## Solution
Redesign the `InventoryWindow` and `ItemSlot` to use:
*   **Glassmorphism**: Semi-transparent dark backgrounds with blur/glow.
*   **Rarity Color Coding**: Distinct borders/glows for Common, Uncommon, Rare, Epic, and Legendary items.
*   **Juicy Interactions**: Scale/glow animations on hover, smooth layout transitions.
*   **Categorization**: Tabs for "Weapons", "Armor", "Consumables", "Materials" (if supported by data).
*   **Detailed Tooltips**: A dedicated detail panel or rich tooltip for item stats.

## Scope
*   **UI Reskin**: `InventoryWindow.tscn`, `ItemSlot.tscn`, and `CraftingPanel` components.
*   **Visual Effects**: Shaders for backgrounds, tweening for slots, rarity glows.
*   **Data Integration**: Extend `Item` logic to support `rarity`, `type`, and `stats` (mocking where necessary).
*   **Interaction**: Implement Drag & Drop for organizing items.
*   **Layout**: Switch from simple Grid to Tabbed view + Details Panel + Polished Crafting Interface.

## Risks
*   **Data Dependency**: Underlying `Item` data requires schema updates to support the new UI.
*   **Performance**: Excessive use of `BackBufferCopy` for blur or complex shaders on many slots might impact low-end performance (though 2D is generally fine).

## Dependencies
*   `ui/theme/main_menu_theme.tres` (or similar shared theme).
*   `ui/effects/ui_button_hover.gd` (logic for hover).
