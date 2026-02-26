# Inventory UI V2 Design

**Design**: `polish-inventory-ui-v2`
**Status**: draft

## Overview

The new design restructures the Inventory Window into distinct, purpose-driven areas, following a "Left-To-Right" information flow and a "Top-Down" resource management model. It transitions from a simple list to a dashboard-style interface.

## Architecture

### 1. Scene Structure
-   **Old Scene**: `InventoryWindow.tscn` (Sidebar | Content | Details)
-   **New Scene**: `InventoryWindow.tscn` (Header + MainContent) -> MainContent (LeftColumn | CenterColumn | RightColumn)

#### Header (Top)
-   Displays `GlobalResources` (Gold, Diamond, Dust) using `HBoxContainer`.
-   Backdrop: Purple/Blue gradient with `TextureRect` glow effects.

#### Left Column (Stats & Equipment)
-   **Stats Blocks**: `VBoxContainer` with `PanelContainer` items for STR, AGI, INT, CON.
-   **Equipment Grid**: `GridContainer` (3x2 or custom layout) showing specific slots: `[Head, Body], [MainHand, OffHand], [Accessory, Boots]`.
    -   Requires new `EquipmentSlotUI` component (inherits or wraps `ItemSlotUI`).

#### Center Column (Inventory Grid)
-   **Tabs**: Custom `SegmentedButtons` (Backpack | Hotbar) at the top.
-   **Grid**: `GridContainer` (5x4) for backpack slots.
    -   Items render with `ItemRarity` glow backgrounds and specific count badges.
-   **Hotbar**: Dedicated `HBoxContainer` row (1-5) above the main grid (or integrated, per design).

#### Right Column (Details & Actions)
-   **Detail Panel**: Shows selected item icon (large), name (rarity color), description, stats.
-   **Action Area**: "Use" / "Drop" buttons.
-   **Trash Zone**: A distinct `PanelContainer` at the bottom that accepts `_can_drop_data` to delete items.

## Visual Style (Theme)
-   **Colors**:
    -   Background: `#1a1b26` (approximate dark blue/purple).
    -   Accent: `#F472B6` (Pink), `#22D3EE` (Cyan), `#FBBF24` (Amber).
-   **Shapes**: Large border radius (12px-16px).
-   **Juice**: Hover scale effects, rarity borders, subtle background animations (optional for v2, maybe v3).

## Data Flow
-   **Stats**: Connect to `GameState.player_data.stat_changed`.
-   **Equipment**: Connect to `GameState.player_data.equipment.equipment_changed`.
-   **Inventory**: Connect to `GameState.inventory.inventory_changed`.
-   **Resources**: Create/Connect to `GameState.resources` (if not existing, create dummy/mock for now).

## New Components
-   `EquipmentSlotUI.tscn`: Specialized slot that shows a background icon when empty (e.g., ghost sword for weapon slot).
-   `ResourceDisplay.tscn`: Reusable component for displaying currency/materials.
-   `TrashSlotUI.tscn`: Special drop target.

## Considerations
-   **Drag & Drop**: Maintain existing drag logic but extend valid drop targets to `TrashSlotUI` and `EquipmentSlotUI`.
-   **Responsiveness**: The mock design is fixed-width. We should use `Container` sizing flags to allow some flex, but optimize for 1280x720+ resolution.
