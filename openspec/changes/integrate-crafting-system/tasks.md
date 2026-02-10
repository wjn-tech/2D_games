# Tasks: Integrate Character Crafting System

## Phase 1: MVP - Side-by-Side UI & Quality Crafting
- [x] **Scaffold UI**: Modify `InventoryWindow` to support a wide Side-by-Side layout (Inventory Left, Crafting Right).
- [x] **Crafting UI Component**: Create `CraftingPanel` scene with:
    -   Scrollable Recipe List (Filtered for Handcrafting).
    -   Recipe Details (Materials needed, expected Quality range).
    -   "Craft" Button.
- [x] **Data Update**: Add `quality_grade` and `crafted_properties` fields to `BaseItem` (or extended item data).
- [x] **Refactor CraftingManager**:
    -   Implement `perform_handcraft(recipe)`: Instant execution + Quality calculation logic.
    -   Quality Logic: Implement `calculate_quality()` based on simple skill/random factor for MVP.
- [x] **Wire Input**: Ensure pressing 'I' opens the full wide window.

## Phase 2: Depth & Polish
- [ ] **Discovery**: Implement recipe unlocking via pickups or "Experimentation" scrolls.
- [ ] **Station Integration**: Add support for opening specific Station UIs (Alchemy/Forge) using the same underlying `CraftingPanel` structure but with different minigame hooks.
- [ ] **Visual Feedback**:Juice effects for "Successful Craft" (particles, floating text).
