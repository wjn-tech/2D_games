# Proposal: Refine Roadmap Policy based on Codebase Scan

Adjust the 15-project sequence to leverage existing high-completion modules (Weather, Layers, Lifespan) while prioritizing the "Minimum Viable Loop" (Life -> World -> Legacy).

## Why
A code scan revealed that the project is not starting from zero. Specifically:
- **Weather and Time (03)** are ~90% complete.
- **Layer Management (01/09)** is ~70% complete.
- **Lifespan/Succession logic (11/12)** has ~30% prototype code.
It is more efficient to "polish to completion" the advanced modules first to create a stable game world, then fill in the missing social and industrial gaps.

## Proposed Strategy: The "Polishing & Linking" Order

### Tier 1: Stabilization (Immediate Focus)
1.  **[03-world-chronometer-and-weather]**: Move to 100%. Link weather to the existing global illumination/modulate system.
2.  **[01-physics-layer-architecture]**: Finalize the bitmasking and layer-switching. Ensure `LayerManager` handles all `TileMapLayer` nodes correctly.
3.  **[02-character-attribute-engine]**: Connect existing `CharacterData` to a visible UI and ensure `Strength` actually affects gameplay (speed/jump).

### Tier 2: The Gameplay Loop (The "Action" Phase)
4.  **[09-layer-combat-mechanics]**: Bridge the gap between Layer Switching and Combat. Ensure NPCs can follow the player through `LayerDoors` or lose aggro across depths.
5.  **[04-npc-behavior-and-factions]**: Polish the existing FSM. Add the "Night/Day" reaction signals (already partially implemented).
6.  **[05-resource-gathering-and-ecology]**: Standardize `Gatherable.gd` and connect it to the Inventory system.

### Tier 3: The Legacy Loop (The "Story" Phase)
7.  **[12-succession-and-legacy]**: Flesh out the `LifespanManager` death signal. 
8.  **[07-crafting-forging-alchemy]** & **[06-trading-and-economy]**: Build the UI/Data for recipes and shops.
9.  **[11-heredity-and-breeding]**: Character growth from infant to adult using the existing `growth_progress` variable.

### Tier 4: Social & Industry (Expansion)
10. **[10-social-marriage-system]**: Fully new module development.
11. **[08-building-and-city-blueprint]**: Refine the building grid.
12. **[13-15]**: Tactical Arrays and Industry.

## Impact
- **Earlier Playability**: The game becomes "complete" in small vertical slices.
- **Reduced Tech Debt**: Polishing existing logic now prevents building new systems on top of buggy prototypes.

## Acceptance Criteria
- [ ] Roadmap priorities are re-ordered in `roadmap.md`.
- [ ] Tier 1 projects have specific completion-focused tasks.
