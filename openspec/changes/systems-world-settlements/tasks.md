- [ ] **Core: Blueprint Refactor**
  - [ ] Create `src/systems/world/blueprints/blueprint_resource.gd`.
  - [ ] Move hardcoded palette/design from `InfiniteChunkManager` to a default Resource.
  - [ ] Modify `InfiniteChunkManager._generate_tile_house` to accept `BlueprintResource`.

- [ ] **Content: Blueprints**
  - [ ] Define `house_small.tres` (based on existing logic).
  - [ ] Define `blacksmith_shop.tres` (includes Anvil placeholder 'A').
  - [ ] Define `general_store.tres` (includes Merchant spawn).

- [ ] **System: Economy**
  - [ ] Add `gold` variable to `src/core/game_state.gd`.
  - [ ] Implement `TradeWindow.tscn`.
  - [ ] Refactor `MerchantNPC` to subtract/add Gold.

- [ ] **System: Settlement Generation**
  - [ ] Implement simple cluster logic in `InfiniteChunkManager` (spawn multiple blueprints near each other).
  - [ ] Ensure terrain flattening adapts to blueprint width.

- [ ] **Content: Objects**
  - [ ] Create `scenes/world/anvil.tscn` (Placeholder interactable).
  - [ ] Update entity spawning logic to handle Anvil and NPCs defined in Blueprints.
