# Design: Inventory Architecture

**Change ID**: `implement-inventory-system`

## Architecture Overview

### 1. Data Model (`Resource` based)
We use `Resource` for items to allow easy editing in Inspector and saving.

```
ItemData (Resource)
├── id: String
├── display_name: String
├── icon: Texture2D
├── max_stack: int
└── (Virtual) _use(player)

WandItem (extends ItemData)
└── wand_data: WandData (The logic graph)
```

### 2. Container Hierarchy
The Player entity will have an `InventoryComponent`.

```
Player
└── InventoryComponent
    ├── Backpack (Inventory: 20 slots)
    └── Hotbar (Inventory: 9 slots)
```

### 3. Selection & Equipping Logic
The `InventoryComponent` tracks `active_hotbar_index`.
- **Input 1-9**: Updates `active_hotbar_index`.
- **On Update**: 
    1. Retrieve `ItemData` at `active_hotbar_index`.
    2. If changed, emit `equipped_item_changed(new_item)`.
    3. Player `Hand` node clears children -> instantiates visual representation of `new_item` (e.g., specific Wand scene or Sword scene).

### 4. Wand Editing Flow
How does the user edit a wand?
- **Option A**: Press 'E' (Open Inventory) -> Right Click Wand -> "Program".
- **Option B** (Chosen): Open Wand Editor hotkey (e.g. Tab or separate key). It opens the editor for the **Currently Equipped Wand**.
    - *Refinement based on User Request*: "Select object to program".
    - If the user opens the editor, we show a side-panel list of ALL programmable items in inventory/hotbar. Clicking one loads it into the board. This satisfies "Selection" requirement.
