# Prop: Implement Wand Decoration & Dynamic Handling

## Summary
Add a "Pixel Paint" style decoration system for Wands, allowing players to design their wand's appearance on a 16x16 grid using materials. The resulting design is used to generate the item's icon and the in-game weapon sprite. Additionally, upgrade the player's weapon holding mechanic to align the wand dynamically between a central pivot and the mouse cursor.

## Problem Statement
Currently, Wands are represented by static placeholders or generic sprites. The game promises a high degree of customization ("Manufacture/Tinker"), but lacks visual feedback for custom wands. The player holding mechanic is also basic (`Sprite2D` offset) and doesn't reflect the "aiming" nature of a magic wand.

## Solution
1.  **Wand Editor**: Update the `VisualGrid` to a 16x16 pixel-art canvas. Players dragging crafting materials (e.g., Wood, Gem) onto the grid will "paint" that cell with the material's `wand_visual_color`.
2.  **Runtime Rendering**: Implement a system to generate `ImageTexture` resources from the saved wand data (16x16 grid of colors) for use in Inventory slots and the detailed Weapon Sprite.
3.  **Dynamic Holding**: Attach the wand to the player's center. Rotate the wand such that the "Head" (Visual Tip) points towards the mouse cursor, utilizing an IK-like approach (Tail fixed, Head follows direction).

## Impact
-   **UI**: Major update to `WandEditor` and `VisualGrid`.
-   **Systems**: Updates to `WandData` (or utilization of existing fields) and `InventoryItem` display logic.
-   **Gameplay**: Player animation/holding logic update.
