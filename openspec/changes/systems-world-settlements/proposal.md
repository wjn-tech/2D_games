# Natural Settlement Generation & Economy System

## Summary
Refactor the existing hardcoded blueprint logic from `InfiniteChunkManager` into a data-driven system using `BlueprintResource`. Use this to generate procedural settlements in the wild with specialized NPCs (Merchants, Blacksmiths) and a functional economy.

## Goals
- **Refactor Blueprints**: Extract `MY_CUSTOM_HOUSE_DESIGN` logic into reusable resources.
- **Ecological World Gen**: Spawn villages in suitable biomes.
- **Economy**: Add Currency (`gold`) to `GameState` and implement Trading UI.
- **Living Settlements**: Mix different blueprint building types (Houses, Shops).
- **Placeholder Anvil**: Blacksmith shops contain an Anvil (interactable placeholder).

## Key Changes
1. **Blueprint Resources**: encapsulate the existing string-grid and palette logic into `.tres` files.
2. **InfiniteChunkManager Update**: Update `_generate_tile_house` to accept `BlueprintResource`.
3. **Settlement Generator**: New logic to place multiple blueprints in a cluster.
4. **Economy Integration**: Add `gold` to `GameState`, UI for interaction.
5. **NPC Specialization**: Specialized NPCs spawned by specific blueprints.
