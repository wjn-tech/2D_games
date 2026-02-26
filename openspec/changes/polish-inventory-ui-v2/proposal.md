# Inventory UI V2 Polish Proposal

**Change ID**: `polish-inventory-ui-v2`
**Type**: refactor
**Status**: proposed

## Summary

Refactor the current functional but minimal Inventory UI into a polished "Magic Backpack" interface, matching the provided high-fidelity design. This includes a three-column layout, resource indicators, equipment slots, detailed rarity styling, and improved UX interactions like drag-to-trash.

## Why

The current inventory UI (v1) lacks the visual polish expected for the game. The user has provided a specific React-based reference implementation ("Magic Backpack") that features glassmorphism, advanced layout, and better information hierarchy. Aligning the Godot implementation with this design will significantly improve player immersion and usability.

## What Changes

1.  **Three-Column Layout**: Replace the current 2-column layout with a Left (Stats/Equip) - Center (Grid) - Right (Details/Trash) structure.
2.  **Resource Header**: Display Gold, Diamond, and Dust resources at the top.
3.  **Equipment Slots**: Visualize equipment slots (Head, Body, Main Hand, Off Hand, Feet, Accessory) with placeholder icons.
4.  **Polished Grid & Hotbar**: Implement the specific "Magic Backpack" styling for item slots, including rarity glows and count badges.
5.  **Trash & Details**: Add a persistent drag-to-trash area and a detailed inspection panel for selected items.
6.  **Enhanced Experience**: Improve interaction with tooltips, context menus, animations, and better visual feedback (dimming background).

## Experience Goals

Based on user feedback, the UI must feel responsive and high-quality:
-   **Visuals**: Clear zones, reduced noise with dimming/blur, consistent styling.
-   **Interaction**: Quick actions (double-click/right-click), clear selection states.
-   **Readability**: Hierarchy with typography, visual representations for stats (bars vs raw numbers).
-   **Feedback**: Animations ("Pop" effect) and sound cues for actions.

## Security & Performance

-   **Performance**: The glassmorphism effect will be implemented using `StyleBoxFlat` and `TextureRect` overlays rather than expensive shaders to ensure performance.
-   **Security**: No new network or file I/O implications.

## Dependencies

-   Existing `InventoryManager` and `Item` resource system.
-   `inventory_theme.tres` (will be expanded).
-   `ItemRarity` class.
