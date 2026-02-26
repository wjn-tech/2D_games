# Inventory UI V2 Tasks

**Tasks**: `polish-inventory-ui-v2`
**Status**: draft
**Priority**: high

1.  **Refactor Layout Scene**
    - [ ] Create new scene structure `InventoryWindowNew.tscn` (Header, MainContainer).
    - [ ] Add `Header` with `ResourceDisplay` components (Gold, Diamond, Magic).
    - [ ] Add `LeftColumn` VBox (Stats Block + Equipment Grid).
    - [ ] Add `CenterColumn` VBox (Tabs + Hotbar Row + Grid).
    - [ ] Add `RightColumn` VBox (DetailPanel + TrashSlot).

2.  **Core Components**
    - [ ] Create `ResourceDisplay.tscn` (Icon, Value, Pill Background).
    - [ ] Create `StatBlock.tscn` (Icon, Name, Value, Progress Bar/BG).
    - [ ] Create `EquipmentSlotUI.tscn` (inherits `ItemSlotUI`, adds specific ghost icon logic).
    - [ ] Create `TrashSlotUI.tscn` (Handles `_can_drop_data` -> returns true for items, `_drop_data` -> deletes item).

3.  **Detail Panel & Data Binding**
    - [ ] Update `DetailPanel.tscn` to match new layout (Large Icon on top, Name below, Stats list, Description box, Buttons row).
    - [ ] Bind `StatBlock` components to `GameState.player_data`.
    - [ ] Verify `EquipmentSlotUI` connects correctly to `PlayerEquipment`.

4.  **Theme & Styling**
    - [ ] Update `inventory_theme.tres` with new `StyleBoxFlat` resources (Glassmorphism, Pill shape, Rarity borders).
    - [ ] Add/Update icons for Stats (STR, AGI, INT, CON) and Equipment Slots (Head, Body, etc.).

5.  **Integration & Tests**
    - [ ] Replace `InventoryWindow` usage in `GameManager` with `InventoryWindowNew`.
    - [ ] Verify drag-and-drop between Backpack <-> Hotbar <-> Equipment <-> Trash.
    - [ ] Verify Stat updates reflect in UI.

6.  **Polish & Experience**
    - [ ] Add `ColorRect` background dimmer/blur behind the window (Modal/Overlay look).
    - [ ] Implement Tooltips for `ItemSlotUI` (hover show name/stats immediately).
    - [ ] Add ProgressBars/Visual Meters for HP/Mana/XP in `StatBlock`.
    - [ ] Implement Double-Click to Use/Equip items.
    - [ ] Implement Right-Click context menu (Use, Drop, Split).
    - [ ] Add selection highlight border (animation).
    - [ ] Standardize Fonts and Colors in `inventory_theme.tres` (define header vs body styles).
    - [ ] Add "Pop" animation (scale/tween) when items change/move/drop.
