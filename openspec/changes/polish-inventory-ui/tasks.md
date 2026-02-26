# Tasks

- [ ] **Prerequisites**
    - [ ] Update `src/core/resources/item_data.gd` (or relevant class) to add `rarity` and `type` fields.
    - [ ] Create `ItemRarity` helper class for color/vfx logic.
    - [ ] Update `src/systems/inventory/inventory_manager.gd` to initialize test data with new rarities.

- [ ] **Assets**
    - [ ] Create `ui/theme/inventory_theme.tres`.
    - [ ] Import category icons.

- [ ] **Components**
    - [ ] **Refactor ItemSlot**:
        - [ ] Add `Border`, `Glow`, and `AnimationPlayer`.
        - [ ] Implement Drag & Drop logic (`_get_drag_data`, `_drop_data`).
    - [ ] **Refactor CraftingPanel**:
        - [ ] Redesign layout to split Recipe List vs Blueprint View.
        - [ ] Apply "Glass" style to ingredient slots.
    - [ ] **Create DetailPanel**:
        - [ ] Create `scenes/ui/inventory/DetailPanel.tscn`.

- [ ] **Main Layout**
    - [ ] **Refactor InventoryWindow**:
        - [ ] Implement 3-column layout.
        - [ ] Integrate new `CraftingPanel` design.
    - [ ] **Script Updates**:
        - [ ] Update `inventory_ui.gd` for tabs, selection, and drag-drop coordination.

- [ ] **Visual Polish**
    - [ ] Entrance animations.
    - [ ] Feedback effects (sound, particles) on craft success or item move.
        - [ ] Implement 3-column layout (Categories | Grid | Details).
        - [ ] Apply "Glass" background styles.
    - [ ] **Script Updates**:
        - [ ] Update `src/ui/inventory/inventory_ui.gd` to handle tab switching (filtering) and item selection.

- [ ] **Visual Polish**
    - [ ] Add entrance animation (window fade-in + items cascading in).
    - [ ] Add sound effects for hover/click (if audio available).
