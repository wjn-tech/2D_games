# Tasks: Inventory & Hotbar System

**Change ID**: `implement-inventory-system`

## Phase 1: Core Data Structures

- [x] `sys.inventory.data`: Create `ItemData` (Resource) and `Inventory` (Resource).
    - [x] Define `ItemData` (id, name, icon, stack_size).
    - [x] Create `WandItem` extends `ItemData` (holds `wand_data`).
    - [x] Create `Inventory` (array of `Slot` dictionaries).
- [x] `sys.inventory.manager`: Create `InventoryManager` (Node/Component).
    - [x] Implement `add_item(item, count)`.
    - [x] Implement `remove_item(slot_index, count)`.
    - [x] Implement `swap_items(from_inv, from_slot, to_inv, to_slot)`.

## Phase 2: UI Implementation

- [x] `sys.inventory.ui`: Create `InventorySlotUI` and `InventoryContainerUI`.
    - [x] Implement Drag & Drop logic (`_get_drag_data`, `_can_drop_data`, `_drop_data`).
    - [x] Create `BackpackPanel` (Grid) and `HotbarPanel` (Horizontal Row).
- [x] `sys.player.input`: Map Keys 1-9 to Hotbar selection.

## Phase 3: Wand Integration

- [x] `sys.magic.integration`: Update Wand Editor to use `ItemData`.
    - [x] Modify `WandEditor` to accept `WandItem` payload.
    - [x] Add "Select Wand" panel if editor is opened without a specific context? Or just edit held wand? (Design: Edit Held Wand).
    - [x] Ensure `WandData` persistence within `ItemData`.

## Phase 4: World Interaction

- [x] `sys.world.pickup`: Create `Pickup` scene.
    - [x] 3D/2D sprite that adds item to Inventory on collision/interact.
